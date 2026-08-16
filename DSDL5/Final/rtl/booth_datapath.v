// Booth datapath: {A, Q, Q_1} is shifted as one 2N+2-bit register.
// A has a guard bit so negating the most-negative N-bit value cannot overflow.
// A precomputed boundary map enables multi-bit skips between Booth operations.
// N must be at least 2.

module booth_datapath (Clk, RstN, Load, Step, Multiplicand, Multiplier,
                       Product, LastStep);

    parameter N = 8;

    localparam DistW = $clog2(N+1);
    localparam ShiftAmountW = $clog2(2*N+2);

    input wire Clk;
    input wire RstN;
    input wire Load;
    input wire Step;
    input wire [N-1:0] Multiplicand;
    input wire [N-1:0] Multiplier;
    output wire [2*N-1:0] Product;
    // High while the current Step consumes every remaining multiplier bit.
    output wire LastStep;

    reg [N:0] A;
    reg [N-1:0] Q;
    reg Q_1;
    reg [N-1:0] M;
    reg [DistW-1:0] Remaining;
    reg [N-1:0] Bmap;

    // Booth pair 01 adds, 10 subtracts, and 00/11 only shift.
    wire DoAdd = (~Q[0]) & Q_1;
    wire DoSub = Q[0] & ~Q_1;

    // Sign extension preserves negative M values in the wider accumulator.
    wire [N:0] MExt = {M[N-1], M};

    wire [N:0] AOp = DoSub ? (A - MExt) : DoAdd ? (A + MExt) : A;

    // A set bit marks a Booth transition: Q[i] XOR Q[i-1], with Q[-1]=0.
    // The map shifts with Q so bit zero always describes the current position.
    wire [N-1:0] BmapInit = Multiplier ^ {Multiplier[N-2:0], 1'b0};

    // The leading zero lets the encoder return N when no boundary remains.
    wire [DistW-1:0] Raw;

    skip_encode #(.MapW(N+1)) u_encode (
        .Map({1'b0, Bmap}),
        .Dist(Raw)
    );

    // Cap the skip at the number of unprocessed multiplier bits.
    wire [DistW-1:0] Dist = (Raw < Remaining) ? Raw : Remaining;

    assign LastStep = (Dist == Remaining);

    wire [N:0] BmapShifted;

    barrel_ashr #(.W(N+1)) u_map_shift (
        .din({1'b0, Bmap}),
        .amt(Dist),
        .dout(BmapShifted)
    );

    wire [2*N+1:0] Shifted;

    wire [ShiftAmountW-1:0] DistWide = Dist;

    barrel_ashr #(.W(2*N+2)) u_shift (
        .din({AOp, Q, Q_1}),
        .amt(DistWide),
        .dout(Shifted)
    );

    always @(posedge Clk or negedge RstN) begin
        if (!RstN) begin
            A <= {(N+1){1'b0}};
            Q <= {N{1'b0}};
            Q_1 <= 1'b0;
            M <= {N{1'b0}};
            Remaining <= {DistW{1'b0}};
            Bmap <= {N{1'b0}};
        end
        else if (Load) begin
            A <= {(N+1){1'b0}};
            Q <= Multiplier;
            Q_1 <= 1'b0;
            M <= Multiplicand;
            Remaining <= N;
            Bmap <= BmapInit;
        end
        else if (Step) begin
            {A, Q, Q_1} <= Shifted;
            Remaining <= Remaining - Dist;
            Bmap <= BmapShifted[N-1:0];
        end
    end

    // Drop A's guard bit after all N multiplier bits have been consumed.
    assign Product = {A[N-1:0], Q};

endmodule
