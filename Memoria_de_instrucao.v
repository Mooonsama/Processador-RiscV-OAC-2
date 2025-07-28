module instr_memory (
    input  wire        clk,           // Ja que tem escrita em registrador, melhor colocar
    input  wire        write,         // Sinal de controle sincrono
    input  wire [31:0] addr,          // Endereço da instrução (PC)
    input  wire [31:0] inst_input,    // Instrução a ser gravada
    output wire [31:0] instruction    // Instrução lida
);

    // Memória com 256 posições de 32 bits
    reg [31:0] memory [0:255];

    // Escrita síncrona na memória (manual)
    always @(posedge clk) begin
        if (write)
            memory[addr[31:2]] <= inst_input;
    end

    assign instruction = memory[addr[31:2]];

endmodule