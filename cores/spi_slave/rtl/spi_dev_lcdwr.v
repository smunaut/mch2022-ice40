/*
 * spi_dev_lcdwr.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module spi_dev_lcdwr #(
	parameter [7:0] CMD_BYTE = 8'hf2
)(
	// LCD PHY drive
	output reg   [7:0] phy_data,
	output reg         phy_rs,
	output reg         phy_valid,
	input  wire        phy_ready,

	// SPI protocol wrapper interface
	input  wire  [7:0] pw_wdata,
	input  wire        pw_wcmd,
	input  wire        pw_wstb,

	input  wire        pw_end,

	// Clock /Reset
	input  wire        clk,
	input  wire        rst
);

	// Signals
	// -------

	// FSM
	localparam [1:0]
		ST_LEN  = 2'b00,
		ST_CMD  = 2'b10,
		ST_DATA = 2'b11;

	reg         active;
	reg   [1:0] state;
	reg   [1:0] state_nxt;

	// Data length tracker
	reg   [8:0] data_len;
	reg         data_inf;
	wire        data_last;


	// FSM
	// ---

	// SPI Command tracking
	always @(posedge clk)
		if (rst)
			active <= 1'b0;
		else
			active <= (active | (pw_wstb & pw_wcmd & (pw_wdata == CMD_BYTE))) & ~pw_end;

	// State tracking
	always @(posedge clk or posedge rst)
		if (rst)
			state <= ST_LEN;
		else if (pw_wstb)
			state <= state_nxt;

	always @(*)
	begin
		// Default sequence
		case (state)
			ST_LEN:  state_nxt = ST_CMD;
			ST_CMD:  state_nxt = data_last ? ST_LEN : ST_DATA;
			ST_DATA: state_nxt = data_last ? ST_LEN : ST_DATA;
			default: state_nxt = state;
		endcase

		// Reset
		if (pw_wcmd)
			state_nxt = ST_LEN;
	end

	// Data length tracking
	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			data_len <= 0;
			data_inf <= 1'b0;
		end else if (pw_wstb) begin
			data_len <= ((state == ST_LEN) ? { 1'b0, pw_wdata } : data_len) - 1;
			data_inf <=  (state == ST_LEN) ? &pw_wdata : data_inf;
		end
	end

	assign data_last = data_len[8] & ~data_inf;

	// Register data
	always @(posedge clk)
		if (pw_wstb) begin
			phy_data <= pw_wdata;
			phy_rs   <= state == ST_DATA;
		end

	always @(posedge clk)
		phy_valid <=
			(phy_valid & ~phy_ready) |
			(pw_wstb & active & (
				(state == ST_CMD) |
				(state == ST_DATA)
			));

endmodule // spi_dev_lcdwr
