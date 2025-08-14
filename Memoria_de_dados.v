// Unidade de Memória de Dados
// Este módulo é responsável por ler e escrever dados na memória.

module data_memory (
    input wire        clk,
    input wire        mem_read,
    input wire        mem_write,
    input wire        load_byte,    // 1 para lb
    input wire        store_byte,   // 1 para sb
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

    // Memória byte-endereçável com 4KB
    reg [7:0] memory [0:4095];
    
    integer i;
    // Inicializa a memória
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            memory[i] = 8'h00;
        end
    end

    always @(posedge clk) begin
        if (mem_write) begin
            if (store_byte) begin
                memory[addr] <= write_data[7:0]; // escreve apenas 1 byte
            end else begin
                // escreve os 4 bytes da palavra
                memory[addr]     <= write_data[7:0];
                memory[addr + 1] <= write_data[15:8];
                memory[addr + 2] <= write_data[23:16];
                memory[addr + 3] <= write_data[31:24];
            end
        end
    end

    always @(*) begin
        if (mem_read) begin
            if (load_byte) begin
                // Leitura de 1 byte com extensão de sinal
                read_data = {{24{memory[addr][7]}}, memory[addr]};
            end else begin
                // Leitura de 4 bytes como palavra
                read_data = { memory[addr + 3],
                            memory[addr + 2],
                            memory[addr + 1],
                            memory[addr] 
                            };
            end
        end else begin
            read_data = 32'b0;
        end
    end

endmodule