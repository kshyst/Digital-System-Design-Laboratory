`timescale 1ns/1ps
`default_nettype none

// Regression test for the board-fit 16x16 top-level interface.
module tb_tcam_16x16_top;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg write_enable = 1'b0;
    reg [3:0] write_address = 4'd0;
    reg [15:0] write_data = 16'h0000;
    reg [15:0] write_x_mask = 16'h0000;
    reg [15:0] search_data = 16'h0000;
    wire [15:0] match_lines;
    integer row;

    tcam_16x16_top dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .write_x_mask(write_x_mask),
        .search_data(search_data),
        .match_lines(match_lines)
    );

    always #5 clk = ~clk;

    task write_row;
        input [3:0] address;
        input [15:0] data;
        input [15:0] x_mask;
        begin
            @(negedge clk);
            write_address = address;
            write_data = data;
            write_x_mask = x_mask;
            write_enable = 1'b1;
            @(posedge clk);
            #1 write_enable = 1'b0;
        end
    endtask

    task expect_match;
        input [15:0] key;
        input [15:0] expected;
        begin
            search_data = key;
            #1;
            if (match_lines !== expected)
                $fatal(1, "key=%h expected=%h actual=%h", key, expected, match_lines);
        end
    endtask

    initial begin
        $dumpfile("build/tb_tcam_16x16_top.vcd");
        $dumpvars(0, tb_tcam_16x16_top);

        @(posedge clk);
        #1 reset = 1'b0;

        // Program all sixteen physical rows through the four-bit address port.
        for (row = 0; row < 16; row = row + 1)
            write_row(row[3:0], 16'h1000 + row, 16'h0000);

        // Every address must have updated only its selected row.
        for (row = 0; row < 16; row = row + 1)
            expect_match(16'h1000 + row, (16'h0001 << row));

        // Rewrite row 7 with four wildcard bits and verify both match and miss.
        write_row(4'd7, 16'hA500, 16'h00F0);
        expect_match(16'hA5A0, 16'h0080);
        expect_match(16'hA4A0, 16'h0000);

        // Reset must invalidate all sixteen rows.
        reset = 1'b1;
        @(posedge clk);
        #1 reset = 1'b0;
        expect_match(16'h1000, 16'h0000);
        expect_match(16'hA5A0, 16'h0000);

        $display("PASS: board-fit top level implements full 16 x 16 TCAM");
        $finish;
    end
endmodule

`default_nettype wire
