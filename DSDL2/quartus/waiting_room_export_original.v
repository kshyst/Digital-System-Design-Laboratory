// Copyright (C) 2025  Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions
// and other software and tools, and any partner logic
// functions, and any output files from any of the foregoing
// (including device programming or simulation files), and any
// associated documentation or information are expressly subject
// to the terms and conditions of the Altera Program License
// Subscription Agreement, the Altera Quartus Prime License Agreement,
// the Altera IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Altera and sold by Altera or its authorized distributors.  Please
// refer to the Altera Software License Subscription Agreements
// on the Quartus Prime software download page.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition"
// CREATED		"Sat Aug  8 23:16:09 2026"

module waiting_room(
	clk,
	rst,
	in_sensor,
	out_sensor,
	ent,
	t_allow,
	close_door,
	open_door,
	occupancy0,
	occupancy1,
	occupancy2,
	occupancy3
);


input wire	clk;
input wire	rst;
input wire	in_sensor;
input wire	out_sensor;
input wire	ent;
input wire	t_allow;
output wire	close_door;
output wire	open_door;
output wire	occupancy0;
output wire	occupancy1;
output wire	occupancy2;
output wire	occupancy3;

wire	SYNTHESIZED_WIRE_24;
wire	SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_3;
wire	SYNTHESIZED_WIRE_4;
wire	[3:0] SYNTHESIZED_WIRE_25;
wire	SYNTHESIZED_WIRE_13;
wire	SYNTHESIZED_WIRE_14;
wire	SYNTHESIZED_WIRE_16;
wire	SYNTHESIZED_WIRE_17;
wire	SYNTHESIZED_WIRE_18;
wire	SYNTHESIZED_WIRE_19;
wire	SYNTHESIZED_WIRE_20;

assign	open_door = SYNTHESIZED_WIRE_13;
assign	occupancy0 = SYNTHESIZED_WIRE_25[0];
assign	occupancy1 = SYNTHESIZED_WIRE_25[1];
assign	occupancy2 = SYNTHESIZED_WIRE_25[2];
assign	occupancy3 = SYNTHESIZED_WIRE_25[3];




updown_counter4	b2v_u_cnt(
	.clk(clk),
	.clr_n(SYNTHESIZED_WIRE_24),
	.enable(SYNTHESIZED_WIRE_1),
	.u(in_sensor),
	.q(SYNTHESIZED_WIRE_25));

assign	SYNTHESIZED_WIRE_1 = in_sensor ^ out_sensor;


DFF	b2v_u_ent_d_ff(
	.CLRN(SYNTHESIZED_WIRE_24),
	.D(ent),
	.CLK(clk),
	.Q(SYNTHESIZED_WIRE_3));

assign	SYNTHESIZED_WIRE_4 =  ~SYNTHESIZED_WIRE_3;

assign	SYNTHESIZED_WIRE_19 = ent & SYNTHESIZED_WIRE_4;

assign	close_door = ~(SYNTHESIZED_WIRE_25 | SYNTHESIZED_WIRE_25 | SYNTHESIZED_WIRE_25 | SYNTHESIZED_WIRE_25);

assign	SYNTHESIZED_WIRE_14 =  ~in_sensor;

assign	SYNTHESIZED_WIRE_20 = ~(SYNTHESIZED_WIRE_25 & SYNTHESIZED_WIRE_25 & SYNTHESIZED_WIRE_25 & SYNTHESIZED_WIRE_25);

assign	SYNTHESIZED_WIRE_18 = SYNTHESIZED_WIRE_13 & SYNTHESIZED_WIRE_14;


DFF	b2v_u_open_ff(
	.CLRN(SYNTHESIZED_WIRE_24),
	.D(SYNTHESIZED_WIRE_16),
	.CLK(clk),
	.Q(SYNTHESIZED_WIRE_13));

assign	SYNTHESIZED_WIRE_16 = SYNTHESIZED_WIRE_17 | SYNTHESIZED_WIRE_18;

assign	SYNTHESIZED_WIRE_24 =  ~rst;

assign	SYNTHESIZED_WIRE_17 = SYNTHESIZED_WIRE_19 & SYNTHESIZED_WIRE_20 & t_allow;

assign	occupancy0 = q[0];
assign	occupancy1 = q[1];
assign	occupancy2 = q[2];
assign	occupancy3 = q[3];

endmodule
