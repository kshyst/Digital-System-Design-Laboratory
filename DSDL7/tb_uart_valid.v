`timescale 1ns/1ps

module tb_uart_valid;

    localparam integer BIT_TICKS = 434;
    localparam integer TIMEOUT_CYCLES = 20 * BIT_TICKS;
    localparam [6:0] TEST_DATA = 7'b1011001;

    reg clk;
    reg rstN;
    reg new_data;
    reg [6:0] send_data;
    wire tx;
    wire busy;
    wire [6:0] rec_data;
    wire rec_new_data;
    wire correct_data;
    integer cycles;

    UARTTop dut (
        .clk(clk),
        .rstN(rstN),
        .new_data(new_data),
        .send_data(send_data),
        .tx(tx),
        .busy(busy),
        .rec_data(rec_data),
        .rec_new_data(rec_new_data),
        .correct_data(correct_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'd0;
        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;

        @(negedge clk);
        send_data = TEST_DATA;
        new_data = 1'b1;
        @(negedge clk);
        new_data = 1'b0;

        cycles = 0;
        while (rec_new_data !== 1'b1 && cycles < TIMEOUT_CYCLES) begin
            @(negedge clk);
            cycles = cycles + 1;
        end
        if (rec_new_data !== 1'b1)
            $fatal(1, "FAIL: valid loopback timed out");
        if (rec_data !== TEST_DATA || correct_data !== 1'b1)
            $fatal(1, "FAIL: sent=%b received=%b correct=%b",
                   TEST_DATA, rec_data, correct_data);

        @(negedge clk);
        if (rec_new_data !== 1'b0 || correct_data !== 1'b0)
            $fatal(1, "FAIL: completion outputs exceeded one cycle");

        $display("PASS: valid UART loopback");
        $finish;
    end

endmodule
