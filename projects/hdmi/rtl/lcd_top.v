/*
 * lcd_top.v
 *
 * vim: ts=4 sw=4
 *
 * LCD top level
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module lcd_top (
	// LCD
	output wire  [7:0] lcd_d,
	output wire        lcd_rs,
	output wire        lcd_wr_n,
	output wire        lcd_cs_n,
	input  wire        lcd_mode,
	output wire        lcd_rst_n,
	input  wire        lcd_fmark,

	// Wishbone interface
	input  wire [31:0] wb_wdata,
	output wire [31:0] wb_rdata,
	input  wire [ 1:0] wb_addr,
	input  wire        wb_we,
	input  wire        wb_cyc,
	output reg         wb_ack,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	// LCD PHY
	wire        phy_ena;

	wire  [7:0] phy_data;
	wire        phy_rs;
	wire        phy_valid;
	wire        phy_ready;
	wire        phy_fmark_stb;

	wire        phy_rst;
	wire        phy_cs;


	// Wishbone interface
	// ------------------

	// Ack
	always @(posedge clk)
		wb_ack <= wb_cyc & ~wb_ack;

	// No read support
	assign wb_rdata = 32'h00000000;


	// Not implemented
	// ---------------

	assign phy_data  = 8'h00;
	assign phy_rs    = 1'b0;
	assign phy_valid = 1'b0;

	assign phy_rst = 1'b0;
	assign phy_cs  = 1'b0;


	// PHY
	// ---

	// Core
	lcd_phy #(
		.SPEED(1)
	) lcd_phy_I (
		.lcd_d         (lcd_d),
		.lcd_rs        (lcd_rs),
		.lcd_wr_n      (lcd_wr_n),
		.lcd_fmark     (lcd_fmark),
		.phy_ena       (phy_ena),
		.phy_data      (phy_data),
		.phy_rs        (phy_rs),
		.phy_valid     (phy_valid),
		.phy_ready     (phy_ready),
		.phy_fmark_stb (phy_fmark_stb),
		.clk           (clk),
		.rst           (rst)
	);

	// Individual IOBs
	SB_IO #(
		.PIN_TYPE(6'b1101_01),   // Reg+RegOE output
		.PULLUP(1'b1),
		.IO_STANDARD("SB_LVCMOS")
	) iob_od_I[1:0] (
		.PACKAGE_PIN   ({lcd_rst_n, lcd_cs_n}),
		.OUTPUT_CLK    (clk),
		.D_OUT_0       (2'b00),
		.OUTPUT_ENABLE ({phy_rst,   phy_cs})
	);

	SB_IO #(
		.PIN_TYPE(6'b0000_00),   // Reg input
		.PULLUP(1'b0),
		.IO_STANDARD("SB_LVCMOS")
	) iob_in_I (
		.PACKAGE_PIN (lcd_mode),
		.INPUT_CLK   (clk),
		.D_IN_0      (phy_ena)
	);

endmodule // lcd_top
