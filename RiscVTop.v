// Unidade principal
// Responsável por interconectar os diferentes módulos do processador

`include "Unidade_de_controle.v"
`include "banco_reg_32.v"
`include "GenImm.v"
`include "Unidade_de_controle_ULA.v"
`include "ULA_nova.v"
`include "Controle_de_branch.v"
`include "PC.v"
`include "Memoria_de_instrucao.v"
`include "Memoria_de_dados.v"
`include "PipeIFID.v"
`include "PipeIDEX.v"
`include "PipeEXMEM.v"
`include "PipeMEMWB.v"
`include "fowarding.v"
`include "Hazard_Unit.v"
`include "Mux2x1.v"
`include "Mux3x1.v"

module riscv_top (
    input wire clk,
    input wire reset
);
    // Estágio 1: Busca de Instrução (IF)
    wire [31:0] pc_current, pc_next, pc_plus4;
    wire [31:0] if_instruction;
    wire pc_write, ifid_write;

    // PC + 4
    assign pc_plus4 = pc_current + 4;

    // Implementação do controle de hazard para o PC
    program_counter PCREG (
        .clk(clk),
        .reset(reset),
        .pc_in(pc_write ? pc_next : pc_current),
        .pc_out(pc_current)
    );

    // Implementação da memória de instrução
    instr_memory IMEM (
        .addr(pc_current),
        .instruction(if_instruction)
    );

    // Implementação do registrador de pipeline IF/ID com flush de branch
    wire [31:0] id_instruction, id_pc;
    reg branch_flush_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            branch_flush_reg <= 1'b0;
        else
            branch_flush_reg <= id_branch & (id_reg_data1 == id_reg_data2);
    end
    
    pipe_IF_ID IFID (
        .clk(clk),
        .reset(reset | branch_flush_reg),
        .enable(ifid_write),
        .instr_in(if_instruction),
        .pc_in(pc_current),
        .instr_out(id_instruction),
        .pc_out(id_pc)
    );


    // Estágio 2: Decodificação de Instrução (ID)

    wire [6:0] id_opcode = id_instruction[6:0];
    wire [4:0] id_rd = id_instruction[11:7];
    wire [2:0] id_funct3 = id_instruction[14:12];
    wire [4:0] id_rs1 = id_instruction[19:15];
    wire [4:0] id_rs2 = id_instruction[24:20];
    wire [6:0] id_funct7 = id_instruction[31:25];

    // Gera os sinais de controle para a ULA
    wire id_alu_src, id_mem_to_reg, id_reg_write, id_mem_read, id_mem_write, id_branch;
    wire [1:0] id_alu_op;
    wire control_mux_sel;

    control_unit CU (
        .opcode(id_opcode),
        .reg_write(id_reg_write),
        .mem_to_reg(id_mem_to_reg),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .alu_src(id_alu_src),
        .alu_op(id_alu_op),
        .branch(id_branch)
    );

    // Detecta hazards de dados
    wire hazard_detected;
    hazard_detection_unit HDU (
        .ins(id_instruction),
        .rd(ex_rd),
        .memrd(ex_mem_read),
        .control(hazard_detected),
        .PCWrite(pc_write),
        .IFIDWrite(ifid_write)
    );

    // Só atrasa por um ciclo quando um hazard é detectado
    reg hazard_stall_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            hazard_stall_reg <= 1'b0;
        else
            hazard_stall_reg <= hazard_detected;
    end

    assign control_mux_sel = hazard_detected & ~hazard_stall_reg;

    // Sinais de controle com atraso de hazard
    wire id_alu_src_final = control_mux_sel ? 1'b0 : id_alu_src;
    wire id_mem_to_reg_final = control_mux_sel ? 1'b0 : id_mem_to_reg;
    wire id_reg_write_final = control_mux_sel ? 1'b0 : id_reg_write;
    wire id_mem_read_final = control_mux_sel ? 1'b0 : id_mem_read;
    wire id_mem_write_final = control_mux_sel ? 1'b0 : id_mem_write;
    wire [1:0] id_alu_op_final = control_mux_sel ? 2'b00 : id_alu_op;

    // Registradores
    wire [31:0] id_reg_data1, id_reg_data2;
    registradores RF (
        .clk(clk),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),
        .write_data(wb_reg_write_data),
        .reg_write(wb_reg_write),
        .read_data1(id_reg_data1),
        .read_data2(id_reg_data2)
    );

    // Gera o valor imediato a partir da instrução
    wire [31:0] id_imm_out;
    imm_gen IMM (
        .instr(id_instruction),
        .imm_out(id_imm_out)
    );

    // Registradores do estágio ID/EX
    wire ex_reg_write, ex_mem_to_reg, ex_mem_read, ex_mem_write, ex_alu_src;
    wire [1:0] ex_alu_op;
    wire [31:0] ex_rs1_data, ex_rs2_data, ex_imm;
    wire [4:0] ex_rs1, ex_rs2, ex_rd;
    wire [5:0] ex_funct_combined;
    wire [2:0] ex_funct3 = ex_funct_combined[2:0];
    wire ex_funct7_bit5 = ex_funct_combined[3];

    id_ex IDEX (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .reg_write_in(id_reg_write_final),
        .mem_to_reg_in(id_mem_to_reg_final),
        .mem_read_in(id_mem_read_final),
        .mem_write_in(id_mem_write_final),
        .alu_src_in(id_alu_src_final),
        .alu_op_in(id_alu_op_final),
        .reg_dst_in(1'b0),
        .rs1_data_in(id_reg_data1),
        .rs2_data_in(id_reg_data2),
        .imm_in(id_imm_out),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .funct_in({2'b00, id_funct7[5], id_funct3}),
        .opcode_in({1'b0, id_opcode[6:2]}), 
        .pc_plus4_in(id_pc + 4),
        .reg_write_out(ex_reg_write),
        .mem_to_reg_out(ex_mem_to_reg),
        .mem_read_out(ex_mem_read),
        .mem_write_out(ex_mem_write),
        .alu_src_out(ex_alu_src),
        .alu_op_out(ex_alu_op),
        .reg_dst_out(),  // Não usado
        .rs1_data_out(ex_rs1_data),
        .rs2_data_out(ex_rs2_data),
        .imm_out(ex_imm),
        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rd_out(ex_rd),
        .funct_out(ex_funct_combined), 
        .opcode_out(),  // Não usado em ID
        .pc_plus4_out()
    );

    // Estágio 3: Execução (EX)

    // Unidade de encaminhamento
    wire [1:0] forward_a, forward_b;
    ForwardingUnit FU (
        .EX_MemRegwrite(mem_reg_write),
        .EX_MemWriteReg(mem_rd),
        .Mem_WbRegwrite(wb_reg_write),
        .Mem_WbWriteReg(wb_rd),
        .ID_Ex_Rs(ex_rs1),
        .ID_Ex_Rt(ex_rs2),
        .upperMux_sel(forward_a),
        .lowerMux_sel(forward_b),
        .comparatorMux1Selector(),  // Não usado
        .comparatorMux2Selector()   // Não usado
    );

    // MUX para entrada A da ALU
    wire [31:0] ex_alu_in_a;
    wire [31:0] mem_forward_data = mem_mem_to_reg ? mem_data_out : mem_alu_result;
    mux3x1 MUX_ALU_A (
        .in1_mux(ex_rs1_data),      
        .in2_mux(wb_reg_write_data),
        .in3_mux(mem_forward_data), 
        .cont_mux(forward_a),
        .out_mux(ex_alu_in_a)
    );

    // MUX para entrada B da ALU
    wire [31:0] ex_rs2_forwarded;
    mux3x1 MUX_ALU_B_FWD (
        .in1_mux(ex_rs2_data),      
        .in2_mux(wb_reg_write_data),
        .in3_mux(mem_forward_data), 
        .cont_mux(forward_b),
        .out_mux(ex_rs2_forwarded)
    );

    wire [31:0] ex_alu_in_b;
    assign ex_alu_in_b = ex_alu_src ? ex_imm : ex_rs2_forwarded;

    // Controle ALU
    wire [3:0] ex_alu_ctrl;
    wire [6:0] ex_funct7_full = {1'b0, ex_funct7_bit5, 5'b00000};
    alu_control ALUCTRL (
        .alu_op(ex_alu_op),
        .funct3(ex_funct3),
        .funct7(ex_funct7_full),
        .alu_ctrl(ex_alu_ctrl)
    );

    // ALU
    wire [31:0] ex_alu_result;
    wire ex_zero;
    alu ALU (
        .a(ex_alu_in_a),
        .b(ex_alu_in_b),
        .alu_ctrl(ex_alu_ctrl),
        .result(ex_alu_result),
        .zero(ex_zero),
        .carry(),
        .overflow()
    );

    // Registradores do estágio EX/MEM
    wire mem_reg_write, mem_mem_to_reg, mem_mem_read, mem_mem_write;
    wire [31:0] mem_alu_result, mem_rs2_data;
    wire [4:0] mem_rd;

    ex_mem EXMEM (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .reg_write_in(ex_reg_write),
        .mem_to_reg_in(ex_mem_to_reg),
        .mem_read_in(ex_mem_read),
        .mem_write_in(ex_mem_write),
        .alu_result_in(ex_alu_result),
        .rs2_data_in(ex_rs2_forwarded),
        .rd_in(ex_rd),
        .reg_write_out(mem_reg_write),
        .mem_to_reg_out(mem_mem_to_reg),
        .mem_read_out(mem_mem_read),
        .mem_write_out(mem_mem_write),
        .alu_result_out(mem_alu_result),
        .rs2_data_out(mem_rs2_data),
        .rd_out(mem_rd)
    );

    // Estágio 4: Acesso à Memória
    wire [31:0] mem_data_out;
    data_memory DMEM (
        .clk(clk),
        .mem_read(mem_mem_read),
        .mem_write(mem_mem_write),
        .load_byte(1'b0),  // Simplified
        .store_byte(1'b0), // Simplified
        .addr(mem_alu_result),
        .write_data(mem_rs2_data),
        .read_data(mem_data_out)
    );

    // Registradores do estágio MEM/WB
    wire wb_reg_write, wb_mem_to_reg;
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0] wb_rd;
    
    mem_wb MEMWB (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .reg_write_in(mem_reg_write),
        .mem_to_reg_in(mem_mem_to_reg),
        .read_data_in(mem_data_out),
        .alu_result_in(mem_alu_result),
        .rd_in(mem_rd),
        .reg_write_out(wb_reg_write),
        .mem_to_reg_out(wb_mem_to_reg),
        .read_data_out(wb_read_data),
        .alu_result_out(wb_alu_result),
        .rd_out(wb_rd)
    );

    // Estágio 5: Write Back
    wire [31:0] wb_reg_write_data;
    assign wb_reg_write_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

    // Lógica de branch
    wire branch_taken;
    wire [31:0] branch_target;

    // Cálculo do alvo do branch (PC + imediato)
    assign branch_target = id_pc + id_imm_out;

    // Decisão do branch (simplificada - apenas BEQ por enquanto)
    assign branch_taken = id_branch & (id_reg_data1 == id_reg_data2);

    // Seleção do PC
    assign pc_next = branch_taken ? branch_target : pc_plus4;

endmodule
