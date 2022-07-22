/*
 * spi_dev_scmd.v
 *
 * vim: ts=4 sw=4
 *
 * Simple Command decoder.
 * Interfaces to the protocol wrapper to decode simple/short commands
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module spi_dev_scmd #(
	parameter [7:0] CMD_BYTE = 8'h00,
	parameter integer CMD_LEN = 4,
	parameter integer CMD_REPEAT = 0,

	// auto
	parameter integer DL = (8*CMD_LEN)-1
)(
	// Protocol wrapper interface
	input  wire  [7:0] pw_wdata,
	input  wire        pw_wcmd,
	input  wire        pw_wstb,

	input  wire        pw_end,

	// Command output
	output wire [DL:0] cmd_data,
	output reg         cmd_stb,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	// Write Shift
	reg  [DL:0] ws_data;
	reg  [CMD_LEN-1:0] ws_stb_shift;

	// Command match
	(* keep *)
	wire [1:0] cmd_match;

	// Command decoder
	// ---------------

	// Data shift register
	always @(posedge clk)
		if (pw_wstb)
			ws_data <= { ws_data[DL-8:0], pw_wdata };

	assign cmd_data = ws_data;

	// Command match
	assign cmd_match[0] = CMD_BYTE[7:4] == pw_wdata[7:4];
	assign cmd_match[1] = CMD_BYTE[3:0] == pw_wdata[3:0];

	always @(posedge clk or posedge rst)
		if (rst)
			ws_stb_shift <= 0;
		else if (pw_wstb)
			ws_stb_shift <= pw_wcmd ?
				{ { (CMD_LEN-1){1'b0} }, &cmd_match } :
				{ ws_stb_shift[CMD_LEN-2:0], CMD_REPEAT ? ws_stb_shift[CMD_LEN-1] : 1'b0 };

	always @(posedge clk)
		cmd_stb <= pw_wstb & ~pw_wcmd & ws_stb_shift[CMD_LEN-1];

endmodule // spi_dev_scmd
