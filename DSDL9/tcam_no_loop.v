`timescale 1ns/1ps
`default_nettype none

// Parallel-write TCAM with an instance array and no for loop.
// The packed data/mask buses are split across entries; search_data is shared.
module tcam_no_loop #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH = 16
) (
    input  wire                         clk,
    input  wire                         reset,
    input  wire [DEPTH-1:0]             write_enable,
    input  wire [DEPTH*DATA_WIDTH-1:0]  write_data,
    input  wire [DEPTH*DATA_WIDTH-1:0]  write_x_mask,
    input  wire [DATA_WIDTH-1:0]        search_data,
    output wire [DEPTH-1:0]             match_lines
);
    generate
        if (DATA_WIDTH < 1 || DEPTH < 1) begin : invalid_parameters
            initial $fatal(1, "TCAM requires DATA_WIDTH >= 1 and DEPTH >= 1");
        end else begin : valid_parameters
            tcam_entry #(.DATA_WIDTH(DATA_WIDTH)) entries [DEPTH-1:0] (
                .clk(clk),
                .reset(reset),
                .write_enable(write_enable),
                .write_data(write_data),
                .write_x_mask(write_x_mask),
                .search_data(search_data),
                .match(match_lines)
            );
        end
    endgenerate
endmodule

`default_nettype wire
