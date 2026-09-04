`timescale 1ns/1ps
`default_nettype none

// Checks that reset invalidates stored entries so empty TCAM rows never match.
module tb_tcam_reset;
    localparam integer DATA_WIDTH = 4;
    localparam integer DEPTH = 2;
    localparam integer ADDR_WIDTH = 1;

    reg clk;
    reg reset;
    reg write_enable;
    reg [ADDR_WIDTH-1:0] write_address;
    reg [DATA_WIDTH-1:0] write_data;
    reg [DATA_WIDTH-1:0] write_x_mask;
    reg [DATA_WIDTH-1:0] search_data;
    wire [DEPTH-1:0] match_lines;

    tcam #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
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

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        write_enable = 1'b0;
        write_address = {ADDR_WIDTH{1'b0}};
        write_data = {DATA_WIDTH{1'b0}};
        write_x_mask = {DATA_WIDTH{1'b0}};
        search_data = 4'b1010;

        @(posedge clk);
        #1 reset = 1'b0;

        write_data = 4'b1010;
        write_enable = 1'b1;
        @(posedge clk);
        #1 write_enable = 1'b0;

        if (match_lines !== 2'b01)
            $fatal(1, "Test setup failed to create a valid match: %b", match_lines);

        reset = 1'b1;
        @(posedge clk);
        #1 reset = 1'b0;

        if (match_lines !== 2'b00)
            $fatal(1, "Reset left a TCAM entry valid: %b", match_lines);

        $display("PASS: reset invalidates TCAM entries");
        $finish;
    end
endmodule

`default_nettype wire
