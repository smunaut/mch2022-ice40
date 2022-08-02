/*
 * lcd_phy_mux.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module lcd_phy_mux #(
	parameter integer N = 2
)(
	// To actual PHY
	output reg  [7:0] phy_data,
	output reg        phy_rs,
	output wire       phy_valid,
	input  wire       phy_ready,

	// From users
	input  wire [8*N-1:0] usr_data,
	input  wire [  N-1:0] usr_rs,
	input  wire [  N-1:0] usr_valid,
	output wire [  N-1:0] usr_ready,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	integer i;

	always @(*)
	begin
		// Defaults
		phy_data = 8'hxx;
		phy_rs   = 1'bx;

		// Priority to low indexes
		for (i=N-1; i>=0; i=i-1)
		begin
			if (usr_valid[i])
			begin
				phy_data = usr_data[8*i+:8];
				phy_rs   = usr_rs[i];
			end
		end
	end

	assign phy_valid = |usr_valid;

	assign usr_ready = { N{phy_ready} };


endmodule // lcd_phy_mux
