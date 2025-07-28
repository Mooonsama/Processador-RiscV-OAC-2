module alu_control (
    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire [6:0] funct7, // geralmente instr[30] para R-type
    output reg [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0010; // lw/sw/addi → soma
            2'b01: alu_ctrl = 4'b0110; // beq → subtração
            2'b10: begin // R-type ou I-type lógico
                case (funct3)
                    3'b000: begin // add/addi or sub
                        if (funct7[5] == 1'b1) // sub (only for R-type)
                            alu_ctrl = 4'b0110; 
                        else
                            alu_ctrl = 4'b0010; // add/addi
                    end
                    3'b111: alu_ctrl = 4'b0000; // and/andi
                    3'b110: alu_ctrl = 4'b0001; // or/ori
                    3'b100: alu_ctrl = 4'b0100; // xor/xori
                    3'b001: alu_ctrl = 4'b1000; // sll/slli
                    3'b101: begin // srl/srli or sra/srai
                        if (funct7[5] == 1'b1) // sra/srai
                            alu_ctrl = 4'b1010;
                        else
                            alu_ctrl = 4'b1001; // srl/srli
                    end
                    3'b010: alu_ctrl = 4'b0111; // slt/slti
                    3'b011: alu_ctrl = 4'b1011; // sltu/sltiu
                    default: alu_ctrl = 4'b1111;
                endcase
            end
            default: alu_ctrl = 4'b1111;
        endcase
    end
endmodule