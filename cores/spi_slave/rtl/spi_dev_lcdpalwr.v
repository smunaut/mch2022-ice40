/*
 * spi_dev_lcdpalwr.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module spi_dev_lcdpalwr #(
	// LSB must be 0 and it uses
	// CMD_BYTE and CMD_BYTE+1
	parameter [7:0] CMD_BYTE = 8'he4
)(
	// LCD PHY drive
	output wire  [7:0] phy_data,
	output wire        phy_rs,
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

	// SPI state
	(* keep *) wire [1:0] match;
	(* keep *) wire       start;

	reg  active_wr;
	reg  active_pal;

	// Palette RAM
	reg   [8:0] pal_waddr;
	wire  [7:0] pal_wdata;
	wire        pal_wen;

	wire  [7:0] pal_raddr;
	wire [15:0] pal_rdata;
	wire        pal_ren;

	// Read control
	reg   [1:0] rd_valid;
	reg         rd_bsel;


	// SPI
	// ---

	// Matching
	assign match[0] = (pw_wdata[7:4] == CMD_BYTE[7:4]);
	assign match[1] = (pw_wdata[3:1] == CMD_BYTE[3:1]);
	assign start = match[0] & match[1] & pw_wcmd & pw_wstb;

	// SPI Command tracking
	always @(posedge clk)
		if (rst) begin
			active_wr  <= 1'b0;
			active_pal <= 1'b0;
		end else begin
			active_wr  <= (active_wr  | (start & ~pw_wdata[0])) & ~pw_end;
			active_pal <= (active_pal | (start &  pw_wdata[0])) & ~pw_end;
		end


	// Palette RAM
	// -----------

	// Instance
	ice40_ebr #(
		.READ_MODE(0),	// x16
		.WRITE_MODE(1)	// x8
	) pal_ram_I (
		.wr_addr (pal_waddr),
		.wr_data (pal_wdata),
		.wr_ena  (pal_wen),
		.wr_mask (8'h00),
		.wr_clk  (clk),
		.rd_addr (pal_raddr),
		.rd_data (pal_rdata),
		.rd_ena  (pal_ren),
		.rd_clk  (clk)
	);

	// Write from SPI
	always @(posedge clk)
		if (pw_wstb)
			pal_waddr <= (pal_waddr + 1) & {9{~pw_wcmd}};

	assign pal_wdata = pw_wdata;
	assign pal_wen   = pw_wstb & active_pal;

	// Read from SPI to LCD
	assign pal_raddr = pw_wdata;
	assign pal_ren   = pw_wstb;

	always @(posedge clk)
	begin
		if (pw_wstb) begin
			rd_valid <= { 2{active_wr} };
			rd_bsel  <= 1'b0;
		end else begin
			rd_valid <= phy_ready ? { 1'b0, rd_valid[1] } : rd_valid;
			rd_bsel  <= rd_bsel ^ phy_ready;
		end
	end

	assign phy_valid = rd_valid[0];
	assign phy_data  = rd_bsel ? pal_rdata[7:0] : pal_rdata[15:8];
	assign phy_rs    = 1'b1;

endmodule // spi_dev_lcdpalwr
