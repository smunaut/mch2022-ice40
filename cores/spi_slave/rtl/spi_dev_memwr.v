/*
 * spi_dev_memwr.v
 *
 * vim: ts=4 sw=4
 *
 * SPI memory write
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module spi_dev_memwr #(
	parameter [7:0] CMD_BYTE = 8'he0,
	parameter integer DATA_WIDTH = 16,
	parameter integer ADDR_WIDTH = 23,	// Word-address
	parameter integer BURST_LEN = 64,	// In words

	// auto-set
	parameter integer DL = DATA_WIDTH - 1,
	parameter integer AL = ADDR_WIDTH - 1
)(
	// Protocol wrapper interface
	input  wire  [7:0] pw_wdata,
	input  wire        pw_wcmd,
	input  wire        pw_wstb,

	input  wire        pw_end,

	// Memory interface
	output wire [AL:0] mi_addr,
	output wire [ 6:0] mi_len,
	output wire        mi_rw,
	output wire        mi_valid,
	input  wire        mi_ready,

	output wire [DL:0] mi_wdata,
	input  wire        mi_wack,
	input  wire        mi_wlast,

	input  wire [DL:0] mi_rdata,	// Not used
	input  wire        mi_rstb,		// Not used
	input  wire        mi_rlast,	// Not used

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

	// Bus
	wire        bus_clr;
	reg         bus_we_csr;
	reg         bus_we_base;

	// FIFO
	wire [DL:0] fw_data;
	wire        fw_ena;
	wire        fw_full;

	wire [DL:0] fr_data;
	wire        fr_ena;
	wire        fr_empty;

	(* keep *)
	wire  [8:0] fifo_level_inc;
	reg   [8:0] fifo_level;

	// DMA
	reg         dma_run;

	localparam [1:0]
		DS_IDLE = 2'b00,
		DS_CMD  = 2'b01,
		DS_WAIT = 2'b10;

	reg   [1:0] dma_state;
	reg   [1:0] dma_state_nxt;

	reg  [AL:0] dma_addr;


	// Wishbone interface
	// ------------------

	// Ack
	always @(posedge clk)
		wb_ack <= wb_cyc & ~wb_ack;

	// Clear
	assign bus_clr = ~wb_cyc | wb_ack;

	// Write strobes
	always @(posedge clk)
		if (bus_clr) begin
			bus_we_csr  <= 1'b0;
			bus_we_base <= 1'b0;
		end else begin
			bus_we_csr  <= wb_we & (wb_addr == 2'b00);
			bus_we_base <= wb_we & (wb_addr == 2'b01);
		end

	// No read support
	assign wb_rdata = 32'h00000000;


	// SPI-to-FIFO
	// -----------

	// Command decode (with repeat)
	spi_dev_scmd #(
		.CMD_BYTE(CMD_BYTE),
		.CMD_LEN(DATA_WIDTH / 8),
		.CMD_REPEAT(1)
	) cmd_I (
		.pw_wdata (pw_wdata),
		.pw_wcmd  (pw_wcmd),
		.pw_wstb  (pw_wstb),
		.pw_end   (pw_end),
		.cmd_data (fw_data),
		.cmd_stb  (fw_ena),
		.clk      (clk),
		.rst      (rst)
	);

	// FIFO instance
	fifo_sync_ram #(
		.DEPTH(256),
		.WIDTH(DATA_WIDTH)
	) fifo_I (
		.wr_data  (fw_data),
		.wr_ena   (fw_ena & ~fw_full),
		.wr_full  (fw_full),
		.rd_data  (fr_data),
		.rd_ena   (fr_ena & ~fr_empty),
		.rd_empty (fr_empty),
		.clk      (clk),
		.rst      (rst)
	);

	// Fill level counter
	assign fifo_level_inc[8:2] = {7{fifo_level_inc[1]}};
	assign fifo_level_inc[1] = fr_ena & ~fw_ena;
	assign fifo_level_inc[0] = fr_ena ^  fw_ena;

	always @(posedge clk)
		if (rst)
			fifo_level <= 0;
		else
			fifo_level <= fifo_level + fifo_level_inc;


	// DMA
	// ---

	// Register Write
	always @(posedge clk or posedge rst)
		if (rst)
			dma_run <= 1'b0;
		else if (bus_we_csr)
			dma_run <= wb_wdata[0];

	// Address
	always @(posedge clk)
		if (rst)
			dma_addr <= 0;
		else if (bus_we_base)
			dma_addr <= wb_wdata[AL:0];
		else if (mi_valid & mi_ready)
			dma_addr <= dma_addr + BURST_LEN;

	// Control
	always @(posedge clk)
		if (rst)
			dma_state <= DS_IDLE;
		else
			dma_state <= dma_state_nxt;

	always @(*)
	begin
		// Default is no change
		dma_state_nxt = dma_state;

		// Transitions
		case (dma_state)
		DS_IDLE:
			if (|fifo_level[8:6] & dma_run)
				dma_state_nxt = DS_CMD;

		DS_CMD:
			if (mi_ready)
				dma_state_nxt = DS_WAIT;

		DS_WAIT:
			if (mi_wack & mi_wlast)
				dma_state_nxt = DS_IDLE;
		endcase
	end

	// MemIF commands
	assign mi_addr  = dma_addr;
	assign mi_len   = (BURST_LEN - 1);
	assign mi_rw    = 1'b0;
	assign mi_valid = (dma_state == DS_CMD);

	// MemIF data from FIFO
	assign mi_wdata = fr_data;
	assign fr_ena   = mi_wack;

endmodule // spi_dev_memwr
