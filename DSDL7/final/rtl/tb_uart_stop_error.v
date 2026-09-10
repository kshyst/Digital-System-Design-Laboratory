`timescale 1ns/1ps

module tb_uart_stop_error;

    localparam integer BIT_TICKS = 10;
    localparam integer TIMEOUT_CYCLES = 20 * BIT_TICKS;
    localparam [6:0] SEED_DATA = 7'b1011001;
    localparam [6:0] BAD_DATA = 7'b0101101;

    reg clk;
    reg rstN;
    reg rx;
    wire [6:0] rec_data;
    wire rec_new_data;
    wire correct_data;

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

    task hold_rx;
        input value;
        integer cycle;
        begin
            rx = value;
            for (cycle = 0; cycle < BIT_TICKS; cycle = cycle + 1)
                @(negedge clk);
        end
    endtask

    task drive_frame;
        input [6:0] data;
        input parity_bit;
        input stop_bit;
        integer bit_index;
        begin
            @(negedge clk);
            hold_rx(1'b0);
            hold_rx(parity_bit);
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
                hold_rx(data[bit_index]);
            rx = stop_bit;
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
        $dumpfile("/tmp/tb_uart_stop_error.vcd");
        $dumpvars(0, tb_uart_stop_error);
        rstN = 1'b1;
        rx = 1'b1;
        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;
        repeat (2) @(negedge clk);

        drive_frame(SEED_DATA, ^SEED_DATA, 1'b1);
        wait_completion;
        if (correct_data !== 1'b1 || rec_data !== SEED_DATA)
            $fatal(1, "FAIL: valid seed frame was not accepted");
        @(negedge clk);

        drive_frame(BAD_DATA, ^BAD_DATA, 1'b0);
        wait_completion;
        rx = 1'b1;
        if (correct_data !== 1'b0)
            $fatal(1, "FAIL: zero stop bit was accepted");
        if (rec_data !== SEED_DATA)
            $fatal(1, "FAIL: framing error changed rec_data to %b", rec_data);
        @(negedge clk);
        if (rec_new_data !== 1'b0)
            $fatal(1, "FAIL: rec_new_data exceeded one cycle");

        $display("PASS: stop-bit errors are rejected");
        $finish;
    end

endmodule
