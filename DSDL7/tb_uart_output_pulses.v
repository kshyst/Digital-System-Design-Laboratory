`timescale 1ns/1ps

module tb_uart_output_pulses;

    localparam integer BIT_TICKS = 4;
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

    reg raw_rx;
    wire [6:0] raw_rec_data;
    wire raw_rec_new_data;
    wire raw_correct_data;
    integer cycles;

    UARTTop #(.BIT_TICKS(BIT_TICKS)) loopback (
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

    UARTReceiver #(.BIT_TICKS(BIT_TICKS)) raw_receiver (
        .clk(clk),
        .rstN(rstN),
        .rx(raw_rx),
        .rec_data(raw_rec_data),
        .rec_new_data(raw_rec_new_data),
        .correct_data(raw_correct_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task hold_raw_rx;
        input value;
        integer cycle;
        begin
            raw_rx = value;
            for (cycle = 0; cycle < BIT_TICKS; cycle = cycle + 1)
                @(negedge clk);
        end
    endtask

    task drive_bad_parity_frame;
        input [6:0] data;
        integer bit_index;
        begin
            @(negedge clk);
            hold_raw_rx(1'b0);
            hold_raw_rx(~(^data));
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
                hold_raw_rx(data[bit_index]);
            hold_raw_rx(1'b1);
            raw_rx = 1'b1;
        end
    endtask

    initial begin
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'd0;
        raw_rx = 1'b1;
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
        if (rec_new_data !== 1'b1 || correct_data !== 1'b1)
            $fatal(1, "FAIL: valid completion pulse missing or misaligned");
        @(negedge clk);
        if (rec_new_data !== 1'b0 || correct_data !== 1'b0)
            $fatal(1, "FAIL: valid completion exceeded one cycle");

        drive_bad_parity_frame(TEST_DATA);
        cycles = 0;
        while (raw_rec_new_data !== 1'b1 && cycles < TIMEOUT_CYCLES) begin
            @(negedge clk);
            cycles = cycles + 1;
        end
        if (raw_rec_new_data !== 1'b1 || raw_correct_data !== 1'b0)
            $fatal(1, "FAIL: invalid completion pulse semantics");
        @(negedge clk);
        if (raw_rec_new_data !== 1'b0 || raw_correct_data !== 1'b0)
            $fatal(1, "FAIL: invalid completion exceeded one cycle");

        $display("PASS: receiver completion pulses are one cycle");
        $finish;
    end

endmodule
