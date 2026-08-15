// Waiting-room entrance/exit controller (Experiment 2).
//
// in_sensor / out_sensor : one-clock-pulse-wide sensor signals (IN / OUT)
// ent                    : entrance request push-button (Ent)
// t_allow                : 1 while entry hours are still open, 0 once the
//                           permitted entry hour has passed (T)
// rst                    : synchronous-style system reset button (active high)
// open_door               : held 1 from the moment entry is granted until
//                           the person is detected passing (IN)  (Open)
// close_door               : 1 while the room is empty, so the exit door can
//                           be shut (Close)
// occupancy                : current headcount, 0..15 (debug / LED output)
module waiting_room (
    input  wire       clk,
    input  wire       rst,
    input  wire       in_sensor,
    input  wire       out_sensor,
    input  wire       ent,
    input  wire       t_allow,
    output wire       open_door,
    output wire       close_door,
    output wire [3:0] occupancy
);

    wire clr_n = ~rst;

    // A person entering and a person leaving in the same clock pulse cancel
    // out, so the counter only ever needs a single up/down step per cycle.
    wire cnt_enable = in_sensor ^ out_sensor;
    wire cnt_up     = in_sensor;

    updown_counter4 U_COUNT (
        .clk    (clk),
        .clr_n  (clr_n),
        .enable (cnt_enable),
        .u      (cnt_up),
        .q      (occupancy)
    );

    // occupancy < 15  <=>  not all four bits are 1
    wire lt15 = ~(occupancy[3] & occupancy[2] & occupancy[1] & occupancy[0]);
    // occupancy == 0
    wire eq0  = ~(occupancy[3] | occupancy[2] | occupancy[1] | occupancy[0]);

    // Rising-edge detector on Ent, so the admission condition is evaluated
    // exactly once "at the moment the button is pressed", not on every
    // clock pulse the button happens to be held down.
    reg ent_d;
    always @(posedge clk or posedge rst)
        if (rst) ent_d <= 1'b0;
        else     ent_d <= ent;
    wire ent_pulse = ent & ~ent_d;

    wire set_open = ent_pulse & lt15 & t_allow;

    reg open_reg;
    always @(posedge clk or posedge rst)
        if (rst) open_reg <= 1'b0;
        else     open_reg <= set_open | (open_reg & ~in_sensor);

    assign open_door  = open_reg;
    assign close_door = eq0;

endmodule
