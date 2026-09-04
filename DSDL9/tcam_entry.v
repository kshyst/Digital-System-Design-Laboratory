`timescale 1ns/1ps
`default_nettype none

// One DATA_WIDTH-bit ternary memory entry.
// A 1 in stored_x_mask makes the corresponding stored bit a don't-care (X).
module tcam_entry #(
    parameter integer DATA_WIDTH = 16
) (
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  write_enable,
    input  wire [DATA_WIDTH-1:0] write_data,
    input  wire [DATA_WIDTH-1:0] write_x_mask,
    input  wire [DATA_WIDTH-1:0] search_data,
    output wire                  match
);
    reg [DATA_WIDTH-1:0] stored_data;
    reg [DATA_WIDTH-1:0] stored_x_mask;
    reg                  valid;

    wire [DATA_WIDTH-1:0] mismatched_bits;

    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
        end else if (write_enable) begin
            stored_data <= write_data;
            stored_x_mask <= write_x_mask;
            valid <= 1'b1;
        end
    end

    // Masked positions are removed before checking for unequal bits.
    assign mismatched_bits = (search_data ^ stored_data) & ~stored_x_mask;
    assign match = valid && (mismatched_bits == {DATA_WIDTH{1'b0}});
endmodule

`default_nettype wire
