// Banco de registradores de 32 bits

module registradores(
    input clk,
    input [4:0] rs1, // Registrador de leitura 1
    input [4:0] rs2, // Registrador de leitura 2
    input [4:0] rd, // Registrador de escrita
    input [31:0] write_data, // Dados a serem escritos
    input reg_write, // Habilita escrita no registrador
    output reg [31:0] read_data1, // Dados lidos do registrador 1
    output reg [31:0] read_data2 // Dados lidos do registrador 2
);

    reg [31:0] registers [31:0]; // Array de 32 de registradores de 32 bits

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'h00000000;
        end
    end

    always @(posedge clk) begin
        if (reg_write) begin
            if (rd != 5'd0) // Verifica se não é o registrador zero
                registers[rd] <= write_data; // Escreve dados no registrador especificado
        end
    end

    always @(*) begin
        read_data1 = registers[rs1]; // Lê dados do registrador 1
        read_data2 = registers[rs2]; // Lê dados do registrador 2
    end
endmodule