/*
 * lcd_top.v
 *
 * vim: ts=4 sw=4
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
	output wire        lcd_mode,
	output wire        lcd_rst_n,
	input  wire        lcd_fmark,

	// SPI protocol wrapper interface
	input  wire  [7:0] pw_wdata,
	input  wire        pw_wcmd,
	input  wire        pw_wstb,

	input  wire        pw_end,

	// Data from GPU
	input  wire [15:0] gpu_data,
	input  wire        gpu_valid,
	output wire        gpu_ready,

	// Clock /Reset
	input  wire        clk,
	input  wire        rst
);

	// Signals
	// -------

	// PHY
	wire [23:0] usr_data;
	wire  [2:0] usr_rs;
	wire  [2:0] usr_valid;
	wire  [2:0] usr_ready;

	wire  [7:0] phy_data;
	wire        phy_rs;
	wire        phy_valid;
	wire        phy_ready;


	// Shifter
	// -------

	reg lcd_sel;

	assign usr_data[7:0] = lcd_sel ? gpu_data[7:0] : gpu_data[15:8];
	assign usr_rs[0]     = 1'b1;
	assign usr_valid[0]  = gpu_valid;
	assign gpu_ready     = lcd_sel;

	always @(posedge clk)
		if (rst)
			lcd_sel <= 1'b0;
		else
			lcd_sel <= gpu_valid & ~lcd_sel;


	// SPI pass-through
	// ----------------

	spi_dev_lcdwr #(
		.CMD_BYTE(8'hf2)
	) spi_pt_I (
		.phy_data  (usr_data[15:8]),
		.phy_rs    (usr_rs[1]),
		.phy_valid (usr_valid[1]),
		.phy_ready (usr_ready[1]),
		.pw_wdata  (pw_wdata),
		.pw_wcmd   (pw_wcmd),
		.pw_wstb   (pw_wstb),
		.pw_end    (pw_end),
		.clk       (clk),
		.rst       (rst)
	);


	// SPI palette writer
	// ------------------

	spi_dev_lcdpalwr #(
		.CMD_BYTE(8'he4)
	) spi_pal_I (
		.phy_data  (usr_data[23:16]),
		.phy_rs    (usr_rs[2]),
		.phy_valid (usr_valid[2]),
		.phy_ready (usr_ready[2]),
		.pw_wdata  (pw_wdata),
		.pw_wcmd   (pw_wcmd),
		.pw_wstb   (pw_wstb),
		.pw_end    (pw_end),
		.clk       (clk),
		.rst       (rst)
	);


	// PHY
	// ---

	// PHY muxing
	lcd_phy_mux #(
		.N(3)
	) mux_I (
		.phy_data   (phy_data),
		.phy_rs     (phy_rs),
		.phy_valid  (phy_valid),
		.phy_ready  (phy_ready),
		.usr_data   (usr_data),
		.usr_rs     (usr_rs),
		.usr_valid  (usr_valid),
		.usr_ready  (usr_ready),
		.clk        (clk),
		.rst        (rst)
	);

	// Core
	lcd_phy_full #(
		.SPEED(1)
	) phy_I (
		.lcd_d         (lcd_d),
		.lcd_rs        (lcd_rs),
		.lcd_wr_n      (lcd_wr_n),
		.lcd_cs_n      (lcd_cs_n),
		.lcd_mode      (lcd_mode),
		.lcd_rst_n     (lcd_rst_n),
		.lcd_fmark     (lcd_fmark),
		.phy_data      (phy_data),
		.phy_rs        (phy_rs),
		.phy_valid     (phy_valid),
		.phy_ready     (phy_ready),
		.phy_ena       (1'b1),
		.phy_rst       (1'b0),
		.phy_cs        (1'b1),
		.phy_mode      (),
		.phy_fmark_stb (),
		.clk           (clk),
		.rst           (rst)
	);

endmodule // lcd_top
