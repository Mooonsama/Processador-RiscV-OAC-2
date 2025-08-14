# Processador-RiscV-OAC-2
# Resumo da Integração do Processador RISC-V Pipelined

## O Que Foi Integrado

-----

### 1\. **Arquitetura de Pipeline de 5 Estágios**

  - **IF (Busca de Instrução)**: PC, Memória de Instruções, registrador IF/ID com descarte de branch (branch flush)
  - **ID (Decodificação de Instrução)**: Unidade de Controle, Banco de Registradores, Gerador de Imediato, Lógica de Branch, registrador ID/EX
  - **EX (Execução)**: ULA (Unidade Lógica e Aritmética), Controle da ULA, Multiplexadores de Forwarding, registrador EX/MEM
  - **MEM (Acesso à Memória)**: Memória de Dados, registrador MEM/WB
  - **WB (Escrita de Volta)**: Multiplexador de escrita de volta

### 2\. **Integração da Unidade de Forwarding**

  - **Localização**: Entre os estágios EX/MEM e MEM/WB
  - **Função**: Detecta hazards **RAW** (Read After Write - Leitura Após Escrita) e encaminha dados de estágios posteriores
  - **Sinais**:
      - `forward_a` e `forward_b` controlam os multiplexadores de entrada da ULA
      - Encaminha do estágio EX/MEM (prioridade) ou do estágio MEM/WB
  - **Problemas Corrigidos**:
      - Lógica corrigida para verificar o registrador **x0** (nunca encaminhar para/de x0)
      - Tratamento adequado do encaminhamento de dados da memória versus da ULA

### 3\. **Integração da Unidade de Detecção de Hazards**

  - **Localização**: No estágio ID
  - **Função**: Detecta hazards de "load-use" (uso de dados recém-carregados)
  - **Sinais de Controle**:
      - `pc_write`: Pausa o PC quando um hazard é detectado
      - `ifid_write`: Pausa o registrador IF/ID
      - `control_mux_sel`: Insere um **NOP** (No Operation - Nenhuma Operação) no pipeline
  - **Módulos Conectados**: Usa `rs1checar.v` e `rs2checar.v`

### 4\. **Integração do Controle de Branch**

  - **Localização**: No estágio ID
  - **Função**: Lida com instruções de branch (BEQ)
  - **Recursos**:
      - Cálculo do alvo do branch (PC + imediato)
      - Avaliação da condição de branch (comparação de registradores)
      - Mecanismo de **descarte do pipeline** para cancelar instruções do caminho errado
      - Atualização correta do PC para branches que são tomados

### 5\. **Registradores de Pipeline**

  - **IF/ID**: Transmite a instrução e o PC, suporta descarte de branch
  - **ID/EX**: Transmite sinais de controle, dados de registrador, imediato, endereços de registrador
  - **EX/MEM**: Transmite o resultado da ULA, controle de memória, dados de escrita
  - **MEM/WB**: Transmite dados da memória, resultado da ULA, controle de escrita

## Recursos Chave Implementados

-----

### ✅ **Encaminhamento de Dados (Data Forwarding)**

  - Encaminhamento **EX-para-EX** (resultado da ULA para a entrada da ULA)
  - Encaminhamento **MEM-para-EX** (dados da Memória/ULA para a entrada da ULA)
  - Encaminhamento **WB-para-EX** (dados de escrita de volta para a entrada da ULA)
  - Tratamento de prioridade adequado (EX \> MEM \> WB)

### ✅ **Detecção de Hazards**

  - Detecção de hazard de "load-use" com parada do pipeline
  - Mecanismo de parada de um ciclo
  - Inserção de **NOP** para hazards de controle

### ✅ **Controle de Branch**

  - Suporte para instrução **BEQ**
  - Cálculo do alvo do branch
  - Descarte do pipeline para branches tomados
  - Tratamento adequado dos "branch delay slots" (espaços de atraso de branch)

### ✅ **Timing do Banco de Registradores**

  - Escrita na borda de descida do clock, leitura combinacional
  - Timing adequado para leitura após escrita no mesmo ciclo


## Sequência de Teste

-----

O testbench inclui uma sequência de instruções abrangente que testa:

1.  **Carregar Byte**: `lb x5, 0(x0)` → carrega 0x0F da memória
2.  **Armazenar Byte**: `sb x5, 4(x0)` → armazena byte na memória (hazard de "load-use")
3.  **Subtração**: `sub x6, x5, x4` → x6 = 0x0F - 0x0B = 0x04 (forwarding)
4.  **AND Lógico**: `and x7, x6, x6` → x7 = 0x04 & 0x04 = 0x04 (forwarding)
5.  **OR Imediato**: `ori x8, x0, 0x0F0` → x8 = 0 | 0xF0 = 0xF0
6.  **Shift para a Direita**: `srl x9, x8, x6` → x9 = 0xF0 \>\> 4 = 0x0F (forwarding)
7.  **Branch se Igual**: `beq x6, x7, +4` → o branch é tomado já que x6 == x7 == 0x04
8.  **Adicionar Imediato**: `addi x10, x0, 100` → **IGNORADO** pelo branch (x10 = 0)

## Como Executar

-----

```bash
# Compilar e executar
iverilog -o riscv_pipeline TestRiscV.v
vvp riscv_pipeline

# Visualizar as formas de onda
gtkwave riscv_tb.vcd
```

## Resultados Esperados

-----

```
x5 (lb):   0000000F ✓ (carregado da memória)
x6 (sub):  00000004 ✓ (15 - 11 = 4)
x7 (and):  00000004 ✓ (4 & 4 = 4)
x8 (ori):  000000F0 ✓ (0 | 240 = 240)
x9 (srl):  0000000F ✓ (240 >> 4 = 15)
x10 (addi): 00000000 ✓ (ignorado pelo branch)
Mem[4] (sb): 0F ✓ (byte armazenado)
Mem[0] (lb): 0F ✓ (dado original)
```

## Comportamento do Pipeline Demonstrado

  - **O pipeline é preenchido em 5 ciclos**
  - **Mensagens de forwarding** aparecem quando os hazards RAW são resolvidos
  - **Mensagens de stall** aparecem para hazards de "load-use"
  - **Branch tomado** com descarte adequado do pipeline
  - **Todos os tipos de instrução funcionando**: Load, Store, ALU, Branch
  - **Nenhuma corrupção de dados** devido a hazards

## Diagrama da Arquitetura

-----

```
[IF] -> [IF/ID] -> [ID] -> [ID/EX] -> [EX] -> [EX/MEM] -> [MEM] -> [MEM/WB] -> [WB]
         ↑          |                   ^                    ^
    [Descarte de Branch] v                   |                    |
                [Unidade de Hazard]       [Unidade de Forwarding]   [Unidade de Forwarding]
                     |                   |                    |
                     v                   v                    v
               [Controle de Stall]      [Mux A da ULA]         [Mux B da ULA]
                     |                   |
                     v                   v
               [Controle de PC]        [Lógica de Branch]
```

O processador integra com sucesso todos os principais componentes (pipeline, forwarding, detecção de hazards, controle de branch) em um processador RISC-V pipelined de 5 estágios totalmente funcional.
