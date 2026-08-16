`timescale 1ns / 1ps

module booth_multiplier_3x7_tb;

    reg Clk;
    reg RstN;
    reg Start;
    reg [7:0] Multiplicand;
    reg [7:0] Multiplier;
    wire [15:0] Product;
    wire Done;

    booth_multiplier dut (
        .Clk(Clk),
        .RstN(RstN),
        .Start(Start),
        .Multiplicand(Multiplicand),
        .Multiplier(Multiplier),
        .Product(Product),
        .Done(Done)
    );

    initial Clk = 1'b0;
    always #5 Clk = ~Clk;

    initial begin
        $dumpfile("booth_multiplier_3x7_tb.vcd");
        $dumpvars(0, booth_multiplier_3x7_tb);

        RstN = 1'b0;
        Start = 1'b0;
        Multiplicand = 8'd0;
        Multiplier = 8'd0;

        repeat (2) @(negedge Clk);
        RstN = 1'b1;

        @(negedge Clk);
        Multiplicand = 8'd3;
        Multiplier = 8'd7;
        Start = 1'b1;

        @(negedge Clk);
        Start = 1'b0;

        wait (Done);
        #1;

        if (Product === 16'd21)
            $display("PASS: 3 * 7 = %0d", Product);
        else
            $fatal(1, "FAIL: 3 * 7 = %0d, expected 21", Product);

        @(negedge Clk);
        $finish;
    end

endmodule
