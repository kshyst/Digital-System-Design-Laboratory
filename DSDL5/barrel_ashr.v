// combinational arithmetic right barrel shifter
module barrel_ashr (din, amt, dout);
    parameter W = 18; // width of the input vector
    localparam AmountW = $clog2(W); // number of shift levels

    input wire [W-1:0] din; // input
    input wire [AmountW-1:0] amt; // input shift amount
    output reg [W-1:0] dout; // shifted output

    integer k;

    always @* begin
        dout = din;
        // update the value
        for (k = 0; k < AmountW; k = k + 1)
            if (amt[k]) dout = $signed(dout) >>> (1 << k);
    end

endmodule
