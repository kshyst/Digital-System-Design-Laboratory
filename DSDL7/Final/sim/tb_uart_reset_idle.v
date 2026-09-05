`timescale 1ns/1ps

module tb_uart_reset_idle;

    localparam integer BIT_TICKS = 4;

    reg clk;
    reg rstN;
    reg new_data;
    reg [6:0] send_data;
    wire tx;
    wire busy;
    wire [6:0] rec_data;
    wire rec_new_data;
    wire correct_data;

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

    task check_idle;
        begin
            if (tx !== 1'b1 || busy !== 1'b0 || rec_data !== 7'd0 ||
                rec_new_data !== 1'b0 || correct_data !== 1'b0)
                $fatal(1,
                       "FAIL: tx=%b busy=%b data=%b new=%b correct=%b",
                       tx, busy, rec_data, rec_new_data, correct_data);
        end
    endtask

    initial begin
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'b1111111;

        #1 rstN = 1'b0;
        #1 check_idle;
        repeat (2) @(negedge clk);
        check_idle;

        rstN = 1'b1;
        repeat (2) @(negedge clk);
        check_idle;

        $display("PASS: reset and idle behavior");
        $finish;
    end

endmodule
