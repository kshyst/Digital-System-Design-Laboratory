`timescale 1ns/1ps

// Complete Experiment 7 regression. The loopback instance checks sender/top
// behavior; the standalone receiver accepts deliberately malformed raw frames.
module Tester;

    localparam integer BIT_TICKS = 2;
    localparam integer TIMEOUT_CYCLES = 40 * BIT_TICKS;
    localparam [6:0] FIRST_DATA = 7'b1011001;
    localparam [6:0] SECOND_DATA = 7'b0101101;

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

    integer top_completion_count;
    integer raw_completion_count;
    reg [6:0] top_data_history [0:255];
    reg top_correct_history [0:255];
    reg [6:0] raw_data_history [0:15];
    reg raw_correct_history [0:15];
    reg previous_top_new;
    reg previous_raw_new;
    integer base_count;
    integer value;

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

    // Record every completion and enforce the one-cycle output contract.
    always @(negedge clk or negedge rstN) begin
        if (!rstN) begin
            top_completion_count = 0;
            raw_completion_count = 0;
            previous_top_new = 1'b0;
            previous_raw_new = 1'b0;
        end else begin
            if (rec_new_data && previous_top_new)
                $fatal(1, "FAIL: loopback rec_new_data exceeded one cycle");
            if (raw_rec_new_data && previous_raw_new)
                $fatal(1, "FAIL: raw rec_new_data exceeded one cycle");
            if (correct_data && !rec_new_data)
                $fatal(1, "FAIL: loopback correct_data is not completion-aligned");
            if (raw_correct_data && !raw_rec_new_data)
                $fatal(1, "FAIL: raw correct_data is not completion-aligned");

            if (rec_new_data) begin
                top_data_history[top_completion_count] = rec_data;
                top_correct_history[top_completion_count] = correct_data;
                top_completion_count = top_completion_count + 1;
            end
            if (raw_rec_new_data) begin
                raw_data_history[raw_completion_count] = raw_rec_data;
                raw_correct_history[raw_completion_count] = raw_correct_data;
                raw_completion_count = raw_completion_count + 1;
            end

            previous_top_new = rec_new_data;
            previous_raw_new = raw_rec_new_data;
        end
    end

    task wait_top_count;
        input integer target;
        integer cycles;
        begin
            cycles = 0;
            while (top_completion_count < target && cycles < TIMEOUT_CYCLES) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (top_completion_count < target)
                $fatal(1, "FAIL: loopback completion timeout at count %0d",
                       target);
        end
    endtask

    task wait_raw_count;
        input integer target;
        integer cycles;
        begin
            cycles = 0;
            while (raw_completion_count < target && cycles < TIMEOUT_CYCLES) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (raw_completion_count < target)
                $fatal(1, "FAIL: raw receiver completion timeout at count %0d",
                       target);
        end
    endtask

    task check_top_result;
        input integer index;
        input [6:0] expected_data;
        begin
            if (top_correct_history[index] !== 1'b1 ||
                top_data_history[index] !== expected_data)
                $fatal(1, "FAIL: loopback[%0d] expected=%b got=%b correct=%b",
                       index, expected_data, top_data_history[index],
                       top_correct_history[index]);
        end
    endtask

    task pulse_request;
        input [6:0] data;
        begin
            @(negedge clk);
            send_data = data;
            new_data = 1'b1;
            @(negedge clk);
            new_data = 1'b0;
        end
    endtask

    task check_symbol;
        input expected_tx;
        integer cycle;
        begin
            for (cycle = 0; cycle < BIT_TICKS; cycle = cycle + 1) begin
                if (tx !== expected_tx || busy !== 1'b1)
                    $fatal(1, "FAIL: frame symbol=%b cycle=%0d tx=%b busy=%b",
                           expected_tx, cycle, tx, busy);
                @(negedge clk);
            end
        end
    endtask

    task send_and_check_frame;
        input [6:0] data;
        integer bit_index;
        begin
            @(negedge clk);
            send_data = data;
            new_data = 1'b1;
            @(negedge clk);
            new_data = 1'b0;

            check_symbol(1'b0);
            check_symbol(^data);
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
                check_symbol(data[bit_index]);
            check_symbol(1'b1);

            if (tx !== 1'b1 || busy !== 1'b0)
                $fatal(1, "FAIL: sender did not return to idle after frame");
        end
    endtask

    task hold_raw_rx;
        input level;
        integer cycle;
        begin
            raw_rx = level;
            for (cycle = 0; cycle < BIT_TICKS; cycle = cycle + 1)
                @(negedge clk);
        end
    endtask

    task drive_raw_frame;
        input [6:0] data;
        input parity_bit;
        input stop_bit;
        integer bit_index;
        begin
            @(negedge clk);
            hold_raw_rx(1'b0);
            hold_raw_rx(parity_bit);
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
                hold_raw_rx(data[bit_index]);
            hold_raw_rx(stop_bit);
            raw_rx = 1'b1;
        end
    endtask

    initial begin
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'd0;
        raw_rx = 1'b1;

        #1 rstN = 1'b0;
        #1;
        if (tx !== 1'b1 || busy !== 1'b0 || rec_data !== 7'd0 ||
            rec_new_data !== 1'b0 || correct_data !== 1'b0 ||
            raw_rec_data !== 7'd0 || raw_rec_new_data !== 1'b0 ||
            raw_correct_data !== 1'b0)
            $fatal(1, "FAIL: asynchronous reset outputs");
        repeat (2) @(negedge clk);
        rstN = 1'b1;
        repeat (2) @(negedge clk);
        $display("PASS: reset and idle outputs");

        $display("TEST: exact valid frame and symbol timing");
        base_count = top_completion_count;
        send_and_check_frame(FIRST_DATA);
        wait_top_count(base_count + 1);
        check_top_result(base_count, FIRST_DATA);

        $display("TEST: request asserted while busy");
        base_count = top_completion_count;
        pulse_request(FIRST_DATA);
        if (busy !== 1'b1)
            $fatal(1, "FAIL: sender did not become busy");
        repeat (2 * BIT_TICKS) @(negedge clk);
        send_data = SECOND_DATA;
        new_data = 1'b1;
        @(negedge clk);
        new_data = 1'b0;
        wait_top_count(base_count + 1);
        check_top_result(base_count, FIRST_DATA);
        repeat (12 * BIT_TICKS) @(negedge clk);
        if (top_completion_count != base_count + 1)
            $fatal(1, "FAIL: busy request was queued");

        $display("TEST: required consecutive frames");
        base_count = top_completion_count;
        pulse_request(FIRST_DATA);
        while (busy !== 1'b0)
            @(negedge clk);
        send_data = SECOND_DATA;
        new_data = 1'b1;
        @(negedge clk);
        new_data = 1'b0;
        wait_top_count(base_count + 2);
        check_top_result(base_count, FIRST_DATA);
        check_top_result(base_count + 1, SECOND_DATA);

        $display("TEST: exhaustive seven-bit loopback");
        for (value = 0; value < 128; value = value + 1) begin
            base_count = top_completion_count;
            pulse_request(value[6:0]);
            wait_top_count(base_count + 1);
            check_top_result(base_count, value[6:0]);
        end

        $display("TEST: valid raw receiver frame");
        base_count = raw_completion_count;
        drive_raw_frame(FIRST_DATA, ^FIRST_DATA, 1'b1);
        wait_raw_count(base_count + 1);
        if (raw_correct_history[base_count] !== 1'b1 ||
            raw_data_history[base_count] !== FIRST_DATA)
            $fatal(1, "FAIL: valid raw frame");

        $display("TEST: required parity error");
        base_count = raw_completion_count;
        drive_raw_frame(SECOND_DATA, ~(^SECOND_DATA), 1'b1);
        wait_raw_count(base_count + 1);
        if (raw_correct_history[base_count] !== 1'b0 ||
            raw_data_history[base_count] !== FIRST_DATA)
            $fatal(1, "FAIL: parity error semantics");

        $display("TEST: required stop-bit error");
        base_count = raw_completion_count;
        drive_raw_frame(SECOND_DATA, ^SECOND_DATA, 1'b0);
        wait_raw_count(base_count + 1);
        if (raw_correct_history[base_count] !== 1'b0 ||
            raw_data_history[base_count] !== FIRST_DATA)
            $fatal(1, "FAIL: stop-bit error semantics");

        $display("TEST: false-start rejection and recovery");
        base_count = raw_completion_count;
        @(negedge clk);
        raw_rx = 1'b0;
        @(negedge clk);
        raw_rx = 1'b1;
        repeat (4 * BIT_TICKS) @(negedge clk);
        if (raw_completion_count != base_count)
            $fatal(1, "FAIL: false start completed a frame");
        drive_raw_frame(SECOND_DATA, ^SECOND_DATA, 1'b1);
        wait_raw_count(base_count + 1);
        if (raw_correct_history[base_count] !== 1'b1 ||
            raw_data_history[base_count] !== SECOND_DATA)
            $fatal(1, "FAIL: recovery after false start");

        @(negedge clk);
        $display("PASS: complete DSDL7 UART regression");
        $finish;
    end

endmodule
