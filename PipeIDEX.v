// Unidade de Pipeline ID/EX
// Esta unidade é responsável por armazenar os dados da fase de decodificação até a fase de execução.

module id_ex (
    input wire clk,
    input wire reset,
    input wire enable,

    // Separa controle para facilitar dps
    input wire reg_write_in,
    input wire mem_to_reg_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire alu_src_in,
    input wire [1:0] alu_op_in,
    input wire reg_dst_in,

    // Entrada
    input wire [31:0] rs1_data_in,
    input wire [31:0] rs2_data_in,
    input wire [31:0] imm_in,
    input wire [4:0] rs1_in,
    input wire [4:0] rs2_in,
    input wire [4:0] rd_in,
    input wire [5:0] funct_in,
    input wire [5:0] opcode_in,
    input wire [31:0] pc_plus4_in,

    // Saidas
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg alu_src_out,
    output reg [1:0] alu_op_out,
    output reg reg_dst_out,

    // Dados
    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] imm_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [5:0] funct_out,
    output reg [5:0] opcode_out,
    output reg [31:0] pc_plus4_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin    // Reseta os sinais de controle e dados
            reg_write_out   <= 0;
            mem_to_reg_out  <= 0;
            mem_read_out    <= 0;
            mem_write_out   <= 0;
            alu_src_out     <= 0;
            alu_op_out      <= 0;
            reg_dst_out     <= 0;

            rs1_data_out    <= 0;
            rs2_data_out    <= 0;
            imm_out         <= 0;
            rs1_out         <= 0;
            rs2_out         <= 0;
            rd_out          <= 0;
            funct_out       <= 0;
            opcode_out      <= 0;
            pc_plus4_out    <= 0;
        end
        else if (enable) begin     // Armazenar dados na transição de clock
            reg_write_out   <= reg_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            alu_src_out     <= alu_src_in;
            alu_op_out      <= alu_op_in;
            reg_dst_out     <= reg_dst_in;

            rs1_data_out    <= rs1_data_in;
            rs2_data_out    <= rs2_data_in;
            imm_out         <= imm_in;
            rs1_out         <= rs1_in;
            rs2_out         <= rs2_in;
            rd_out          <= rd_in;
            funct_out       <= funct_in;
            opcode_out      <= opcode_in;
            pc_plus4_out    <= pc_plus4_in;
        end
        // Se enable = 0, mantem os valores antigos para fazer stall
    end

endmodule