`timescale 1ns/1ps

module comparator_1bit (
    input  wire a,
    input  wire b,
    output wire gt,
    output wire eq,
    output wire lt
);
    assign gt =  a & ~b;
    assign eq = ~(a ^ b);
    assign lt = ~a &  b;
endmodule
