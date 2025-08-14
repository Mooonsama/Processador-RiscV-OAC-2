// Unidade de Pipeline IF/ID
// Esta unidade é responsável por armazenar os dados da fase de instrução até a fase de decodificação.

module pipe_IF_ID (
    input wire clk,
    input wire reset,
    input wire enable,               // Controle de stall (1 = permite avanço)
    input wire [31:0] instr_in,      // Instrução vinda do estágio IF
    input wire [31:0] pc_in,         // Contador do PC que vem de IF

    output reg [31:0] instr_out,     // Instrução para o estágio ID
    output reg [31:0] pc_out  		 // Contador do PC para o estágio ID
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin    // Reseta os sinais de controle e dados
            instr_out     <= 32'b0;
            pc_out  <= 32'b0;
        end
        else if (enable) begin     // Armazenar dados na transição de clock
            instr_out     <= instr_in;
            pc_out  <= pc_in;
        end
        // Se enable = 0, mantem os valores antigos para fazer stall
        // Se tiver tempo a gente organiza esses comentários
    end

endmodule