`timescale 1ns/1ps

// Seven-bit UART receiver for the assignment-specific parity-before-data frame.
// rx is synchronized, the start bit is confirmed at midpoint, and each later
// symbol is sampled once per BIT_TICKS clocks at the same phase.
module UARTReceiver #(
    parameter integer BIT_TICKS = 434
) (
    input  wire       clk,
    input  wire       rstN,
    input  wire       rx,
    output reg  [6:0] rec_data,
    output reg        rec_new_data,
    output reg        correct_data
);

    function integer counter_width;
        input integer value;
        integer width;
        begin
            value = value - 1;
            width = 0;
            while (value > 0) begin
                value = value >> 1;
                width = width + 1;
            end
            counter_width = width < 1 ? 1 : width;
        end
    endfunction

    localparam integer TICK_WIDTH = counter_width(BIT_TICKS);
    localparam [TICK_WIDTH-1:0] LAST_TICK = BIT_TICKS - 1;
    localparam [TICK_WIDTH-1:0] HALF_TICK = (BIT_TICKS / 2) - 1;

    localparam [2:0] IDLE   = 3'd0;
    localparam [2:0] START  = 3'd1;
    localparam [2:0] PARITY = 3'd2;
    localparam [2:0] DATA   = 3'd3;
    localparam [2:0] STOP   = 3'd4;

    reg rx_meta;
    reg rx_sync;
    reg [2:0] state;
    reg [TICK_WIDTH-1:0] tick_count;
    reg [2:0] bit_index;
    reg [6:0] data_latch;
    reg parity_latch;

    // Two flip-flops isolate the FSM from an asynchronous serial input.
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            state          <= IDLE;
            tick_count     <= {TICK_WIDTH{1'b0}};
            bit_index      <= 3'd0;
            data_latch     <= 7'd0;
            parity_latch   <= 1'b0;
            rec_data       <= 7'd0;
            rec_new_data   <= 1'b0;
            correct_data   <= 1'b0;
        end else begin
            // Completion and validity are aligned one-clock notifications.
            rec_new_data <= 1'b0;
            correct_data <= 1'b0;

            case (state)
                IDLE: begin
                    tick_count <= {TICK_WIDTH{1'b0}};
                    bit_index <= 3'd0;
                    if (!rx_sync)
                        state <= START;
                end

                START: begin
                    if (tick_count == HALF_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
                        state <= rx_sync ? IDLE : PARITY;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end

                PARITY: begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
                        bit_index <= 3'd0;
                        parity_latch <= rx_sync;
                        state <= DATA;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end

                DATA: begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
                        data_latch[bit_index] <= rx_sync;
                        if (bit_index == 3'd6) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end

                STOP: begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
                        rec_new_data <= 1'b1;
                        if (rx_sync && ((^data_latch) == parity_latch)) begin
                            rec_data <= data_latch;
                            correct_data <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    tick_count <= {TICK_WIDTH{1'b0}};
                    bit_index <= 3'd0;
                end
            endcase
        end
    end

endmodule
