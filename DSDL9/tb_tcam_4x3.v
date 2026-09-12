`timescale 1ns/1ps
`default_nettype none

// 4 x 3 exact and independent wildcard masks
module tb_tcam_4x3;
    localparam integer DATA_WIDTH = 3;
    localparam integer DEPTH = 4;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg [DEPTH-1:0] write_enable = 0;
    reg [DEPTH*DATA_WIDTH-1:0] write_data = 0;
    reg [DEPTH*DATA_WIDTH-1:0] write_x_mask = 0;
    reg [DATA_WIDTH-1:0] search_data = 0;
    wire [DEPTH-1:0] match_loop;
    wire [DEPTH-1:0] match_no_loop;

    tcam #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) loop (
        .clk(clk), .reset(reset), .write_enable(write_enable),
        .write_data(write_data), .write_x_mask(write_x_mask),
        .search_data(search_data), .match_lines(match_loop)
    );
    tcam_no_loop #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) no_loop (
        .clk(clk), .reset(reset), .write_enable(write_enable),
        .write_data(write_data), .write_x_mask(write_x_mask),
        .search_data(search_data), .match_lines(match_no_loop)
    );

    always #5 clk = ~clk;

    task check_search;
        input [DATA_WIDTH-1:0] data;
        input [DEPTH-1:0] expected;
        begin
            search_data = data;
            #1;
            if (match_loop !== expected || match_no_loop !== expected)
                $fatal(1, "Search %h: expected %h, loop %h, no-loop %h",
                       data, expected, match_loop, match_no_loop);
            #9; // Keep each result visible in GTKWave.
        end
    endtask

    initial begin
        $dumpfile("build/tb_tcam_4x3.vcd");
        $dumpvars(0, tb_tcam_4x3);
        @(posedge clk);
        #1 reset = 1'b0;

        @(negedge clk);
        // Rows 3..0 contain 111, 10X, X10, 001.
        write_data = {3'b111, 3'b100, 3'b010, 3'b001};
        write_x_mask = {3'b000, 3'b001, 3'b100, 3'b000};
        write_enable = 4'b1111;
        @(posedge clk);
        #1 write_enable = 4'b0000;

        // Exhaust every possible 3-bit search key.
        check_search(3'b000, 4'b0000);
        check_search(3'b001, 4'b0001);
        check_search(3'b010, 4'b0010);
        check_search(3'b011, 4'b0000);
        check_search(3'b100, 4'b0100);
        check_search(3'b101, 4'b0100);
        check_search(3'b110, 4'b0010);
        check_search(3'b111, 4'b1000);

        $display("PASS: 4 x 3 exact and independent wildcard masks (both implementations)");
        $finish;
    end
endmodule

`default_nettype wire
