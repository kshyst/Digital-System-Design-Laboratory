`timescale 1ns/1ps

module tb_serial_waveform;
    reg clk;
    reg reset;
    reg a;
    reg b;
    wire gt;
    wire eq;
    wire lt;

    serial_comparator dut(clk, reset, a, b, gt, eq, lt);

    task send_bit;
        input a_bit;
        input b_bit;
        begin
            a = a_bit;
            b = b_bit;
            #5 clk = 1;
            #5 clk = 0;
        end
    endtask

    initial begin
        $dumpfile(".build/serial_waveform.vcd");
        $dumpvars(0, tb_serial_waveform);

        clk = 0;
        reset = 1;
        a = 0;
        b = 0;
        #5 reset = 0;

        send_bit(1, 1);
        send_bit(0, 0);
        send_bit(1, 0);
        send_bit(0, 1);

        #5 $finish;
    end
endmodule
