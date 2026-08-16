// Returns the distance to the nearest upcoming Booth boundary.
module skip_encode (Map, Dist);

    parameter MapW = 9;
    localparam DistW = $clog2(MapW);
    localparam MaxSkip = MapW - 1;

    input wire [MapW-1:0] Map;
    output reg [DistW-1:0] Dist;

    integer k;

    always @* begin
        Dist = MaxSkip;
        // Descending scan lets the nearest (lowest) set bit win.
        for (k = MaxSkip; k >= 1; k = k - 1)
            if (Map[k]) Dist = k;
    end

endmodule
