`timescale 1ns/1ps

module tb_uart_frame_format;

    localparam integer BIT_TICKS = 434;
    localparam [6:0] TEST_DATA = 7'b1011001;

    reg clk;
    reg rstN;
    reg new_data;
    reg [6:0] send_data;
    wire tx;
    wire busy;
    integer bit_index;

    UARTSender dut (
        .clk(clk),
        .rstN(rstN),
        .new_data(new_data),
        .send_data(send_data),
        .tx(tx),
        .busy(busy)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check_symbol;
        input expected_tx;
        integer cycle;
        begin
            for (cycle = 0; cycle < BIT_TICKS; cycle = cycle + 1) begin
                if (tx !== expected_tx || busy !== 1'b1)
                    $fatal(1,
                           "FAIL: symbol=%b cycle=%0d tx=%b busy=%b",
                           expected_tx, cycle, tx, busy);
                @(negedge clk);
            end
        end
    endtask

    initial begin
        $dumpfile("/tmp/tb_uart_frame_format.vcd");
        $dumpvars(0, tb_uart_frame_format);
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'b0;

        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;

        if (tx !== 1'b1 || busy !== 1'b0)
            $fatal(1, "FAIL: sender is not idle after reset");

        @(negedge clk);
        send_data = TEST_DATA;
        new_data = 1'b1;
        @(negedge clk);
        new_data = 1'b0;

        check_symbol(1'b0);
        check_symbol(^TEST_DATA);
        for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1)
            check_symbol(TEST_DATA[bit_index]);
        check_symbol(1'b1);

        if (tx !== 1'b1 || busy !== 1'b0)
            $fatal(1, "FAIL: sender did not return to idle");

        $display("PASS: sender frame format and 434-cycle timing");
        $finish;
    end

endmodule
