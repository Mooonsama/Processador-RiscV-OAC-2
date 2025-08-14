`include "RiscVTop.v"

`timescale 1ns/1ps

module riscv_tb();

    reg clk = 0;
    reg reset = 1;
    integer cycle_count = 0;
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

        // ---------------- Reset por 3 ciclos ----------------
        #30;
        reset = 0;
        $display("Reset foi pra zero no tempo %0t", $time);

        // ---------------- Nosso: Inicializa registradores para testes ----------------
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

        // 0x14: srl x9, x8, x6       --> x9 = x8 >> x6 (shift de 4 bits)
        uut.IMEM.memory[5] = 32'h006454B3;

        // 0x18: beq x6, x7, +4       --> se x6 == x7, (x6 == x7 == 0x04)
        uut.IMEM.memory[6] = 32'h00730263;

        // 0x1C: addi x10, x0, 100    --> x10 = 100 (pula)
        uut.IMEM.memory[7] = 32'h06400513;

        // Inicializa memória de dados com valor em 0x00
        uut.DMEM.memory[0] = 8'h0F;


        // // ---------------- Chat: Inicializa registradores para testes ----------------
        // // ---------------- Carrega instruções que testam forwarding e hazards ----------------
        // // Test sequence designed to trigger forwarding and hazards
        
        // // Initialize some registers for testing
        // uut.RF.registers[1] = 32'h00000010; // x1 = 16
        // uut.RF.registers[2] = 32'h00000005; // x2 = 5
        
        // // 0x00: addi x3, x1, 10      --> x3 = x1 + 10 = 26 (no hazard)
        // uut.IMEM.memory[0] = 32'h00A08193;
        
        // // 0x04: add x4, x3, x2       --> x4 = x3 + x2 = 31 (RAW hazard on x3, needs forwarding)
        // uut.IMEM.memory[1] = 32'h00218233;
        
        // // 0x08: sub x5, x4, x1       --> x5 = x4 - x1 = 15 (RAW hazard on x4, needs forwarding)
        // uut.IMEM.memory[2] = 32'h401202B3;
        
        // // 0x0C: lw x6, 0(x0)         --> x6 = mem[0] (load instruction)
        // uut.IMEM.memory[3] = 32'h00002303;
        
        // // 0x10: add x7, x6, x5       --> x7 = x6 + x5 (load-use hazard, needs stall)
        // uut.IMEM.memory[4] = 32'h005303B3;
        
        // // 0x14: sw x7, 4(x0)         --> mem[4] = x7 (store instruction)  
        // uut.IMEM.memory[5] = 32'h00702223;
        
        // // 0x18: nop
        // uut.IMEM.memory[6] = 32'h00000013;

        // // ---------------- Initialize Data Memory ----------------
        // uut.DMEM.memory[0] = 8'h20; // mem[0] = 32 (byte)
        // uut.DMEM.memory[1] = 8'h00;
        // uut.DMEM.memory[2] = 8'h00;
        // uut.DMEM.memory[3] = 8'h00;

        // ---------------- Debug dos ciclos ----------------
        $display("Instrucoes carregadas. Iniciando execucao...");
        $display("");
        //---------------- Executa por ciclos suficientes para ver pipeline completo ----------------
        repeat(20) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            $display("--- Cycle %0d ---", cycle_count);
            $display("IF:  PC=%h, Instr=%h", uut.pc_current, uut.if_instruction);
            $display("ID:  PC=%h, Instr=%h", uut.id_pc, uut.id_instruction);
            $display("EX:  RS1=%d, RS2=%d, RD=%d, ALU=%h", uut.ex_rs1, uut.ex_rs2, uut.ex_rd, uut.ex_alu_result);
            $display("MEM: RD=%d, ALU=%h, MemRead=%b, MemWrite=%b", uut.mem_rd, uut.mem_alu_result, uut.mem_mem_read, uut.mem_mem_write);
            $display("WB:  RD=%d, Data=%h, RegWrite=%b", uut.wb_rd, uut.wb_reg_write_data, uut.wb_reg_write);

            // Mostra a atividade de forwarding
            if (uut.forward_a != 2'b00 || uut.forward_b != 2'b00) begin
                $display("FORWARDING: A=%b, B=%b", uut.forward_a, uut.forward_b);
            end

            // Mostra a detecção de hazards
            if (uut.control_mux_sel) begin
                $display("HAZARD: Pipeline stalled");
            end

            // Mostra os valores dos registradores
            $display("Regs: x1=%h, x2=%h, x3=%h, x4=%h, x5=%h, x6=%h, x7=%h", 
                    uut.RF.registers[1], uut.RF.registers[2], uut.RF.registers[3], 
                    uut.RF.registers[4], uut.RF.registers[5], uut.RF.registers[6], uut.RF.registers[7]);
            $display("");
        end

        // ---------------- Resultados finais ----------------
        $display("Resultados finais");
        // ---------------- Teste nosso: Resultados -----------------
        $display("x5 (lb):  %h (esperado: 0000000F)", uut.RF.registers[5]);
        $display("x6 (sub): %h (esperado: 00000004)", uut.RF.registers[6]);
        $display("x7 (and): %h (esperado: 00000004)", uut.RF.registers[7]);
        $display("x8 (ori): %h (esperado: 000000F0)", uut.RF.registers[8]);
        $display("x9 (srl): %h (esperado: 0000000F)", uut.RF.registers[9]); // F0 >> 4 = 0x0000000F
        $display("x10 (addi): %h (esperado: 00000000 - pula)", uut.RF.registers[10]);
        $display("Mem[4] (sb): %h (esperado: 0000000F)", uut.DMEM.memory[4]);
        $display("Mem[0] (lb): %h (esperado: 0000000F)", uut.DMEM.memory[0]); // Verifica se o byte foi carregado corretamente

        // // ---------------- Teste do chat: Resultados ----------------
        // $display("x1: %h (initial: 00000010)", uut.RF.registers[1]);
        // $display("x2: %h (initial: 00000005)", uut.RF.registers[2]);
        // $display("x3: %h (expected: 0000001A)", uut.RF.registers[3]); // 16 + 10 = 26
        // $display("x4: %h (expected: 0000001F)", uut.RF.registers[4]); // 26 + 5 = 31
        // $display("x5: %h (expected: 0000000F)", uut.RF.registers[5]); // 31 - 16 = 15
        // $display("x6: %h (expected: 00000020)", uut.RF.registers[6]); // loaded from mem[0]
        // $display("x7: %h (expected: 0000002F)", uut.RF.registers[7]); // 32 + 15 = 47
        // $display("mem[4]: %h (expected: 0000002F)", {uut.DMEM.memory[7], uut.DMEM.memory[6], uut.DMEM.memory[5], uut.DMEM.memory[4]}); // stored x7

        $display("");
        // Imprime os registradores
        $display("");
        $display("Todos os Valores dos Registradores");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d: %h", i, uut.RF.registers[i]);
        end

        $display("");
        $display("Teste concluído!");
        $finish;
    end
endmodule
