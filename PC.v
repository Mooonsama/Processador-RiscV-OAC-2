// Unidade de Contador de Programa
// Esta unidade é responsável por manter o controle do endereço da próxima instrução a ser executada.

module program_counter (
    input wire clk,           // clock
    input wire reset,         // sinal de reset
    input wire [31:0] pc_in,  // valor de entrada (novo endereço)
    output reg [31:0] pc_out  // valor de saída (endereço atual)
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 32'b0;           
        else
            pc_out <= pc_in;           
    end

endmodule