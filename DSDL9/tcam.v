`timescale 1ns/1ps
`default_nettype none

// Parameterized ternary content-addressable memory.
// The defaults implement the required 16 entries of 16 ternary bits each.
module tcam #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH = 16,
    parameter integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
) (
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  write_enable,
    input  wire [ADDR_WIDTH-1:0] write_address,
    input  wire [DATA_WIDTH-1:0] write_data,
    input  wire [DATA_WIDTH-1:0] write_x_mask,
    input  wire [DATA_WIDTH-1:0] search_data,
    output wire [DEPTH-1:0]      match_lines
);
    genvar entry_index;

    generate
        for (entry_index = 0; entry_index < DEPTH; entry_index = entry_index + 1) begin : entries
            localparam [ADDR_WIDTH-1:0] ENTRY_ADDRESS = entry_index;

            tcam_entry #(
                .DATA_WIDTH(DATA_WIDTH)
            ) entry (
                .clk(clk),
                .reset(reset),
                .write_enable(write_enable && (write_address == ENTRY_ADDRESS)),
                .write_data(write_data),
                .write_x_mask(write_x_mask),
                .search_data(search_data),
                .match(match_lines[entry_index])
            );
        end
    endgenerate
endmodule

`default_nettype wire
