// booth_multiplier_tb.v -- self-checking testbench for booth_multiplier.v
//
//     iverilog -o booth_tb.out barrel_ashr.v skip_encode.v booth_datapath.v \
//              booth_control.v booth_multiplier.v booth_multiplier_tb.v
//     vvp booth_tb.out
//
// Experiment 5 -- Digital Systems Design Lab
//
// Phase 1 is directed: the corner cases, including the ones that break naive
// versions of this design (most negative operand, alternating bits). Phase 2
// runs all 256*256 signed operand pairs against Verilog's own signed multiply,
// so for N=8 the design is proven rather than sampled, and it collects the
// step counts the report compares against plain shift-and-add.
//
// Waveforms are dumped for the directed phase only.

`timescale 1ns / 1ps

module booth_multiplier_tb;

    parameter N = 8;
    parameter CYCLE = 10; // 100 MHz

    reg Clk;
    reg RstN;
    reg Start;
    reg [N-1:0] Multiplicand;
    reg [N-1:0] Multiplier;
    wire [2*N-1:0] Product;
    wire Done;

    reg [2*N-1:0] Got; // product captured at Done
    integer RunSteps; // CALC cycles of the current run
    integer SumSteps; // over the whole exhaustive phase
    integer MaxSteps;
    integer MinSteps;

    reg signed [2*N-1:0] Expected;
    reg [31:0] Errors;
    reg [31:0] Runs;
    integer i, j;

    booth_multiplier #(.N(N)) dut (
        .Clk(Clk),
        .RstN(RstN),
        .Start(Start),
        .Multiplicand(Multiplicand),
        .Multiplier(Multiplier),
        .Product(Product),
        .Done(Done)
    );

    initial Clk = 1'b0;
    always #(CYCLE/2) Clk = ~Clk;

    // A CALC cycle is exactly a cycle in which the control unit asserts Step.
    always @(posedge Clk)
        if (dut.Step) RunSteps = RunSteps + 1;

    // Drive one multiplication and check the result.
    task do_mul;
        input reg [N-1:0] a;
        input reg [N-1:0] b;
        begin
            @(negedge Clk);
            Multiplicand = a;
            Multiplier = b;
            Start = 1'b1;
            RunSteps = 0;

            @(negedge Clk);
            Start = 1'b0;

            while (!Done) @(negedge Clk);
            Got = Product;

            Expected = $signed(a) * $signed(b);
            Runs = Runs + 1;

            if (Got !== Expected) begin
                Errors = Errors + 1;
                $display("FAIL: %0d * %0d -> %0d (%h), expected %0d (%h)",
                         $signed(a), $signed(b), $signed(Got), Got,
                         Expected, Expected);
            end

            SumSteps = SumSteps + RunSteps;
            if (RunSteps > MaxSteps) MaxSteps = RunSteps;
            if (RunSteps < MinSteps) MinSteps = RunSteps;
        end
    endtask

    // Same, but prints the case: used for the directed phase so the transcript
    // can go straight into the report.
    task show_mul;
        input reg [N-1:0] a;
        input reg [N-1:0] b;
        input reg [8*44-1:0] note;
        begin
            do_mul(a, b);
            $display("  %5d * %5d = %6d   steps: %0d   %0s",
                     $signed(a), $signed(b), $signed(Got), RunSteps, note);
        end
    endtask

    initial begin
        Errors = 0;
        Runs = 0;
        SumSteps = 0;
        MaxSteps = 0;
        MinSteps = 1000;
        RunSteps = 0;

        $dumpfile("booth_multiplier_tb.vcd");
        $dumpvars(0, booth_multiplier_tb);

        Start = 1'b0;
        Multiplicand = {N{1'b0}};
        Multiplier = {N{1'b0}};

        RstN = 1'b0;
        repeat (2) @(negedge Clk);
        RstN = 1'b1;
        @(negedge Clk);

        // --- phase 1: directed corner cases ---------------------------------
        $display("");
        $display("--- directed cases ---");

        show_mul(8'd0, 8'd0, "zero");
        show_mul(8'd0, -8'd128, "zero x min");
        show_mul(8'd1, 8'd1, "one");
        show_mul(-8'd1, -8'd1, "-1 x -1");
        show_mul(8'd3, 8'd5, "small positive");
        show_mul(-8'd3, 8'd5, "negative x positive");
        show_mul(8'd3, -8'd5, "positive x negative");
        show_mul(-8'd3, -8'd5, "negative x negative");
        show_mul(8'd3, 8'd7, "run of ones in Q");
        show_mul(-8'd128, 8'd2, "min x 2: overflows an N-bit accumulator");
        show_mul(-8'd128, -8'd128, "min x min: largest product");
        show_mul(8'd127, 8'd127, "max x max");
        show_mul(-8'd128, 8'd127, "min x max");
        show_mul(8'h55, 8'hAA, "alternating bits: worst case");
        show_mul(8'd5, -8'd1, "all ones multiplier: best case");

        if (Errors == 0) $display("  directed cases clean");

        // --- phase 2: exhaustive --------------------------------------------
        $dumpoff; // 65536 runs would make the VCD useless
        $display("");
        $display("--- exhaustive: all %0d signed operand pairs ---", 256*256);

        Runs = 0;
        SumSteps = 0;
        MaxSteps = 0;
        MinSteps = 1000;

        for (i = 0; i < 256; i = i + 1)
            for (j = 0; j < 256; j = j + 1)
                do_mul(i[N-1:0], j[N-1:0]);

        $display("  %0d products checked against Verilog signed multiply", Runs);
        $display("");
        $display("--- cycle cost per multiply (CALC steps only) ---");
        $display("  plain shift-and-add / 1-bit Booth: %0d steps always", N);
        $display("  this design: min %0d, max %0d, average %0.2f  (%0.1f%% of it)",
                 MinSteps, MaxSteps, SumSteps * 1.0 / Runs,
                 SumSteps * 100.0 / (Runs * N));

        $display("");
        if (Errors == 0)
            $display("========== PASS: booth_multiplier clean ==========");
        else
            $display("========== FAIL: %0d error(s) ==========", Errors);
        $finish;
    end

endmodule
