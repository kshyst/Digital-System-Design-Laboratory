`timescale 1ns/1ps

module tb_comparator_4bit;
    reg  [3:0] a;
    reg  [3:0] b;
    wire       gt;
    wire       eq;
    wire       lt;
    integer    ai;
    integer    bi;

    comparator_4bit dut(a, b, gt, eq, lt);

    initial begin
        for (ai = 0; ai < 16; ai = ai + 1) begin
            for (bi = 0; bi < 16; bi = bi + 1) begin
                a = ai;
                b = bi;
                #1;
                if ((gt !== (ai > bi)) ||
                    (eq !== (ai == bi)) ||
                    (lt !== (ai < bi))) begin
                    $display("FAIL: a=%0d b=%0d gt=%b eq=%b lt=%b",
                             ai, bi, gt, eq, lt);
                    $finish;
                end
            end
        end

        $display("PASS: all 256 four-bit comparisons");
        $finish;
    end
endmodule
