`timescale 1ns/1ps
`default_nettype none

// Expected failure: the DUT must reject zero/negative dimensions at time zero.
// Default case: one entry, zero data bits. Run NO_LOOP=0 and NO_LOOP=1.
module tb_tcam_invalid;
    parameter integer DATA_WIDTH = 0;
    parameter integer DEPTH = 1;
    parameter integer NO_LOOP = 0;

    generate
        if (NO_LOOP) begin : test_no_loop
            tcam_no_loop #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
                .clk(1'b0), .reset(1'b1), .write_enable('0),
                .write_data('0), .write_x_mask('0),
                .search_data('0), .match_lines()
            );
        end else begin : test_loop
            tcam #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
                .clk(1'b0), .reset(1'b1), .write_enable('0),
                .write_data('0), .write_x_mask('0),
                .search_data('0), .match_lines()
            );
        end
    endgenerate

    initial begin
        #1;
        $fatal(1, "FAIL: invalid dimensions were accepted");
    end
endmodule

`default_nettype wire
