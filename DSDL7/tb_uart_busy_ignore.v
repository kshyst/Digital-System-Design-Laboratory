`timescale 1ns/1ps

module tb_uart_busy_ignore;

    localparam integer BIT_TICKS = 4;
    localparam integer TIMEOUT_CYCLES = 30 * BIT_TICKS;
    localparam [6:0] ACCEPTED_DATA = 7'b1011001;
    localparam [6:0] IGNORED_DATA = 7'b0101101;

    reg clk;
    reg rstN;
    reg new_data;
    reg [6:0] send_data;
    wire tx;
    wire busy;
    wire [6:0] rec_data;
    wire rec_new_data;
    wire correct_data;
    integer completion_count;
    integer cycles;
    reg [6:0] observed_data;
    reg observed_correct;

    UARTTop #(.BIT_TICKS(BIT_TICKS)) dut (
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

    always @(negedge clk) begin
        if (rec_new_data) begin
            completion_count = completion_count + 1;
            observed_data = rec_data;
            observed_correct = correct_data;
        end
    end

    initial begin
        completion_count = 0;
        observed_data = 7'd0;
        observed_correct = 1'b0;
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'd0;
        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;

        @(negedge clk);
        send_data = ACCEPTED_DATA;
        new_data = 1'b1;
        @(negedge clk);
        new_data = 1'b0;
        if (busy !== 1'b1)
            $fatal(1, "FAIL: sender did not become busy");

        repeat (2 * BIT_TICKS) @(negedge clk);
        if (busy !== 1'b1)
            $fatal(1, "FAIL: sender ended before busy-request test");
        send_data = IGNORED_DATA;
        new_data = 1'b1;
        @(negedge clk);
        new_data = 1'b0;

        cycles = 0;
        while (completion_count < 1 && cycles < TIMEOUT_CYCLES) begin
            @(negedge clk);
            cycles = cycles + 1;
        end
        if (completion_count != 1 || !observed_correct ||
            observed_data !== ACCEPTED_DATA)
            $fatal(1, "FAIL: busy request changed result to %b correct=%b",
                   observed_data, observed_correct);

        repeat (12 * BIT_TICKS) @(negedge clk);
        if (completion_count != 1)
            $fatal(1, "FAIL: busy request was queued as another frame");

        $display("PASS: busy requests are ignored");
        $finish;
    end

endmodule
