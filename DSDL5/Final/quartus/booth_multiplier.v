// Signed N x N Booth multiplier with variable-distance shifts.
// Pulse Start for one cycle while operands are stable. Done pulses when Product
// is valid; busy Start pulses are ignored and Product holds until the next run.

module booth_multiplier (Clk, RstN, Start, Multiplicand, Multiplier,
                         Product, Done);

    parameter N = 8;

    input wire Clk;
    input wire RstN;
    input wire Start;
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
