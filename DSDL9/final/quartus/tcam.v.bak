`timescale 1ns/1ps
`default_nettype none

// Each enabled row stores its own data and X mask on the same rising edge. Meaning multiple registers with defined
// Data width on a single store.
// Row i uses write_data[i*DATA_WIDTH +: DATA_WIDTH] with the same mask slice.
module tcam #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH = 16
) (
    input  wire                         clk,
    input  wire                         reset,
    input  wire [DEPTH-1:0]             write_enable,
    input  wire [DEPTH*DATA_WIDTH-1:0]  write_data,     // Data of all registers
    input  wire [DEPTH*DATA_WIDTH-1:0]  write_x_mask,   // X values for all registers
    input  wire [DATA_WIDTH-1:0]        search_data,    // Data we comparing with
    output wire [DEPTH-1:0]             match_lines     // Registers matched
);
    genvar row;

    generate
        if (DATA_WIDTH < 1 || DEPTH < 1) begin : invalid_parameters
            initial $fatal(1, "TCAM requires DATA_WIDTH >= 1 and DEPTH >= 1");
        end else begin : valid_parameters
            for (row = 0; row < DEPTH; row = row + 1) begin : entries
                tcam_entry #(.DATA_WIDTH(DATA_WIDTH)) entry (
                    .clk(clk),
                    .reset(reset),
                    .write_enable(write_enable[row]),
                    .write_data(write_data[row*DATA_WIDTH +: DATA_WIDTH]),
                    .write_x_mask(write_x_mask[row*DATA_WIDTH +: DATA_WIDTH]),
                    .search_data(search_data),
                    .match(match_lines[row])
                );
            end
        end
    endgenerate
endmodule

`default_nettype wire
