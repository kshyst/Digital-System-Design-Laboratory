`timescale 1ns/1ps

module tb_uart_false_start;

    localparam integer BIT_TICKS = 10;
    localparam integer TIMEOUT_CYCLES = 20 * BIT_TICKS;
    localparam [6:0] TEST_DATA = 7'b1011001;

    reg clk;
    reg rstN;
    reg rx;
    wire [6:0] rec_data;
    wire rec_new_data;
    wire correct_data;
    integer completion_count;

    UARTReceiver #(.BIT_TICKS(BIT_TICKS)) dut (
        .clk(clk),
        .rstN(rstN),
        .rx(rx),
        .rec_data(rec_data),
        .rec_new_data(rec_new_data),
        .correct_data(correct_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    always @(negedge clk) begin
        if (rec_new_data)
            completion_count = completion_count + 1;
    end

    task hold_rx;
        input value;
        integer cycle;
        begin
            rx = value;
            for (cycle = 0; cycle < BIT_TICKS; cycle = cycle + 1)
                @(negedge clk);
        end
    endtask

    task drive_valid_frame;
        input [6:0] data;
        integer bit_index;
        begin
            @(negedge clk);
            hold_rx(1'b0);
            hold_rx(^data);
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
                hold_rx(data[bit_index]);
            rx = 1'b1;
        end
    endtask

    task wait_completion;
        integer cycles;
        begin
            cycles = 0;
            while (rec_new_data !== 1'b1 && cycles < TIMEOUT_CYCLES) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (rec_new_data !== 1'b1)
                $fatal(1, "FAIL: receiver completion timeout");
        end
    endtask

    initial begin
        $dumpfile("/tmp/tb_uart_false_start.vcd");
        $dumpvars(0, tb_uart_false_start);
        completion_count = 0;
        rstN = 1'b1;
        rx = 1'b1;
        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;
        repeat (2) @(negedge clk);

        @(negedge clk);
        rx = 1'b0;
        @(negedge clk);
        rx = 1'b1;
        repeat (3 * BIT_TICKS) @(negedge clk);
        if (completion_count != 0)
            $fatal(1, "FAIL: false start produced a completed frame");

        drive_valid_frame(TEST_DATA);
        wait_completion;
        if (correct_data !== 1'b1 || rec_data !== TEST_DATA)
            $fatal(1, "FAIL: receiver did not recover after false start");
        @(negedge clk);
        if (completion_count != 1)
            $fatal(1, "FAIL: expected one completion, observed %0d",
                   completion_count);

        $display("PASS: false starts are rejected");
        $finish;
    end

endmodule
