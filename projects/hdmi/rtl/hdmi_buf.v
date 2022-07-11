/*
 * hdmi_buf.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2020-2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module hdmi_buf (
	// Write port
	input  wire [ 9:0] waddr,
	input  wire [15:0] wdata,
	input  wire        wren,
	input  wire        wclk,

	// Read port
	input  wire [ 9:0] raddr,
	output wire [15:0] rdata,
	input  wire        rclk
);

	genvar i;

	generate
		for (i=0; i<4; i=i+1)
			ice40_ebr #(
				.READ_MODE  (2),	// 1024x4
				.WRITE_MODE (2)		// 1024x4
			) ebr_wrap_I (
				.wr_addr (waddr),
				.wr_data (wdata[i*4+:4]),
				.wr_mask (4'h0),
				.wr_ena  (wren),
				.wr_clk  (wclk),
				.rd_addr (raddr),
				.rd_data (rdata[i*4+:4]),
				.rd_ena  (1'b1),
				.rd_clk  (rclk)
			);
	endgenerate

endmodule
