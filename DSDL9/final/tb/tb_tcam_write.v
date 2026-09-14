`timescale 1ns/1ps
`default_nettype none

// 16 distinct entries written on one clock edge
module tb_tcam_write;
    localparam integer DATA_WIDTH = 16;
    localparam integer DEPTH = 16;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg [DEPTH-1:0] write_enable = 0;
    reg [DEPTH*DATA_WIDTH-1:0] write_data = 0;
    reg [DEPTH*DATA_WIDTH-1:0] write_x_mask = 0;
    reg [DATA_WIDTH-1:0] search_data = 0;
    wire [DEPTH-1:0] match_loop;
    wire [DEPTH-1:0] match_no_loop;
    integer row;
    reg [DEPTH-1:0] expected;

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
        $dumpfile("build/tb_tcam_write.vcd");
        $dumpvars(0, tb_tcam_write);
        @(posedge clk);
        #1 reset = 1'b0;

        @(negedge clk);
        // Row 0 is the rightmost (least-significant) word.
        write_data = {16'h0010, 16'h000F, 16'h000E, 16'h000D,
                      16'h000C, 16'h000B, 16'h000A, 16'h0009,
                      16'h0008, 16'h0007, 16'h0006, 16'h0005,
                      16'h0004, 16'h0003, 16'h0002, 16'h0001};
        write_enable = 16'hFFFF;
        search_data = 16'h0001;
        #1;
        if (match_loop !== 16'h0000 || match_no_loop !== 16'h0000)
            $fatal(1, "A row changed before the rising clock edge");
        @(posedge clk);
        #1 write_enable = 16'h0000;

        for (row = 0; row < DEPTH; row = row + 1) begin
            expected = 16'h0000;
            expected[row] = 1'b1;
            check_search(row + 1, expected);
        end
        check_search(16'h0000, 16'h0000);

        $display("PASS: 16 distinct entries written on one clock edge (both implementations)");
        $finish;
    end
endmodule

`default_nettype wire
