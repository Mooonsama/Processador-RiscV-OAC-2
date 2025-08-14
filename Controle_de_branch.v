// Módulo de controle de branch
// Este módulo determina o próximo endereço do PC com base no controle de branch e na saída da ALU.


module branch_control (
    input  wire        branch,      // Sinal da unidade de controle
    input  wire        zero,        // Flag de igualdade da ALU
    input  wire [31:0] pc_plus_4,   // PC + 4 (próxima instrução normal)
    input  wire [31:0] pc_branch,   // PC + offset (caso branch)
    output wire [31:0] pc_next      // Próximo PC
);

    assign pc_next = (branch && zero) ? pc_branch : pc_plus_4;

endmodule