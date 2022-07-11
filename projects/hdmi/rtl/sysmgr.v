/*
 * sysmgr.v
 *
 * vim: ts=4 sw=4
 *
 * CRG generating:
 *  - clk_pix -  25.2 MHz pixel clock of HDMI
 *  - clk_1x  -  31.5 MHz for main logic
 *  - clk_4x  - 126.0 MHz for QPI memory & TMDS clock
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module sysmgr (
	// Inputs
	input  wire clk_in,

	// Outputs
	output wire clk_pix,
	output wire clk_1x,
	output wire clk_4x,
	output wire sync_4x,
	output wire rst
);

	// Signals
	// -------

	// Misc
	wire     pll_lock;

	// System reset
	reg [3:0] rst_cnt;
	wire      rst_i;


	// System clock
	// ------------

	// PLL
	SB_PLL40_2F_PAD #(
		.FEEDBACK_PATH       ("SIMPLE"),
		.DIVR                (4'b0000),
		.DIVF                (7'b1010011),
		.DIVQ                (3'b011),
		.FILTER_RANGE        (3'b001),
		.PLLOUT_SELECT_PORTA ("GENCLK"),
		.PLLOUT_SELECT_PORTB ("SHIFTREG_0deg"),
		.SHIFTREG_DIV_MODE   (3),
	) pll_I (
		.PACKAGEPIN    (clk_in),
		.PLLOUTGLOBALA (clk_4x),
		.PLLOUTGLOBALB (clk_pix),
		.RESETB        (1'b1),
		.LOCK          (pll_lock)
	);

	// Fabric derived clocks
	ice40_serdes_crg #(
		.NO_CLOCK_2X(1)
	) crg_I (
		.clk_4x   (clk_4x),
		.pll_lock (pll_lock),
		.clk_1x   (clk_1x),
		.rst      (rst)
	);

	// SERDES sync signal
	ice40_serdes_sync #(
		.PHASE      (2),
		.NEG_EDGE   (0),
		.GLOBAL_BUF (0),
		.LOCAL_BUF  (0),
		.BEL_COL    ("X21"),
		.BEL_ROW    ("Y4")
	) sync_4x_I (
		.clk_slow (clk_1x),
		.clk_fast (clk_4x),
		.rst      (rst),
		.sync     (sync_4x)
	);

endmodule // sysmgr
