// booth_multiplier.v -- top level: signed N x N multiplier, Booth's algorithm
// with a multi-bit (barrel) shift.
//
// Experiment 5 -- Digital Systems Design Lab
//
// It only wires together the two units the assignment asks for:
//
//     booth_control  --- Load, Step --->  booth_datapath
//                    <---- LastStep ---
//
// Handshake: pulse Start for one cycle with the operands valid. Done pulses
// for one cycle when Product is valid, and Product then holds until the next
// Start. A Start arriving during a run is ignored, so the caller only has to
// wait for Done before asking for the next product.
//
// Operands and product are two's complement signed. A run takes 3 cycles of
// overhead plus one cycle per run of multiplier bits: as few as 1 step when the
// multiplier has no run boundaries, against the N steps plain shift-and-add
// always needs.
//
// N is the only knob. Shift distances, shifter rows and counter widths are all
// derived from it inside booth_datapath.v.

module booth_multiplier (Clk, RstN, Start, Multiplicand, Multiplier,
                         Product, Done);

    parameter N = 8; // width

    input wire Clk;
    input wire RstN; // active low
    input wire Start; // start signal
    input wire [N-1:0] Multiplicand;
    input wire [N-1:0] Multiplier;
    output wire [2*N-1:0] Product;
    output wire Done;

    wire Load;
    wire Step;
    wire LastStep;

    booth_control u_control (
        .Clk(Clk),
        .RstN(RstN),
        .Start(Start),
        .LastStep(LastStep),
        .Load(Load),
        .Step(Step),
        .Done(Done)
    );

    booth_datapath #(.N(N)) u_datapath (
        .Clk(Clk),
        .RstN(RstN),
        .Load(Load),
        .Step(Step),
        .Multiplicand(Multiplicand),
        .Multiplier(Multiplier),
        .Product(Product),
        .LastStep(LastStep)
    );

endmodule
