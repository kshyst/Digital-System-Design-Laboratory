`timescale 1ns/1ps
`default_nettype none

// Checks the Experiment 9 wildcard example in both implementations.
module tb_tcam_wildcard;
    localparam integer DATA_WIDTH = 8;
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
        $dumpfile("build/tb_tcam_wildcard.vcd");
        $dumpvars(0, tb_tcam_wildcard);
        @(posedge clk);
        #1 reset = 1'b0;

        @(negedge clk);
        // Rows 0..2: 0110XXXX, X1101XXX, 0X1X11X0.
        // Row 3 stays invalid even though its input mask is all-X.
        write_data = {8'b00000000, 8'b00101100, 8'b01101000, 8'b01100000};
        write_x_mask = {8'b11111111, 8'b01010010, 8'b10000111, 8'b00001111};
        write_enable = 4'b0111;
        @(posedge clk);
        #1 write_enable = 4'b0000;

        check_search(8'b01101110, 4'b0111);
        check_search(8'b11111111, 4'b0000);

        $display("PASS: assignment wildcard example (both implementations)");
        $finish;
    end
endmodule

`default_nettype wire
