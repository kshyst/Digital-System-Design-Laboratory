`timescale 1ns/1ps

// Seven-bit UART sender for the assignment-specific parity-before-data frame.
// new_data is accepted only while idle; the active frame uses a latched copy.
module UARTSender #(
    parameter integer BIT_TICKS = 434
) (
    input  wire       clk,
    input  wire       rstN,
    input  wire       new_data,
    input  wire [6:0] send_data,
    output wire       tx,
    output wire       busy
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

    localparam [2:0] IDLE   = 3'd0;
    localparam [2:0] START  = 3'd1;
    localparam [2:0] PARITY = 3'd2;
    localparam [2:0] DATA   = 3'd3;
    localparam [2:0] STOP   = 3'd4;

    reg [2:0] state;
    reg [TICK_WIDTH-1:0] tick_count;
    reg [2:0] bit_index;
    reg [6:0] data_latch;
    reg parity_latch;

    assign busy = state != IDLE;
    assign tx = state == START  ? 1'b0 :
                state == PARITY ? parity_latch :
                state == DATA   ? data_latch[bit_index] : 1'b1;

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            state        <= IDLE;
            tick_count   <= {TICK_WIDTH{1'b0}};
            bit_index    <= 3'd0;
            data_latch   <= 7'd0;
            parity_latch <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tick_count <= {TICK_WIDTH{1'b0}};
                    bit_index  <= 3'd0;
                    if (new_data) begin
                        data_latch   <= send_data;
                        parity_latch <= ^send_data;
                        state        <= START;
                    end
                end

                START: begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
                        state <= PARITY;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end

                PARITY: begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
                        bit_index <= 3'd0;
                        state <= DATA;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end

                DATA: begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= {TICK_WIDTH{1'b0}};
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
