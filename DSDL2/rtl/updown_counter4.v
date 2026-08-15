// 4-bit up/down counter, function table matches the assignment's Table 1.
// Clr is active-low asynchronous clear; Enable is a synchronous count-enable;
// U selects count direction (1 = up, 0 = down) on the rising edge of Clk.
module updown_counter4 (
    input  wire       clk,
    input  wire       clr_n,
    input  wire       enable,
    input  wire       u,
    output reg  [3:0] q
);

    always @(posedge clk or negedge clr_n) begin
        if (!clr_n)
            q <= 4'd0;
        else if (enable) begin
            if (u)
                q <= q + 4'd1;
            else
                q <= q - 4'd1;
        end
    end

endmodule
