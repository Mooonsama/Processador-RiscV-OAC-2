module mux3x1 (
    
    // Entradas
    input wire [31:0] in1_mux,
    input wire [31:0] in2_mux,
    input wire [31:0] in3_mux,
    
    // Controle
    input wire [1:0] cont_mux,
    
    // Saída
    output wire [31:0] out_mux
);

    assign out_mux =
        (cont_mux == 2'b00) ? in1_mux :
        (cont_mux == 2'b01) ? in2_mux :
        (cont_mux == 2'b10) ? in3_mux :
        32'bx; 
endmodule