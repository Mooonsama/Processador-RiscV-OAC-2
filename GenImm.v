// Gerador de Imediato
// Este módulo gera o valor imediato a partir da instrução.

module imm_gen (
    input wire [31:0] instr,
    output reg [31:0] imm_out
);

    wire [6:0] opcode = instr[6:0];
    
    always @(*) begin
        case (opcode)
            7'b0010011, // I-type: addi, ori, andi...
            7'b0000011, // I-type: lw
            7'b1100111: // I-type: jalr
                imm_out = {{20{instr[31]}}, instr[31:20]};

            7'b0100011: begin // S-type: sw, sb, sh
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            7'b1100011: begin // B-type: beq, bne, etc.
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            7'b0010111, // U-type: auipc
            7'b0110111: // U-type: lui
                imm_out = {instr[31:12], 12'b0};

            7'b1101111: begin // J-type: jal
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            default: imm_out = 32'b0; // fallback
        endcase
    end

endmodule