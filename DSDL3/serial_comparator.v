`timescale 1ns/1ps

module serial_comparator (
    input  wire clk,
    input  wire reset,
    input  wire a,
    input  wire b,
    output wire gt,
    output wire eq,
    output wire lt
);
    wire [1:0] state;
    wire [1:0] master;
    wire [1:0] next_state;

    assign next_state[1] = state[1] | (~state[1] & ~state[0] &  a & ~b);
    assign next_state[0] = state[0] | (~state[1] & ~state[0] & ~a &  b);

    assign master = reset ? 2'b00 : (~clk ? next_state : master);
    assign state  = reset ? 2'b00 : ( clk ? master     : state);

    assign gt =  state[1];
    assign eq = ~state[1] & ~state[0];
    assign lt =  state[0];
endmodule
