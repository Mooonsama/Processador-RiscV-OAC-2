module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output reg         zero,
    output reg         carry,
    output reg         overflow
);

    always @(*) begin
        carry    = 0;
        overflow = 0;

        case (alu_ctrl)
            4'b0010: begin // Soma (ADD)
                {carry, result} = a + b;
                overflow = (a[31] == b[31]) && (result[31] != a[31]);
            end
            4'b0110: begin // Subtração (SUB)
                result   = a - b;
                overflow = (a[31] != b[31]) && (result[31] != a[31]);
            end
            4'b0000: result = a & b;        // AND
            4'b0001: result = a | b;        // OR
            4'b0100: result = a ^ b;        // XOR (added for completeness)
            4'b1000: result = a << b[4:0];  // SLL (Shift Left Logical)
            4'b1001: result = a >> b[4:0];  // SRL (Shift Right Logical)
            4'b1010: result = $signed(a) >>> b[4:0]; // SRA (Shift Right Arithmetic) - added
            4'b0111: result = (a < b) ? 32'b1 : 32'b0; // SLT (Set Less Than) - added
            4'b1011: result = ($unsigned(a) < $unsigned(b)) ? 32'b1 : 32'b0; // SLTU - added
            default: result = 32'b0;
        endcase

        zero = (result == 32'b0);
    end
endmodule