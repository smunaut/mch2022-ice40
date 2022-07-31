/*
 * lcd_phy_full.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module lcd_phy_full #(
	parameter integer SPEED = 0		// 0 = clk/2, 1 = clk
)(
	// LCD
	output wire [7:0] lcd_d,
	output wire       lcd_rs,
	output wire       lcd_wr_n,
	output wire       lcd_cs_n,
	output wire       lcd_mode,
	output wire       lcd_rst_n,
	input  wire       lcd_fmark,

	// Data
	input  wire [7:0] phy_data,
	input  wire       phy_rs, // 0 = cmd, 1 = data
	input  wire       phy_valid,
	output wire       phy_ready,

	// Control Status
	input  wire       phy_ena,
	input  wire       phy_rst,
	input  wire       phy_cs,
	output wire       phy_mode,
	output wire       phy_fmark_stb,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	wire        phy_ena_i;
	wire        phy_rst_i;
	wire        phy_cs_i;


	// Control
	// -------

	assign phy_ena_i = phy_mode ? phy_ena : 1'b0;
	assign phy_rst_i = phy_mode ? phy_rst : 1'b0;
	assign phy_cs_i  = phy_mode ? phy_cs  : 1'b0;


	// RAW PHY
	// -------

	lcd_phy_raw #(
		.SPEED(SPEED)
	) raw_I (
		.lcd_d         (lcd_d),
		.lcd_rs        (lcd_rs),
		.lcd_wr_n      (lcd_wr_n),
		.lcd_fmark     (lcd_fmark),
		.phy_ena       (phy_ena_i),
		.phy_data      (phy_data),
		.phy_rs        (phy_rs),
		.phy_valid     (phy_valid),
		.phy_ready     (phy_ready),
		.phy_fmark_stb (phy_fmark_stb),
		.clk           (clk),
		.rst           (rst)
	);

	// Independent IOBs
	// ----------------

	SB_IO #(
		.PIN_TYPE(6'b1101_01),   // Reg+RegOE output
		.PULLUP(1'b1),
		.IO_STANDARD("SB_LVCMOS")
	) iob_od_I[1:0] (
		.PACKAGE_PIN   ({lcd_rst_n, lcd_cs_n}),
		.OUTPUT_CLK    (clk),
		.D_OUT_0       (2'b00),
		.OUTPUT_ENABLE ({phy_rst_i, phy_cs_i})
	);

	SB_IO #(
		.PIN_TYPE(6'b0000_00),   // Reg input
		.PULLUP(1'b0),
		.IO_STANDARD("SB_LVCMOS")
	) iob_in_I (
		.PACKAGE_PIN (lcd_mode),
		.INPUT_CLK   (clk),
		.D_IN_0      (phy_mode)
	);

endmodule // lcd_phy_full
