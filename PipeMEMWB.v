// Unidade de Pipeline MEM/WB
// Esta unidade é responsável por armazenar os dados da fase de memória até a fase de escrita.

module mem_wb (
    input wire clk,
    input wire reset,
    input wire enable,

    // Controle
    input wire reg_write_in,
    input wire mem_to_reg_in,

    // Entrada
    input wire [31:0] read_data_in,
    input wire [31:0] alu_result_in,
    input wire [4:0]  rd_in,

    // Saidas
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg [31:0] read_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0]  rd_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin   // Reseta os sinais de controle e dados
            reg_write_out    <= 0;
            mem_to_reg_out   <= 0;
            read_data_out    <= 0;
            alu_result_out   <= 0;
            rd_out           <= 0;
        end
        else if (enable) begin     // Armazenar dados na transição de clock
            reg_write_out    <= reg_write_in;
            mem_to_reg_out   <= mem_to_reg_in;
            read_data_out    <= read_data_in;
            alu_result_out   <= alu_result_in;
            rd_out           <= rd_in;
        end
        // enable stall
    end

endmodule
