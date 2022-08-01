/*
 * top.v
 *
 * vim: ts=4 sw=4
 *
 * Top-level module for MCH2022 PSRAM loader
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module top (
	// IRQ
	output wire       irq_n,

	// SPI Slave (to ESP32)
	input  wire       spi_mosi,
	output wire       spi_miso,
	input  wire       spi_clk,
	input  wire       spi_cs_n,

	// PSRAM
	inout  wire [3:0] ram_io,
	output wire       ram_clk,
	output wire       ram_cs_n,

	// Clock
	input  wire       clk_in
);

	localparam integer WN = 2;
	genvar i;


	// Signals
	// -------

	// Wishbone
	wire   [23:0] wb_addr;
	wire   [31:0] wb_rdata [0:WN-1];
	wire   [31:0] wb_wdata;
	wire [WN-1:0] wb_cyc;
	wire          wb_we;
	wire [WN-1:0] wb_ack;

	wire [(32*WN)-1:0] wb_rdata_flat;

	// SPI interface
		// Raw core IF
	wire  [7:0] usr_mosi_data;
	wire        usr_mosi_stb;

	wire  [7:0] usr_miso_data;
	wire        usr_miso_ack;

	wire        csn_state;
	wire        csn_rise;
	wire        csn_fall;

		// Protocol IF
	wire  [7:0] pw_wdata;
	wire        pw_wcmd;
	wire        pw_wstb;

	wire        pw_end;

	wire        pw_req;
	wire        pw_gnt;

	wire  [7:0] pw_rdata;
	wire        pw_rstb;

	wire  [3:0] pw_irq;
	wire        irq;

	// Memory interface
	wire [22:0] mi_addr;
	wire [ 6:0] mi_len;
	wire        mi_rw;
	wire        mi_valid;
	wire        mi_ready;

	wire [15:0] mi_wdata;
	wire        mi_wack;
	wire        mi_wlast;

	wire [15:0] mi_rdata;
	wire        mi_rstb;
	wire        mi_rlast;

	// QPI PHY
	wire [15:0] qpi_phy_io_i;
	wire [15:0] qpi_phy_io_o;
	wire [ 3:0] qpi_phy_io_oe;
	wire [ 3:0] qpi_phy_clk_o;
	wire        qpi_phy_cs_o;

	// Clock / Reset
	wire        clk_1x;
	wire        clk_4x;
	wire        sync_4x;
	wire        rst;


	// SPI
	// ---

	// Device Core
	spi_dev_core core_I (
		.spi_miso      (spi_miso),
		.spi_mosi      (spi_mosi),
		.spi_clk       (spi_clk),
		.spi_cs_n      (spi_cs_n),
		.usr_mosi_data (usr_mosi_data),
		.usr_mosi_stb  (usr_mosi_stb),
		.usr_miso_data (usr_miso_data),
		.usr_miso_ack  (usr_miso_ack),
		.csn_state     (csn_state),
		.csn_rise      (csn_rise),
		.csn_fall      (csn_fall),
		.clk           (clk_1x),
		.rst           (rst)
	);

	// Protocol wrapper
	spi_dev_proto proto_I (
		.usr_mosi_data (usr_mosi_data),
		.usr_mosi_stb  (usr_mosi_stb),
		.usr_miso_data (usr_miso_data),
		.usr_miso_ack  (usr_miso_ack),
		.csn_state     (csn_state),
		.csn_rise      (csn_rise),
		.csn_fall      (csn_fall),
		.pw_wdata      (pw_wdata),
		.pw_wcmd       (pw_wcmd),
		.pw_wstb       (pw_wstb),
		.pw_end        (pw_end),
		.pw_req        (pw_req),
		.pw_gnt        (pw_gnt),
		.pw_rdata      (pw_rdata),
		.pw_rstb       (pw_rstb),
		.pw_irq        (pw_irq),
		.irq           (irq),
		.clk           (clk_1x),
		.rst           (rst)
	);

	// Wishbone bridge
	spi_dev_to_wb #(
		.WB_N(WN)
	) wb_I (
		.pw_wdata (pw_wdata),
		.pw_wcmd  (pw_wcmd),
		.pw_wstb  (pw_wstb),
		.pw_end   (pw_end),
		.pw_req   (pw_req),
		.pw_gnt   (pw_gnt),
		.pw_rdata (pw_rdata),
		.pw_rstb  (pw_rstb),
		.wb_wdata (wb_wdata),
		.wb_rdata (wb_rdata_flat),
		.wb_addr  (wb_addr),
		.wb_we    (wb_we),
		.wb_cyc   (wb_cyc),
		.wb_ack   (wb_ack),
		.clk      (clk_1x),
		.rst      (rst)
	);

	for (i=0; i<WN; i=i+1)
		assign wb_rdata_flat[i*32+:32] = wb_rdata[i];

	assign pw_irq = 4'b0000;

	assign irq_n = irq ? 1'b0 : 1'bz;


	// QSPI controller [0]
	// ---------------

	// Controller
	qpi_memctrl #(
		.CMD_READ   (8'hEB),
		.CMD_WRITE  (8'h02),
		.DUMMY_CLK  (6),
		.PAUSE_CLK  (8),
		.FIFO_DEPTH (1),
		.N_CS       (1),
		.DATA_WIDTH (16),
		.PHY_SPEED  (4),
		.PHY_WIDTH  (1),
		.PHY_DELAY  (4)
	) memctrl_I (
		.phy_io_i   (qpi_phy_io_i),
		.phy_io_o   (qpi_phy_io_o),
		.phy_io_oe  (qpi_phy_io_oe),
		.phy_clk_o  (qpi_phy_clk_o),
		.phy_cs_o   (qpi_phy_cs_o),
		.mi_addr_cs (2'b00),
		.mi_addr    ({mi_addr, 1'b0 }),	/* 16 bits aligned */
		.mi_len     (mi_len),
		.mi_rw      (mi_rw),
		.mi_valid   (mi_valid),
		.mi_ready   (mi_ready),
		.mi_wdata   (mi_wdata),
		.mi_wack    (mi_wack),
		.mi_wlast   (mi_wlast),
		.mi_rdata   (mi_rdata),
		.mi_rstb    (mi_rstb),
		.mi_rlast   (mi_rlast),
		.wb_wdata   (wb_wdata),
		.wb_rdata   (wb_rdata[0]),
		.wb_addr    (wb_addr[4:0]),
		.wb_we      (wb_we),
		.wb_cyc     (wb_cyc[0]),
		.wb_ack     (wb_ack[0]),
		.clk        (clk_1x),
		.rst        (rst)
	);

	// PHY
	qpi_phy_ice40_4x #(
		.N_CS     (1),
		.WITH_CLK (1),
	) phy_I (
		.pad_io    (ram_io),
		.pad_clk   (ram_clk),
		.pad_cs_n  (ram_cs_n),
		.phy_io_i  (qpi_phy_io_i),
		.phy_io_o  (qpi_phy_io_o),
		.phy_io_oe (qpi_phy_io_oe),
		.phy_clk_o (qpi_phy_clk_o),
		.phy_cs_o  (qpi_phy_cs_o),
		.clk_1x    (clk_1x),
		.clk_4x    (clk_4x),
		.clk_sync  (sync_4x)
	);


	// SPI memory writer [1]
	// -----------------

	spi_dev_memwr #(
		.CMD_BYTE(8'he0),
		.DATA_WIDTH(16),
		.ADDR_WIDTH(23)
	) memwr_I (
		.pw_wdata (pw_wdata),
		.pw_wcmd  (pw_wcmd),
		.pw_wstb  (pw_wstb),
		.pw_end   (pw_end),
		.mi_addr  (mi_addr),
		.mi_len   (mi_len),
		.mi_rw    (mi_rw),
		.mi_valid (mi_valid),
		.mi_ready (mi_ready),
		.mi_wdata (mi_wdata),
		.mi_wack  (mi_wack),
		.mi_wlast (mi_wlast),
		.mi_rdata (mi_rdata),
		.mi_rstb  (mi_rstb),
		.mi_rlast (mi_rlast),
		.wb_wdata (wb_wdata),
		.wb_rdata (wb_rdata[1]),
		.wb_addr  (wb_addr[1:0]),
		.wb_we    (wb_we),
		.wb_cyc   (wb_cyc[1]),
		.wb_ack   (wb_ack[1]),
		.clk      (clk_1x),
		.rst      (rst)
	);


	// Clock/Reset Generation
	// ----------------------

	sysmgr sysmgr_I (
		.clk_in  (clk_in),
		.clk_1x  (clk_1x),
		.clk_4x  (clk_4x),
		.sync_4x (sync_4x),
		.rst     (rst)
	);

endmodule // top
