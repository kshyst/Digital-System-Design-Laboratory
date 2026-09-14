`timescale 1ns/1ps
`default_nettype none

// Full-size TCAM: independent masks across all 16 bits and selective writes.
// Catches truncated/reordered data or masks, ignored masks, and ignored enables.
module tb_tcam_16x16;
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
    integer checks = 0;

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
            checks = checks + 1;
            #9; // Keep each result visible in GTKWave.
        end
    endtask

    task check_entry;
        input [15:0] exact_key;
        input [15:0] masked_key;
        input [15:0] different_key;
        input [15:0] expected;
        begin
            check_search(exact_key, expected);
            check_search(masked_key, expected);
            check_search(different_key, 16'h0000);
        end
    endtask

    initial begin
        $dumpfile("build/tb_tcam_16x16.vcd");
        $dumpvars(0, tb_tcam_16x16);
        @(posedge clk);
        #1 reset = 1'b0;

        @(negedge clk);
        // Row 0 is the rightmost word. Each row ignores a different bit.
        write_data = {16'hFFFF, 16'hEEEE, 16'hDDDD, 16'hCCCC,
                      16'hBBBB, 16'hAAAA, 16'h9999, 16'h8888,
                      16'h7777, 16'h6666, 16'h5555, 16'h4444,
                      16'h3333, 16'h2222, 16'h1111, 16'h0000};
        write_x_mask = {16'h8000, 16'h4000, 16'h2000, 16'h1000,
                        16'h0800, 16'h0400, 16'h0200, 16'h0100,
                        16'h0080, 16'h0040, 16'h0020, 16'h0010,
                        16'h0008, 16'h0004, 16'h0002, 16'h0001};
        write_enable = 16'hFFFF;
        search_data = 16'h0001;
        #1;
        if (match_loop !== 16'h0000 || match_no_loop !== 16'h0000)
            $fatal(1, "An initial write took effect before the rising edge");
        @(posedge clk);
        #1 write_enable = 16'h0000;

        // Literal keys: exact, changed masked bit, changed unmasked bit.
        check_entry(16'h0000, 16'h0001, 16'h0002, 16'h0001);
        check_entry(16'h1111, 16'h1113, 16'h1115, 16'h0002);
        check_entry(16'h2222, 16'h2226, 16'h222A, 16'h0004);
        check_entry(16'h3333, 16'h333B, 16'h3323, 16'h0008);
        check_entry(16'h4444, 16'h4454, 16'h4464, 16'h0010);
        check_entry(16'h5555, 16'h5575, 16'h5515, 16'h0020);
        check_entry(16'h6666, 16'h6626, 16'h66E6, 16'h0040);
        check_entry(16'h7777, 16'h77F7, 16'h7677, 16'h0080);
        check_entry(16'h8888, 16'h8988, 16'h8A88, 16'h0100);
        check_entry(16'h9999, 16'h9B99, 16'h9D99, 16'h0200);
        check_entry(16'hAAAA, 16'hAEAA, 16'hA2AA, 16'h0400);
        check_entry(16'hBBBB, 16'hB3BB, 16'hABBB, 16'h0800);
        check_entry(16'hCCCC, 16'hDCCC, 16'hECCC, 16'h1000);
        check_entry(16'hDDDD, 16'hFDDD, 16'h9DDD, 16'h2000);
        check_entry(16'hEEEE, 16'hAEEE, 16'h6EEE, 16'h4000);
        check_entry(16'hFFFF, 16'h7FFF, 16'hFFFE, 16'h8000);

        @(negedge clk);
        // Change every input lane, but enable only rows 1, 8, and 15.
        write_data = {256{1'b1}};
        write_x_mask = {256{1'b1}};
        write_data[1*DATA_WIDTH +: DATA_WIDTH] = 16'hA50A;
        write_x_mask[1*DATA_WIDTH +: DATA_WIDTH] = 16'h00F0;
        write_data[8*DATA_WIDTH +: DATA_WIDTH] = 16'hA50A;
        write_x_mask[8*DATA_WIDTH +: DATA_WIDTH] = 16'h0F00;
        write_data[15*DATA_WIDTH +: DATA_WIDTH] = 16'h0000;
        write_enable = 16'h8102;
        #1;
        if (match_loop !== 16'h0000 || match_no_loop !== 16'h0000)
            $fatal(1, "A selective write took effect before the rising edge");
        @(posedge clk);
        #1 write_enable = 16'h0000;

        // Rows 1 and 8 overlap; row 15 is an all-X entry.
        check_search(16'hA50A, 16'h8102);
        check_search(16'hA5FA, 16'h8002);
        check_search(16'hAF0A, 16'h8100);
        check_search(16'hA5FB, 16'h8000);
        check_search(16'h1111, 16'h8000); // Old row 1 data no longer matches.
        check_search(16'h8888, 16'h8000); // Old row 8 data no longer matches.
        check_search(16'hFFFF, 16'h8000);

        // All 13 disabled rows must retain their original data AND masks.
        check_search(16'h0001, 16'h8001); // Row 0 and all-X row 15.
        check_search(16'h2226, 16'h8004); // Row 2 and all-X row 15.
        check_search(16'h333B, 16'h8008); // Row 3 and all-X row 15.
        check_search(16'h4454, 16'h8010); // Row 4 and all-X row 15.
        check_search(16'h5575, 16'h8020); // Row 5 and all-X row 15.
        check_search(16'h6626, 16'h8040); // Row 6 and all-X row 15.
        check_search(16'h77F7, 16'h8080); // Row 7 and all-X row 15.
        check_search(16'h9B99, 16'h8200); // Row 9 and all-X row 15.
        check_search(16'hAEAA, 16'h8400); // Row 10 and all-X row 15.
        check_search(16'hB3BB, 16'h8800); // Row 11 and all-X row 15.
        check_search(16'hDCCC, 16'h9000); // Row 12 and all-X row 15.
        check_search(16'hFDDD, 16'hA000); // Row 13 and all-X row 15.
        check_search(16'hAEEE, 16'hC000); // Row 14 and all-X row 15.

        @(negedge clk);
        write_data = 0;
        write_x_mask = 0;
        @(posedge clk);
        #1;
        check_search(16'hA50A, 16'h8102);
        check_search(16'h0001, 16'h8001);
        check_search(16'h77F7, 16'h8080);
        check_search(16'hAEEE, 16'hC000);

        $display("PASS: 16 x 16 independent masks and selective writes (%0d searches, both implementations)", checks);
        $finish;
    end
endmodule

`default_nettype wire
