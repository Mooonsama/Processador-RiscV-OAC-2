`include "RiscVTop.v"

`timescale 1ns/1ps

module riscv_tb();

    reg clk = 0;
    reg reset = 1;
    integer i;

    // Instancia o top module
    riscv_top uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock de 10ns
    always #5 clk = ~clk;

    // Inicialização do teste
    initial begin
        $dumpfile("riscv_tb.vcd");
        $dumpvars(0, riscv_tb);

        // === Fase 0: Reset inicial
        #10;
        reset = 0;

        // === Carrega instruções manualmente na instr_memory ===
        // Formato: <opcode> + campos. Todos em hexadecimal

        uut.RF.registers[4] = 32'h0000000B; // Inicializa x4 com um valor para testes
        uut.RF.registers[5] = 32'h0000000F; // Inicializa x5 com um valor para testes

        // 0x00: lb x5, 0(x0)          --> carrega byte da mem[0] para x5
        uut.IMEM.memory[0] = 32'h00000283;

        // 0x04: sb x5, 4(x0)         --> armazena byte de x5 na mem[4]
        uut.IMEM.memory[1] = 32'h00500223;

        // 0x08: sub x6, x5, x4       --> x6 = x5 - x4 = 00000004
        uut.IMEM.memory[2] = 32'h40428333;

        // 0x0C: and x7, x6, x6       --> x7 = x6 & x6 = 00000004
        uut.IMEM.memory[3] = 32'h006363B3;

        // 0x10: ori x8, x0, 0x0F0     --> x8 = 0 | 0x0F0
        uut.IMEM.memory[4] = 32'h0F006413;

        // 0x14: srl x9, x8, x6       --> x9 = x8 >> x6 (shift by 4 bits)
        uut.IMEM.memory[5] = 32'h006454B3;

        // 0x18: beq x5, x6, +4       --> se x5 == x6, pula instrucao (won't be taken since x5 != x6)
        uut.IMEM.memory[6] = 32'h00630263;

        // Add a NOP or another instruction after the branch
        uut.IMEM.memory[7] = 32'h00000013; // NOP (addi x0, x0, 0)

        // === Inicializa memória de dados com valor em 0x00
        uut.DMEM.memory[0] = 8'h0F; // byte para instrução lb

        //=== Roda por ciclos suficientes ===
        //Executa ciclo por ciclo para debug
        repeat(15) begin // Run enough cycles for all instructions
            #10;
            $display("Cycle %0d: PC=%h, Instr=%h", $time/10, uut.pc_current, uut.instruction);
            $display("  Opcode=%b, RegWrite=%b, rd=%d", uut.instruction[6:0], uut.reg_write, uut.instruction[11:7]);
            if (uut.reg_write) begin
                $display("  Writing %h to reg[%d]", uut.reg_write_data, uut.instruction[11:7]);
            end
            $display("  x5=%h, x6=%h, x7=%h, x8=%h, x9=%h", 
                     uut.RF.registers[5], uut.RF.registers[6], uut.RF.registers[7], 
                     uut.RF.registers[8], uut.RF.registers[9]);
            $display("");
        end

        // === Resultados esperados ===
        $display("x5 (lb):  %h (esperado: 0000000F)", uut.RF.registers[5]);
        $display("x6 (sub): %h (esperado: 00000004)", uut.RF.registers[6]);
        $display("x7 (and): %h (esperado: 00000004)", uut.RF.registers[7]);
        $display("x8 (ori): %h (esperado: 000000F0)", uut.RF.registers[8]);
        $display("x9 (srl): %h (esperado: 0000000F)", uut.RF.registers[9]); // F0 >> 4 = 0x0000000F
        $display("Mem[4] (sb): %h (esperado: 0000000F)", uut.DMEM.memory[4]);
        $display("Mem[0] (lb): %h (esperado: 0000000F)", uut.DMEM.memory[0]); // Verifica se o byte foi carregado corretamente

        // === Verifica o estado dos registradores ===
        $display("Estado dos registradores:");
        $display("x0: %h", uut.RF.registers[0]); // x0 deve ser sempre 0
        $display("x1: %h", uut.RF.registers[1]);
        $display("x2: %h", uut.RF.registers[2]);
        $display("x3: %h", uut.RF.registers[3]);
        $display("x4: %h", uut.RF.registers[4]);
        $display("x5: %h", uut.RF.registers[5]);
        $display("x6: %h", uut.RF.registers[6]);
        $display("x7: %h", uut.RF.registers[7]);
        $display("x8: %h", uut.RF.registers[8]);
        $display("x9: %h", uut.RF.registers[9]);
        $display("x10: %h", uut.RF.registers[10]);
        $display("x11: %h", uut.RF.registers[11]);
        $display("x12: %h", uut.RF.registers[12]);
        $display("x13: %h", uut.RF.registers[13]);
        $display("x14: %h", uut.RF.registers[14]);
        $display("x15: %h", uut.RF.registers[15]);
        $display("x16: %h", uut.RF.registers[16]);
        $display("x17: %h", uut.RF.registers[17]);
        $display("x18: %h", uut.RF.registers[18]);
        $display("x19: %h", uut.RF.registers[19]);
        $display("x20: %h", uut.RF.registers[20]);
        $display("x21: %h", uut.RF.registers[21]);
        $display("x22: %h", uut.RF.registers[22]);
        $display("x23: %h", uut.RF.registers[23]);
        $display("x24: %h", uut.RF.registers[24]);
        $display("x25: %h", uut.RF.registers[25]);
        $display("x26: %h", uut.RF.registers[26]);
        $display("x27: %h", uut.RF.registers[27]);
        $display("x28: %h", uut.RF.registers[28]);
        $display("x29: %h", uut.RF.registers[29]);
        $display("x30: %h", uut.RF.registers[30]);
        $display("x31: %h", uut.RF.registers[31]);

        $finish; // Finaliza a simulação

    end
endmodule
