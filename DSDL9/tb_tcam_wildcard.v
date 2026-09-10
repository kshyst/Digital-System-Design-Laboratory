`timescale 1ns/1ps
`default_nettype none

// Checks the three wildcard patterns given in the Experiment 9 PDF.
module tb_tcam_wildcard;
    localparam integer DATA_WIDTH = 8;
    localparam integer DEPTH = 4;
    localparam integer ADDR_WIDTH = 2;

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
        $dumpfile("tb_tcam_wildcard.vcd");
        $dumpvars(0, tb_tcam_wildcard);
    end

    task write_entry;
        input [ADDR_WIDTH-1:0] address;
        input [DATA_WIDTH-1:0] data;
        input [DATA_WIDTH-1:0] x_mask;
        begin
            write_address = address;
            write_data = data;
            write_x_mask = x_mask;
            write_enable = 1'b1;
            @(posedge clk);
            #1 write_enable = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        write_enable = 1'b0;
        write_address = {ADDR_WIDTH{1'b0}};
        write_data = {DATA_WIDTH{1'b0}};
        write_x_mask = {DATA_WIDTH{1'b0}};
        search_data = {DATA_WIDTH{1'b0}};

        @(posedge clk);
        #1 reset = 1'b0;

        // A 1 in write_x_mask represents X at the same bit position.
        write_entry(2'd0, 8'b01100000, 8'b00001111); // 0110XXXX
        write_entry(2'd1, 8'b01101000, 8'b10000111); // X1101XXX
        write_entry(2'd2, 8'b00101100, 8'b01010010); // 0X1X11X0

        search_data = 8'b01101110;
        #1;
        if (match_lines !== 4'b0111)
            $fatal(1, "PDF example did not match all three entries: %b", match_lines);

        search_data = 8'b11111111;
        #1;
        if (match_lines !== 4'b0000)
            $fatal(1, "Compared bits were incorrectly ignored: %b", match_lines);

        $display("PASS: ternary wildcard matching");
        $finish;
    end
endmodule

`default_nettype wire
