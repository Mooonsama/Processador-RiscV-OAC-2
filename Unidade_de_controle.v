module control_unit (
    input  wire [6:0] opcode,    // instr[6:0]
    output reg       reg_write,
    output reg       mem_to_reg,
    output reg       mem_read,
    output reg       mem_write,
    output reg       alu_src,
    output reg [1:0] alu_op,
    output reg       branch
);

    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type (add, sub, and, or...)
                reg_write   = 1;
                mem_to_reg  = 0;
                mem_read    = 0;
                mem_write   = 0;
                alu_src     = 0;
                alu_op      = 2'b10;
                branch     = 0;
            end
            7'b0000011: begin // lw (I-type)
                reg_write   = 1;
                mem_to_reg  = 1;
                mem_read    = 1;
                mem_write   = 0;
                alu_src     = 1;
                alu_op      = 2'b00;
                branch     = 0;
            end
            7'b0100011: begin // sw (S-type)
                reg_write   = 0;
                mem_to_reg  = 0; // irrelevante
                mem_read    = 0;
                mem_write   = 1;
                alu_src     = 1;
                alu_op      = 2'b00;
                branch     = 0;
            end
            7'b1100011: begin // beq, bne (B-type)
                reg_write   = 0;
                mem_to_reg  = 0;
                mem_read    = 0;
                mem_write   = 0;
                alu_src     = 0;
                alu_op      = 2'b01;
                branch     = 1;
            end
            7'b0010011: begin // addi, ori, andi (I-type)
                reg_write   = 1;
                mem_to_reg  = 0;
                mem_read    = 0;
                mem_write   = 0;
                alu_src     = 1;
                alu_op      = 2'b10;
                branch     = 0;
            end
            default: begin // default (NOP)
                reg_write   = 0;
                mem_to_reg  = 0;
                mem_read    = 0;
                mem_write   = 0;
                alu_src     = 0;
                alu_op      = 2'b00;
                branch     = 0;
            end
        endcase
    end
endmodule