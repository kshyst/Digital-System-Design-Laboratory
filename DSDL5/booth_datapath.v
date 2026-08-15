// booth_datapath.v -- registers, adder/subtractor and barrel shifter of the
// Booth multiplier. It contains no sequencing: every move is commanded by
// booth_control.v through Load and Step.
//
// Experiment 5 -- Digital Systems Design Lab
//
// Register layout (the classic Booth arrangement):
//
//        A (N+1)          Q (N)         Q_1 (1)
//   +---------------+---------------+-------+
//   |  accumulator  |  multiplier   | extra |   shifted as one 2N+2 vector
//   +---------------+---------------+-------+
//
// Everything below is sized from N alone. The one derived quantity is DistW,
// the width of a shift distance: a step never usefully skips more than the N
// multiplier bits, and never less than 1, so distances live in 1 .. N and DistW
// is $clog2(N+1). That same number is the encoder window width, the row count
// of both barrel shifters and the width of the Remaining counter.
//
// Notes on the design choices:
//   * A is N+1 bits, not N. With the most negative multiplicand the step
//     A <= A - M adds +2**(N-1), which an N-bit accumulator cannot hold; it
//     would wrap and the arithmetic shift would then spread the wrong sign.
//     One guard bit removes the case.
//   * Add/subtract and shift happen on the same clock edge, so one step costs
//     one cycle.
//   * A, Q and Q_1 are shifted together by one shifter, so the new Q_1 falls
//     out of the shift for free.
//   * The skip distance comes from a boundary map built once at load time and
//     then shifted along with the rest, not from re-inspecting Q every step.
//   * RstN is asynchronous, active low.
//
// N must be at least 2.

module booth_datapath (Clk, RstN, Load, Step, Multiplicand, Multiplier,
                       Product, LastStep);

    parameter N = 8; // operand width

    // Width of a shift distance, and with it the reach of the shifters:
    // 2**DistW-1 is at least N, so one step can consume the whole multiplier
    // when no boundaries are left in it.
    localparam DistW = $clog2(N+1); // TODO ?

    // The main shifter is twice as wide as the map shifter, so it sizes its own
    // amount port one bit wider. Dist is zero extended to match; that top row
    // is selected by a constant zero and disappears in synthesis.
    localparam ShiftAmountW = $clog2(2*N+2); // TODO ?

    input wire Clk;
    input wire RstN; // active low
    input wire Load; // load inputs
    input wire Step; // apply one step: one add/subtract + shift
    input wire [N-1:0] Multiplicand;
    input wire [N-1:0] Multiplier;
    output wire [2*N-1:0] Product; // output product
    // High during the step that consumes the last multiplier bits, so the
    // control unit knows this Step is the final one and can move on to Done.
    output wire LastStep;

    reg [N:0] A; // accumulator, N+1 bits
    reg [N-1:0] Q; // multiplier, gets shifted out
    reg Q_1; // the Booth extra required bit
    reg [N-1:0] M; // multiplicand
    // steps remaining, in this question where we have variable shift amount
    // it basically means shifts remaining to be done
    reg [DistW-1:0] Remaining; 
    reg [N-1:0] Bmap; // boundary map

    // subtraction or addition 01: addition, 10: subtraction, 00 and 11: no ops
    wire DoAdd = (~Q[0]) & Q_1;
    wire DoSub = Q[0] & ~Q_1;

    // M is N bits but A is N+1, so M has to be widened before it can be added.
    // The operands are signed, so the extra bit is a copy of the sign, not a
    // zero: widening -1 must give -1, not +255.
    wire [N:0] MExt = {M[N-1], M};

    wire [N:0] AOp = DoSub ? (A - MExt) : DoAdd ? (A + MExt) : A;

    // --- boundary map -------------------------------------------------------
    // Booth only works at the boundaries of runs of ones; inside a run every
    // pair recodes to 00 or 11 and the step is a plain shift. Which positions
    // are boundaries is a property of the multiplier alone, so the map is
    // built once at load time instead of being rediscovered every step:
    //
    //     BmapInit[i] = Multiplier[i] ^ Multiplier[i-1],  Multiplier[-1] = 0
    //
    // that is, the multiplier XORed with itself shifted up by one. Bmap then
    // travels with A, Q and Q_1: shifting it right by the same distance keeps
    // Bmap[0] aligned with the position the datapath is working on.
    wire [N-1:0] BmapInit = Multiplier ^ {Multiplier[N-2:0], 1'b0};

    // --- shift distance -----------------------------------------------------
    // Distance to the next boundary above the current position, from a priority
    // encoder over the map. The window is N+1 wide, covering distances 1 .. N,
    // so the encoder can name any distance the multiplier could need and the
    // map needs no padding beyond one bit. That top bit sits above Bmap and is
    // fed a zero, which reads as "no boundary" and is exactly right: above the
    // sign bit the extension is constant, so no boundary can appear there and
    // the step is free to consume the rest of Q in one go.
    wire [DistW-1:0] Raw;

    skip_encode #(.MapW(N+1)) u_encode (
        .Map({1'b0, Bmap}),
        .Dist(Raw)
    );

    // Never shift past the end of the multiplier. Raw is at least 1, so every
    // step makes progress.
    wire [DistW-1:0] Dist = (Raw < Remaining) ? Raw : Remaining;

    assign LastStep = (Dist == Remaining);

    // The map travels with the registers, one shifter of its own.
    wire [N:0] BmapShifted;

    // Its width is N+1, so its amount port is $clog2(N+1) wide: DistW exactly.
    barrel_ashr #(.W(N+1)) u_map_shift (
        .din({1'b0, Bmap}), // zero on top, so the arithmetic fill is zero too
        .amt(Dist),
        .dout(BmapShifted)
    );

    // --- the shifter --------------------------------------------------------
    wire [2*N+1:0] Shifted;

    wire [ShiftAmountW-1:0] DistWide = Dist; // zero extended, see ShiftAmountW above

    barrel_ashr #(.W(2*N+2)) u_shift (
        .din({AOp, Q, Q_1}),
        .amt(DistWide),
        .dout(Shifted)
    );

    // --- state --------------------------------------------------------------
    always @(posedge Clk or negedge RstN) begin
        // async reset
        if (!RstN) begin
            A <= {(N+1){1'b0}};
            Q <= {N{1'b0}};
            Q_1 <= 1'b0;
            M <= {N{1'b0}};
            Remaining <= {DistW{1'b0}};
            Bmap <= {N{1'b0}};
        end
        // load inputs and init
        else if (Load) begin
            A <= {(N+1){1'b0}};
            Q <= Multiplier;
            Q_1 <= 1'b0;
            M <= Multiplicand;
            Remaining <= N; // N shifts remaining
            Bmap <= BmapInit;
        end
        else if (Step) begin
            // shift the entire tuple
            {A, Q, Q_1} <= Shifted;
            // decrease the steps remaining
            Remaining <= Remaining - Dist;
            // shift the boundry map
            Bmap <= BmapShifted[N-1:0];
        end
        // Otherwise hold: the result stays readable until the next Load.
    end

    // After N bits have been shifted through, the product is the low 2N bits
    // of {A, Q}.
    assign Product = {A[N-1:0], Q};

endmodule
