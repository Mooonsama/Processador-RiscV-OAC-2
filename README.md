# Processador-RiscV-OAC-2

# Resumo da Integração do Processador RISC-V Pipelined

## O Que Foi Integrado

---

### 1. **Arquitetura de Pipeline de 5 Estágios**
- **IF (Instruction Fetch)**: PC (Program Counter), Memória de Instruções, registrador IF/ID
- **ID (Instruction Decode)**: Unidade de Controle, Banco de Registradores, Gerador de Imediato, registrador ID/EX
- **EX (Execute)**: ULA (Unidade Lógica e Aritmética), Controle da ULA, Multiplexadores de Forwarding, registrador EX/MEM
- **MEM (Memory Access)**: Memória de Dados, registrador MEM/WB
- **WB (Write Back)**: Multiplexador de write-back

### 2. **Integração da Unidade de Forwarding**
- **Localização**: Entre os estágios EX/MEM e MEM/WB
- **Função**: Detecta hazards **RAW** (Read After Write) e encaminha os dados dos estágios posteriores
- **Sinais**: 
  - `forward_a` e `forward_b` controlam os multiplexadores de entrada da ULA
  - Encaminha do estágio EX/MEM (prioridade) ou do estágio MEM/WB
- **Problemas Corrigidos**: 
  - Lógica corrigida para verificar o registrador **x0** (nunca encaminhar para/de x0)
  - Estrutura condicional simplificada para melhor síntese

### 3. **Integração da Unidade de Detecção de Hazards**
- **Localização**: No estágio ID
- **Função**: Detecta hazards de "**load-use**" (uso de dados recém-carregados)
- **Sinais de Controle**:
  - `pc_write`: Pausa o PC quando um hazard é detectado
  - `ifid_write`: Pausa o registrador IF/ID
  - `control_mux_sel`: Insere um **NOP** (No Operation) no pipeline
- **Módulos Conectados**: Usa `rs1checar.v` e `rs2checar.v`

### 4. **Registradores de Pipeline**
- **IF/ID**: Transmite a instrução e o PC
- **ID/EX**: Transmite sinais de controle, dados de registrador, imediato, endereços de registrador
- **EX/MEM**: Transmite o resultado da ULA, controle de memória, dados de escrita
- **MEM/WB**: Transmite dados da memória, resultado da ULA, controle de escrita

## Recursos Chave Implementados

---

### ✅ **Encaminhamento de Dados (Data Forwarding)**
- **EX-para-EX** forwarding (resultado da ULA para a entrada da ULA)
- **MEM-para-EX** forwarding (estágio de Memória para a entrada da ULA)
- Tratamento de prioridade adequado (o encaminhamento EX tem precedência sobre o MEM)

### ✅ **Detecção de Hazards**
- Detecção de hazard de "load-use"
- Mecanismo de **parada do pipeline (stalling)**
- **NOP** insertion para hazards de controle

### ✅ **Controle do Pipeline**
- Sinais de ativação/desativação para cada registrador do pipeline
- Funcionalidade de **reset** para todos os estágios
- **Clock gating** para tratamento de hazards

## Arquivos Modificados/Criados

---

### **Arquivos Modificados:**
1. **RiscVTop.v** - Completamente reescrito como um processador pipeline de 5 estágios
2. **fowarding.v** - Erros de lógica corrigidos e estrutura simplificada
3. **TestRiscV.v** - Testbench atualizado para testes do pipeline

### **Arquivos Existentes Integrados:**
- `PipeIFID.v`, `PipeIDEX.v`, `PipeEXMEM.v`, `PipeMEMWB.v`
- `Hazard_Unit.v`, `rs1checar.v`, `rs2checar.v`
- `Mux2x1.v`, `Mux3x1.v`
- Todos os componentes originais do processador (ULA, Unidade de Controle, Memória, etc.)

## Sequência de Teste

---

O testbench inclui instruções que testam especificamente:

1. **Sem Hazard**: `addi x3, x1, 10`
2. **Hazard RAW + Forwarding**: `add x4, x3, x2` (usa x3 da instrução anterior)
3. **Encaminhamento Duplo**: `sub x5, x4, x1` (usa x4 da instrução anterior)
4. **Instrução de Load**: `lw x6, 0(x0)`
5. **Hazard de "Load-Use"**: `add x7, x6, x5` (requer parada do pipeline)
6. **Instrução de Store**: `sw x7, 4(x0)`

## Como Executar

---

```bash
# Tornar o script executável
chmod +x compile_and_run.sh

# Compilar e executar
./compile_and_run.sh

# Ou manualmente:
iverilog -o riscv_pipeline TestRiscV.v
vvp riscv_pipeline
gtkwave riscv_tb.vcd  # Visualizar as formas de onda
