`timescale 1ns/1ps

module tb_uart_all_values;

    localparam integer BIT_TICKS = 2;
    localparam integer TIMEOUT_CYCLES = 30 * BIT_TICKS;

    reg clk;
    reg rstN;
    reg new_data;
    reg [6:0] send_data;
    wire tx;
    wire busy;
    wire [6:0] rec_data;
    wire rec_new_data;
    wire correct_data;
    integer value;
    integer cycles;

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

    initial begin
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'd0;
        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;

        for (value = 0; value < 128; value = value + 1) begin
            @(negedge clk);
            send_data = value[6:0];
            new_data = 1'b1;
            @(negedge clk);
            new_data = 1'b0;

            cycles = 0;
            while (rec_new_data !== 1'b1 && cycles < TIMEOUT_CYCLES) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (rec_new_data !== 1'b1)
                $fatal(1, "FAIL: value %0d timed out", value);
            if (correct_data !== 1'b1 || rec_data !== value[6:0])
                $fatal(1, "FAIL: sent=%0d received=%0d correct=%b",
                       value, rec_data, correct_data);

            @(negedge clk);
            if (rec_new_data !== 1'b0 || correct_data !== 1'b0)
                $fatal(1, "FAIL: output pulse width for value %0d", value);
        end

        $display("PASS: all 128 UART values");
        $finish;
    end

endmodule
