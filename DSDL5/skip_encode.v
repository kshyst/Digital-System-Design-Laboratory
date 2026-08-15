// priority encoder that picks the shift distance
// outputs Dist which is the distance to the next boundary
// it basically finds the shift amount for the variable shift mentioned in the question
module skip_encode (Map, Dist);

    parameter MapW = 9; // Map width
    localparam DistW = $clog2(MapW); // just wide enough to hold MapW-1
    localparam MaxSkip = MapW - 1;

    input wire [MapW-1:0] Map;
    output reg [DistW-1:0] Dist;

    integer k;

    always @* begin
        // default value incase no match
        Dist = MaxSkip;
        // priority encoder by nature
        for (k = MaxSkip; k >= 1; k = k - 1)
            if (Map[k]) Dist = k;
    end

endmodule
