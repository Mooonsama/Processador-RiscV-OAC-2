// Unidade de Forwarding
// Este módulo é responsável por encaminhar os dados corretos para os multiplexadores, evitando hazards.

module ForwardingUnit (
    input EX_MemRegwrite,
    input [4:0] EX_MemWriteReg,
    input Mem_WbRegwrite,
    input [4:0] Mem_WbWriteReg,
    input [4:0] ID_Ex_Rs,
    input [4:0] ID_Ex_Rt,
    output reg [1:0] upperMux_sel,
    output reg [1:0] lowerMux_sel,
    output reg [1:0] comparatorMux1Selector,
    output reg [1:0] comparatorMux2Selector
    );

    always@(*) begin
        // Inicia sem forwarding
        upperMux_sel = 2'b00;
        lowerMux_sel = 2'b00;
        comparatorMux1Selector = 2'b00;
        comparatorMux2Selector = 2'b00;
        
        // Forward do RS1 (upperMux_sel)
        if (EX_MemRegwrite && (EX_MemWriteReg != 5'b00000) && (EX_MemWriteReg == ID_Ex_Rs)) begin
            // Encaminha dados do estágio EX/MEM    
            upperMux_sel = 2'b10;
            comparatorMux1Selector = 2'b01;
        end
        else if (Mem_WbRegwrite && (Mem_WbWriteReg != 5'b00000) && (Mem_WbWriteReg == ID_Ex_Rs)) begin
            // Encaminha dados do estágio MEM/WB
            upperMux_sel = 2'b01;
            comparatorMux1Selector = 2'b10;
        end
        
        // Forward do RS2 (lowerMux_sel)
        if (EX_MemRegwrite && (EX_MemWriteReg != 5'b00000) && (EX_MemWriteReg == ID_Ex_Rt)) begin
            // Encaminha dados do estágio EX/MEM
            lowerMux_sel = 2'b10;
            comparatorMux2Selector = 2'b01;
        end
        else if (Mem_WbRegwrite && (Mem_WbWriteReg != 5'b00000) && (Mem_WbWriteReg == ID_Ex_Rt)) begin
            // Encaminha dados do estágio MEM/WB
            lowerMux_sel = 2'b01;
            comparatorMux2Selector = 2'b10;
        end
    end
endmodule