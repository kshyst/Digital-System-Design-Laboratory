`timescale 1ns/1ps
`default_nettype none

// Addressed-write TCAM: one row is written per clock; all rows are searched.
// At the default 16 x 16 size, the external interface uses 71 pins.
module tcam_upgraded #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH = 16
) (
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         write_enable,
    input  wire [((DEPTH > 1) ? $clog2(DEPTH) : 1)-1:0] write_address,
    input  wire [DATA_WIDTH-1:0]        write_data,
    input  wire [DATA_WIDTH-1:0]        write_x_mask,
    input  wire [DATA_WIDTH-1:0]        search_data,
    output wire [DEPTH-1:0]             match_lines
);
    generate
        if (DATA_WIDTH < 1 || DEPTH < 1) begin : invalid_parameters
            initial $fatal(1, "TCAM requires DATA_WIDTH >= 1 and DEPTH >= 1");
        end else begin : valid_parameters
            wire [DEPTH-1:0] row_write_enable;
            wire [DEPTH*DATA_WIDTH-1:0] all_write_data;
            wire [DEPTH*DATA_WIDTH-1:0] all_write_x_mask;

            // Move the enable bit to the addressed row; unused addresses write none.
            assign row_write_enable = {{(DEPTH-1){1'b0}}, write_enable}
                                    << write_address;
            // All rows receive the same inputs, but only the enabled row stores them.
            assign all_write_data = {DEPTH{write_data}};
            assign all_write_x_mask = {DEPTH{write_x_mask}};

            tcam #(
                .DATA_WIDTH(DATA_WIDTH),
                .DEPTH(DEPTH)
            ) core (
                .clk(clk),
                .reset(reset),
                .write_enable(row_write_enable),
                .write_data(all_write_data),
                .write_x_mask(all_write_x_mask),
                .search_data(search_data),
                .match_lines(match_lines)
            );
        end
    endgenerate
endmodule

`default_nettype wire
