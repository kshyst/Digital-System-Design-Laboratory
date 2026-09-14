`timescale 1ns/1ps
`default_nettype none

// 1 x 1 minimum size and synchronous reset priority
module tb_tcam_1x1;
    localparam integer DATA_WIDTH = 1;
    localparam integer DEPTH = 1;
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
        $dumpfile("build/tb_tcam_1x1.vcd");
        $dumpvars(0, tb_tcam_1x1);
        @(posedge clk);
        #1 reset = 1'b0;

        check_search(1'b0, 1'b0);
        check_search(1'b1, 1'b0);
        @(negedge clk);
        write_data = 1'b1;
        write_enable = 1'b1;
        @(posedge clk);
        #1 write_enable = 1'b0;
        check_search(1'b1, 1'b1);
        check_search(1'b0, 1'b0);

        @(negedge clk);
        write_data = 1'b0;
        write_x_mask = 1'b1;
        write_enable = 1'b1;
        @(posedge clk);
        #1 write_enable = 1'b0;
        check_search(1'b0, 1'b1);
        check_search(1'b1, 1'b1);

        @(negedge clk);
        reset = 1'b1;
        write_enable = 1'b1;
        #1;
        if (match_loop !== 1'b1 || match_no_loop !== 1'b1)
            $fatal(1, "Reset acted before the rising clock edge");
        @(posedge clk);
        #1;
        reset = 1'b0;
        write_enable = 1'b0;
        check_search(1'b0, 1'b0);
        check_search(1'b1, 1'b0);

        $display("PASS: 1 x 1 minimum size and synchronous reset priority (both implementations)");
        $finish;
    end
endmodule

`default_nettype wire
