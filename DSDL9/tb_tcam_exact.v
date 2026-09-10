`timescale 1ns/1ps
`default_nettype none

// Checks ordinary CAM behavior when no stored bit is marked as X.
module tb_tcam_exact;
    localparam integer DATA_WIDTH = 16;
    localparam integer DEPTH = 16;
    localparam integer ADDR_WIDTH = 4;

    reg clk;
    reg reset;
    reg write_enable;
    reg [ADDR_WIDTH-1:0] write_address;
    reg [DATA_WIDTH-1:0] write_data;
    reg [DATA_WIDTH-1:0] write_x_mask;
    reg [DATA_WIDTH-1:0] search_data;
    wire [DEPTH-1:0] match_lines;

    tcam dut (
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
        $dumpfile("tb_tcam_exact.vcd");
        $dumpvars(0, tb_tcam_exact);
    end

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

        // Store an exact value in the last entry.
        write_address = 4'd15;
        write_data = 16'hA55A;
        write_x_mask = 16'h0000;
        write_enable = 1'b1;
        @(posedge clk);
        #1 write_enable = 1'b0;

        search_data = 16'hA55A;
        #1;
        if (match_lines !== 16'h8000)
            $fatal(1, "Exact value did not select only entry 15: %h", match_lines);

        search_data = 16'hA55B;
        #1;
        if (match_lines !== 16'h0000)
            $fatal(1, "Different value incorrectly matched: %h", match_lines);

        $display("PASS: exact TCAM matching");
        $finish;
    end
endmodule

`default_nettype wire
