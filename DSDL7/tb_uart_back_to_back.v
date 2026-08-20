`timescale 1ns/1ps

module tb_uart_back_to_back;

    localparam integer BIT_TICKS = 4;
    localparam integer TIMEOUT_CYCLES = 30 * BIT_TICKS;
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
    integer completion_count;
    integer cycles;
    reg [6:0] first_received;
    reg [6:0] second_received;
    reg first_correct;
    reg second_correct;

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
            if (completion_count == 0) begin
                first_received = rec_data;
                first_correct = correct_data;
            end else if (completion_count == 1) begin
                second_received = rec_data;
                second_correct = correct_data;
            end
            completion_count = completion_count + 1;
        end
    end

    task pulse_request;
        input [6:0] value;
        begin
            send_data = value;
            new_data = 1'b1;
            @(negedge clk);
            new_data = 1'b0;
        end
    endtask

    initial begin
        completion_count = 0;
        first_received = 7'd0;
        second_received = 7'd0;
        first_correct = 1'b0;
        second_correct = 1'b0;
        rstN = 1'b1;
        new_data = 1'b0;
        send_data = 7'd0;
        #1 rstN = 1'b0;
        repeat (2) @(negedge clk);
        rstN = 1'b1;

        @(negedge clk);
        pulse_request(FIRST_DATA);
        if (busy !== 1'b1)
            $fatal(1, "FAIL: sender did not become busy");

        while (busy !== 1'b0)
            @(negedge clk);
        pulse_request(SECOND_DATA);

        cycles = 0;
        while (completion_count < 2 && cycles < 2 * TIMEOUT_CYCLES) begin
            @(negedge clk);
            cycles = cycles + 1;
        end
        if (completion_count != 2)
            $fatal(1, "FAIL: expected two completions, observed %0d",
                   completion_count);
        if (!first_correct || first_received !== FIRST_DATA)
            $fatal(1, "FAIL: first frame received=%b correct=%b",
                   first_received, first_correct);
        if (!second_correct || second_received !== SECOND_DATA)
            $fatal(1, "FAIL: second frame received=%b correct=%b",
                   second_received, second_correct);

        $display("PASS: consecutive UART frames");
        $finish;
    end

endmodule
