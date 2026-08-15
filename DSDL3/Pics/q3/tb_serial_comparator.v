`timescale 1ns/1ps

module tb_serial_comparator;
    reg  clk;
    reg  reset;
    reg  a;
    reg  b;
    wire gt;
    wire eq;
    wire lt;
    integer ai;
    integer bi;
    integer bit_index;
    reg expected_gt;
    reg expected_eq;
    reg expected_lt;

    serial_comparator dut(clk, reset, a, b, gt, eq, lt);

    task do_reset;
        begin
            clk = 0;
            reset = 1;
            #1;
            if ({gt, eq, lt} !== 3'b010) begin
                $display("FAIL: reset gt=%b eq=%b lt=%b", gt, eq, lt);
                $finish;
            end
            reset = 0;
            #1;
        end
    endtask

    task compare_bit;
        input a_bit;
        input b_bit;
        input expected_gt;
        input expected_eq;
        input expected_lt;
        begin
            a = a_bit;
            b = b_bit;
            #1;
            clk = 1;
            #1;
            if ({gt, eq, lt} !== {expected_gt, expected_eq, expected_lt}) begin
                $display("FAIL: a=%b b=%b gt=%b eq=%b lt=%b expected=%b%b%b",
                         a, b, gt, eq, lt,
                         expected_gt, expected_eq, expected_lt);
                $finish;
            end
            clk = 0;
            #1;
        end
    endtask

    initial begin
        clk = 0;
        reset = 0;
        a = 0;
        b = 0;

        for (ai = 0; ai < 16; ai = ai + 1) begin
            for (bi = 0; bi < 16; bi = bi + 1) begin
                do_reset;
                expected_gt = 0;
                expected_eq = 1;
                expected_lt = 0;

                for (bit_index = 3; bit_index >= 0; bit_index = bit_index - 1) begin
                    if (expected_eq && (ai[bit_index] != bi[bit_index])) begin
                        expected_gt = ai[bit_index] > bi[bit_index];
                        expected_eq = 0;
                        expected_lt = ai[bit_index] < bi[bit_index];
                    end
                    compare_bit(ai[bit_index], bi[bit_index],
                                expected_gt, expected_eq, expected_lt);
                end
            end
        end

        $display("PASS: all 256 serial comparisons at every prefix");
        $finish;
    end
endmodule
