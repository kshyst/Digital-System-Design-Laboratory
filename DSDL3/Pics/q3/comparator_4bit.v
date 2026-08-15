`timescale 1ns/1ps

module comparator_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire       gt,
    output wire       eq,
    output wire       lt
);
    wire [3:0] bit_gt;
    wire [3:0] bit_eq;
    wire [3:0] bit_lt;

    comparator_1bit c3(a[3], b[3], bit_gt[3], bit_eq[3], bit_lt[3]);
    comparator_1bit c2(a[2], b[2], bit_gt[2], bit_eq[2], bit_lt[2]);
    comparator_1bit c1(a[1], b[1], bit_gt[1], bit_eq[1], bit_lt[1]);
    comparator_1bit c0(a[0], b[0], bit_gt[0], bit_eq[0], bit_lt[0]);

    assign gt = bit_gt[3]
              | (bit_eq[3] & bit_gt[2])
              | (bit_eq[3] & bit_eq[2] & bit_gt[1])
              | (bit_eq[3] & bit_eq[2] & bit_eq[1] & bit_gt[0]);
    assign eq = &bit_eq;
    assign lt = bit_lt[3]
              | (bit_eq[3] & bit_lt[2])
              | (bit_eq[3] & bit_eq[2] & bit_lt[1])
              | (bit_eq[3] & bit_eq[2] & bit_eq[1] & bit_lt[0]);
endmodule
