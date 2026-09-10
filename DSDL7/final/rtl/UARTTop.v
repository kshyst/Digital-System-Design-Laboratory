`timescale 1ns/1ps

// Direct internal loopback: the sender's serial output is the receiver input.
module UARTTop #(
    parameter integer BIT_TICKS = 434
) (
    input  wire       clk,
    input  wire       rstN,
    input  wire       new_data,
    input  wire [6:0] send_data,
    output wire       tx,
    output wire       busy,
    output wire [6:0] rec_data,
    output wire       rec_new_data,
    output wire       correct_data
);

    UARTSender #(.BIT_TICKS(BIT_TICKS)) sender (
        .clk(clk),
        .rstN(rstN),
        .new_data(new_data),
        .send_data(send_data),
        .tx(tx),
        .busy(busy)
    );

    UARTReceiver #(.BIT_TICKS(BIT_TICKS)) receiver (
        .clk(clk),
        .rstN(rstN),
        .rx(tx),
        .rec_data(rec_data),
        .rec_new_data(rec_new_data),
        .correct_data(correct_data)
    );

endmodule
