`timescale 1ns/1ps
`default_nettype none

// Board-fit top level for the required 16-row by 16-bit TCAM.
//
// The original tcam module exposes the data and mask of all sixteen rows at
// once. At 16 x 16 that creates 562 top-level pins, so Quartus cannot place it
// on the laboratory FPGA package. This wrapper keeps the full internal TCAM
// but writes one addressed row per clock, reducing the external interface to
// 71 pins.
module tcam_16x16_top (
    input  wire        clk,
    input  wire        reset,
    input  wire        write_enable,
    input  wire [3:0]  write_address,
    input  wire [15:0] write_data,
    input  wire [15:0] write_x_mask,
    input  wire [15:0] search_data,
    output wire [15:0] match_lines
);
    wire [15:0]  row_write_enable;
    wire [255:0] all_write_data;
    wire [255:0] all_write_x_mask;

    // Convert the addressed write into the one-enable-per-row interface used
    // by the existing TCAM core. Data and mask are replicated; only the row
    // whose enable bit is high captures them on the rising clock edge.
    assign row_write_enable = write_enable
                            ? (16'h0001 << write_address)
                            : 16'h0000;
    assign all_write_data = {16{write_data}};
    assign all_write_x_mask = {16{write_x_mask}};

    tcam #(
        .DATA_WIDTH(16),
        .DEPTH(16)
    ) core (
        .clk(clk),
        .reset(reset),
        .write_enable(row_write_enable),
        .write_data(all_write_data),
        .write_x_mask(all_write_x_mask),
        .search_data(search_data),
        .match_lines(match_lines)
    );
endmodule

`default_nettype wire
