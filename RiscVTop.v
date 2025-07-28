`include "Unidade_de_controle.v"
`include "banco_reg_32.v"
`include "GenImm.v"
`include "Unidade_de_controle_ULA.v"
`include "ULA_nova.v"
`include "Controle_de_branch.v"
`include "PC.v"
`include "Memoria_de_instrucao.v"
`include "Memoria_de_dados.v"


module riscv_top (
    input wire clk,
    input wire reset
);

    // === Fios e sinais ===
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    wire [31:0] instruction;

    // Fios para campos da instrução
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    // Unidade de Controle
    wire alu_src, mem_to_reg, reg_write, mem_read, mem_write, branch;
    wire [1:0] alu_op;

    control_unit CU (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch)
    );

    // Registradores
    wire [31:0] reg_data1, reg_data2, reg_write_data;
    registradores RF (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(reg_write_data),
        .reg_write(reg_write),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    // Imediato
    wire [31:0] imm_out;
    imm_gen IMM (
        .instr(instruction),
        .imm_out(imm_out)
    );

    // ALU control
    wire [3:0] alu_ctrl;
    alu_control ALUCTRL (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .alu_ctrl(alu_ctrl)
    );

    // Mux ALU src
    wire [31:0] alu_in2;
    assign alu_in2 = (alu_src) ? imm_out : reg_data2;

    // ALU
    wire [31:0] alu_result;
    wire zero, carry, overflow;
    alu ALU (
        .a(reg_data1),
        .b(alu_in2),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero),
        .carry(carry),
        .overflow(overflow)
    );

    // PC + 4
    assign pc_plus4 = pc_current + 4;

    // PC + imediato (branch)
    wire [31:0] pc_branch = pc_current + imm_out;

    // Branch control (PC mux)
    branch_control BRCTRL (
        .branch(branch),
        .zero(zero),
        .pc_plus_4(pc_plus4),
        .pc_branch(pc_branch),
        .pc_next(pc_next)
    );

    // PC
    program_counter PCREG (
        .clk(clk),
        .reset(reset),
        .pc_in(pc_next),
        .pc_out(pc_current)
    );

    // Memória de instrução
    instr_memory IMEM (
        .addr(pc_current),
        .instruction(instruction)
    );

    // Memória de dados
    wire [31:0] data_memory_out;
    wire load_byte = (opcode == 7'b0000011 && funct3 == 3'b000);
    wire store_byte = (opcode == 7'b0100011 && funct3 == 3'b000);

    data_memory DMEM (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .load_byte(load_byte),
        .store_byte(store_byte),
        .addr(alu_result),
        .write_data(reg_data2),
        .read_data(data_memory_out)
    );

    // Mux de escrita no registrador
    assign reg_write_data = (mem_to_reg) ? data_memory_out : alu_result;

endmodule
