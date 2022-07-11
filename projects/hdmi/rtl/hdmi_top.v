/*
 * hdmi_top.v
 *
 * vim: ts=4 sw=4
 *
 * HDMI top level
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module hdmi_top (
	// PADs
	output wire  [3:0] hdmi_p,
	output wire  [3:0] hdmi_n,

	// Memory interface
	output wire [31:0] mi_addr,
	output wire [ 6:0] mi_len,
	output wire        mi_rw,
	output wire        mi_valid,
	input  wire        mi_ready,

	output wire [15:0] mi_wdata,    // Not used
	input  wire        mi_wack,     // Not used
	input  wire        mi_wlast,    // Not used

	input  wire [15:0] mi_rdata,
	input  wire        mi_rstb,
	input  wire        mi_rlast,

	// Wishbone interface
	input  wire [31:0] wb_wdata,
	output wire [31:0] wb_rdata,
	input  wire [ 1:0] wb_addr,
	input  wire        wb_we,
	input  wire        wb_cyc,
	output reg         wb_ack,

	// Clock / Reset
	input  wire clk_pix,
	input  wire clk_tmds,
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	// Bus
	wire        bus_clr;
	reg         bus_we_csr;
	reg         bus_we_base;
	reg         bus_we_tmg;

	// DMA config
	reg  [22:0] dma_cfg_base;
	reg  [ 6:0] dma_cfg_bn_cnt;
	reg  [ 6:0] dma_cfg_bn_len;
	reg  [ 6:0] dma_cfg_bl_len;
	reg  [ 7:0] dma_cfg_bl_inc;

	reg         dma_run;

	// DMA runtime
	reg  [22:0] dma_addr;
	reg  [ 7:0] dma_cnt;
	reg         dma_last;
	wire        dma_valid;

	// Line buffers
	reg  [ 9:0] buf_waddr;
	wire [15:0] buf_wdata;
	wire        buf_wren;
	wire [ 9:0] buf_raddr;
	wire [15:0] buf_rdata;

	// Line requests
	reg         lreq_first;
	wire        lreq_stb_pix;
	wire        lreq_stb_sys;

	// Timing gen
	wire        tg_hsync_0;
	wire        tg_vsync_0;
	wire        tg_active_0;
	wire        tg_h_first_0;
	wire        tg_h_last_0;
	wire        tg_v_first_0;
	wire        tg_v_last_0;

	reg         tg_vsync_1;
	wire        tg_vsync_stb_0;

	// Pixels
	reg         px_line_1;
	reg         px_buf_sel_1;
	reg   [9:0] px_buf_addr_1;

	wire  [7:0] px_data_r_2;
	wire  [7:0] px_data_g_2;
	wire  [7:0] px_data_b_2;

	wire        px_hsync_2;
	wire        px_vsync_2;
	wire        px_active_2;

	// Pixel-clock domain reset
	reg         rst_pix_i;
	wire        rst_pix;


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
			bus_we_tmg  <= 1'b0;
		end else begin
			bus_we_csr  <= wb_we & (wb_addr == 2'b00);
			bus_we_base <= wb_we & (wb_addr == 2'b01);
			bus_we_tmg  <= wb_we & (wb_addr == 2'b10);
		end

	// Register Write
	always @(posedge clk or posedge rst)
		if (rst)
			dma_run <= 1'b0;
		else if (bus_we_csr)
			dma_run <= wb_wdata[0];

	always @(posedge clk or posedge rst)
		if (rst)
			dma_cfg_base <= 0;
		else if (bus_we_base)
			dma_cfg_base <= wb_wdata[22:0];

	always @(posedge clk or posedge rst)
		if (rst) begin
			dma_cfg_bn_cnt <= 4;
			dma_cfg_bn_len <= 63;
			dma_cfg_bl_len <= 63;
			dma_cfg_bl_inc <= 63;
		end else if (bus_we_tmg) begin
			dma_cfg_bn_cnt <= wb_wdata[30:24];
			dma_cfg_bn_len <= wb_wdata[22:16];
			dma_cfg_bl_len <= wb_wdata[14: 8];
			dma_cfg_bl_inc <= wb_wdata[ 7: 0];
		end

	// No read support
	assign wb_rdata = 32'h00000000;


	// DMA
	// ---

	// DMA requests
	always @(posedge clk)
	begin
		if (~dma_run)
			dma_cnt <= 8'h00;
		else if (lreq_stb_sys)
			dma_cnt <= { 1'b1, dma_cfg_bn_cnt };
		else if (mi_ready & mi_valid)
			dma_cnt <= dma_cnt - 1;
	end

	always @(posedge clk)
		if (lreq_stb_sys)
			dma_last <= (dma_cfg_bn_cnt[6:0] == 6'h00);
		else if (mi_ready & mi_valid)
			dma_last <= (dma_cnt[6:0] == 6'h01);

	assign dma_valid = dma_cnt[7];

	always @(posedge clk)
		if (lreq_stb_sys & lreq_first)
			dma_addr <= dma_cfg_base;
		else if (mi_ready & mi_valid)
			dma_addr <= dma_addr + (dma_last ? dma_cfg_bl_inc : dma_cfg_bn_len) + 1;

	// DMA Memory interface
	assign mi_addr  = dma_addr;
	assign mi_len   = dma_last ? dma_cfg_bl_len : dma_cfg_bn_len;
	assign mi_rw    = 1'b1;
	assign mi_valid = dma_valid;

	assign mi_wdata = 16'h0000;

	// Buffer write path
	always @(posedge clk)
		buf_waddr[9] <= (buf_waddr[9] ^ lreq_stb_sys) & ~(lreq_stb_sys & lreq_first);

	always @(posedge clk)
		if (lreq_stb_sys)
			buf_waddr[8:0] <= 8'h00;
		else
			buf_waddr[8:0] <= buf_waddr[8:0] + mi_rstb;

	assign buf_wdata = mi_rdata;
	assign buf_wren  = mi_rstb;


	// Line cross-clock
	// ----------------

	// Buffer
	hdmi_buf buf_I (
		.waddr (buf_waddr),
		.wdata (buf_wdata),
		.wren  (buf_wren),
		.wclk  (clk),
		.raddr (buf_raddr),
		.rdata (buf_rdata),
		.rclk  (clk_pix)
	);

	// Requests
	xclk_strobe xclk_lr (
		.in_stb  (lreq_stb_pix),
		.in_clk  (clk_pix),
		.out_stb (lreq_stb_sys),
		.out_clk (clk),
		.rst     (rst)
	);


	// Timing generator
	// ----------------

	// Core
	hdmi_tgen #(
		.H_WIDTH  (  10 ),
		.H_FP     (  16 ),
		.H_SYNC   (  96 ),
		.H_BP     (  48 ),
		.H_ACTIVE ( 640 ),
		.V_WIDTH  (   9 ),
		.V_FP     (  10 ),
		.V_SYNC   (   2 ),
		.V_BP     (  33 ),
		.V_ACTIVE ( 480 )
	) tgen_I (
		.vid_hsync   (tg_hsync_0),
		.vid_vsync   (tg_vsync_0),
		.vid_active  (tg_active_0),
		.vid_h_first (tg_h_first_0),
		.vid_h_last  (tg_h_last_0),
		.vid_v_first (tg_v_first_0),
		.vid_v_last  (tg_v_last_0),
		.clk         (clk_pix),
		.rst         (rst_pix)
	);

	// Detect vsync rising edge
	always @(posedge clk_pix)
		tg_vsync_1 <= tg_vsync_0;

	assign tg_vsync_stb_0 = tg_vsync_0 & ~tg_vsync_1;


	// Pixel pipeline
	// --------------

	wire px_h_first_0;

	assign px_h_first_0 = tg_h_first_0 & tg_active_0;

	// Line toggle (to double each lines)
	always @(posedge clk_pix)
		px_line_1 <= (px_line_1 ^ px_h_first_0) & ~tg_vsync_stb_0;

	// Line requests
	always @(posedge clk_pix)
		lreq_first <= (lreq_first | tg_vsync_stb_0) & ~px_h_first_0;

	assign lreq_stb_pix = tg_vsync_stb_0 | (px_h_first_0 & ~px_line_1);

	// Buffer ping-pong
	always @(posedge clk_pix)
		px_buf_sel_1 <= (px_buf_sel_1 ^ (px_h_first_0 & ~px_line_1)) | tg_vsync_stb_0;

	// Address counter
	always @(posedge clk_pix)
		if (tg_h_first_0)
			px_buf_addr_1 <= 0;
		else
			px_buf_addr_1 <= px_buf_addr_1 + tg_active_0;

	// Address mapping
	assign buf_raddr = { px_buf_sel_1, px_buf_addr_1[9:1] };

	// Data mapping
	assign px_data_r_2 = { buf_rdata[15:11], buf_rdata[15:13] };
	assign px_data_g_2 = { buf_rdata[10: 5], buf_rdata[10: 9] };
	assign px_data_b_2 = { buf_rdata[ 4: 0], buf_rdata[ 4: 2] };

	// Delay syncs
	delay_bus #(2, 3) dly_sync_I (
		.d   ({tg_hsync_0, tg_vsync_0, tg_active_0}),
		.q   ({px_hsync_2, px_vsync_2, px_active_2}),
		.clk (clk_pix)
	);


	// PHY
	// ---

	hdmi_phy phy_I (
		.hdmi_p   (hdmi_p),
		.hdmi_n   (hdmi_n),
		.in_r     (px_data_r_2),
		.in_g     (px_data_g_2),
		.in_b     (px_data_b_2),
		.in_hsync (px_hsync_2),
		.in_vsync (px_vsync_2),
		.in_de    (px_active_2),
		.clk_tmds (clk_tmds),
		.clk_pix  (clk_pix),
		.rst_pix  (rst_pix)
	);


	// Reset
	// -----

	always @(posedge clk_pix or posedge rst)
		if (rst)
			rst_pix_i <= 1'b1;
		else
			rst_pix_i <= 1'b0;

	SB_GB rst_gbuf_I (
		.USER_SIGNAL_TO_GLOBAL_BUFFER (rst_pix_i),
		.GLOBAL_BUFFER_OUTPUT         (rst_pix)
	);

endmodule // hdmi_top
