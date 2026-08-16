// Variable-distance combinational arithmetic-right shifter.
module barrel_ashr (din, amt, dout);
    parameter W = 18;
    localparam AmountW = $clog2(W);

    input wire [W-1:0] din;
    input wire [AmountW-1:0] amt;
    output reg [W-1:0] dout;

    integer k;

    always @* begin
        dout = din;
        for (k = 0; k < AmountW; k = k + 1)
            if (amt[k]) dout = $signed(dout) >>> (1 << k);
    end

endmodule
