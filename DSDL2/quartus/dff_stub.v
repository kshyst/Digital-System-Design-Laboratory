// Minimal behavioral stand-in for Altera's DFF primitive, used only to
// simulate the Quartus-exported netlist outside Quartus (iverilog doesn't
// know Altera's device primitive library). CLRN is active-low async clear.
module DFF(CLRN, D, CLK, Q);
    input CLRN, D, CLK;
    output reg Q;
    always @(posedge CLK or negedge CLRN)
        if (!CLRN) Q <= 1'b0;
        else       Q <= D;
endmodule
