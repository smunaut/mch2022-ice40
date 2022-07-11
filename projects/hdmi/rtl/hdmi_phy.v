/*
 * hdmi_phy.v
 *
 * vim: ts=4 sw=4
 *
 * HDMI PHY (TMDS encoders & serializers)
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module hdmi_phy (
	// PADs
	output wire [3:0] hdmi_p,
	output wire [3:0] hdmi_n,

	// Inputs
	input  wire [7:0] in_r,
	input  wire [7:0] in_g,
	input  wire [7:0] in_b,
	input  wire       in_hsync,
	input  wire       in_vsync,
	input  wire       in_de,

	// Clock / Reset
	input  wire clk_tmds,
	input  wire clk_pix,
	input  wire rst_pix
);

	// Signals
	// -------

	// Lanes
	wire [9:0] tmds[0:3];

	// Serializars
	reg  [1:0] sync_r;
	wire       load_r;
	reg  [1:0] sync_f;
	wire       load_f;
	reg  [5:0] ser_r[0:3];
	reg  [5:0] ser_f[0:3];

	// IO signals
	wire [7:0] iob_rise;
	wire [7:0] iob_fall;


	// Encoders
	// --------

	// Lane 0 (Blue)
	hdmi_tmds_simple enc0 (
		.q   (tmds[0]),
		.c   ({in_vsync, in_hsync}),
		.d   (in_b),
		.den (in_de),
		.clk (clk_pix),
		.rst (rst_pix),
	);

	// Lane 1 (Green)
	hdmi_tmds_simple enc1 (
		.q   (tmds[1]),
		.c   (2'b00),
		.d   (in_g),
		.den (in_de),
		.clk (clk_pix),
		.rst (rst_pix),
	);

	// Lane 2 (Red)
	hdmi_tmds_simple enc2 (
		.q   (tmds[2]),
		.c   (2'b00),
		.d   (in_r),
		.den (in_de),
		.clk (clk_pix),
		.rst (rst_pix),
	);

	// Clock
	assign tmds[3] = 10'b1111100000;


	// Serializers
	// -----------

	always @(posedge clk_tmds)
		sync_r <= { sync_r[0], clk_pix };

	assign load_r = sync_r[0] & ~sync_r[1];

	always @(negedge clk_tmds)
		sync_f <= { sync_f[0], clk_pix };

	assign load_f = sync_f[0] & ~sync_f[1];


	always @(posedge clk_tmds)
	begin : xp
		integer i;
		for (i=0; i<4; i=i+1)
			ser_r[i] <= load_r ?
				{ tmds[i][9], tmds[i][7], tmds[i][5], tmds[i][3], tmds[i][1], ~tmds[i][1] } :
				{ 1'b0, ser_r[i][5:2], ~ser_r[i][2] };
	end

	always @(negedge clk_tmds)
	begin : xn
		integer i;
		for (i=0; i<4; i=i+1)
			ser_f[i] <= load_f ?
				{ tmds[i][8], tmds[i][6], tmds[i][4], tmds[i][2], tmds[i][0], ~tmds[i][0] } :
				{ 1'b0, ser_f[i][5:2], ~ser_f[i][2] };
	end

	assign iob_rise = {
		ser_r[3][1], ser_r[2][1], ser_r[1][1], ser_r[0][1],
		ser_r[3][0], ser_r[2][0], ser_r[1][0], ser_r[0][0]
	};
	assign iob_fall = {
		ser_f[3][1], ser_f[2][1], ser_f[1][1], ser_f[0][1],
		ser_f[3][0], ser_f[2][0], ser_f[1][0], ser_f[0][0]
	};


	// IOBs
	// ----

	SB_IO #(
		.PIN_TYPE(6'b0100_01), // DDR Output
		.PULLUP(1'b0),
		.IO_STANDARD("SB_LVCMOS")
	) iob_I[7:0] (
		.PACKAGE_PIN   ({hdmi_p, hdmi_n}),
		.OUTPUT_CLK    (clk_tmds),
		.D_OUT_0       (iob_rise),
		.D_OUT_1       (iob_fall),
		.OUTPUT_ENABLE (1'b1)
	);

endmodule // hdmi_phy
