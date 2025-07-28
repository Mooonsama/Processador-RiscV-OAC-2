module mux2x1 (
    
    // Entradas
    input wire [31:0] in1_mux,
    input wire [31:0] in2_mux,
    
    // Controle
    input wire cont_mux,
    
    // Saida
    output reg [31:0] out_mux
);

    always @(*) begin
        if(cont_mux)
            out_mux <= in1_mux;
        else
            out_mux <= in2_mux;
    end

endmodule