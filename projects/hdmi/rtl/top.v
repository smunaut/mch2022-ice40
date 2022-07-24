/*
 * top.v
 *
 * vim: ts=4 sw=4
 *
 * Top-level module for MCH2022 HDMI screen mirror demo
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module top (
	// SPI Slave (to ESP32)
	input  wire       spi_mosi,
	output wire       spi_miso,
	input  wire       spi_clk,
	input  wire       spi_cs_n,

	// PSRAM
	inout  wire [3:0] ram_io,
	output wire       ram_clk,
	output wire       ram_cs_n,

	// LCD
	output wire [7:0] lcd_d,
	output wire       lcd_rs,
	output wire       lcd_wr_n,
	output wire       lcd_cs_n,
	input  wire       lcd_mode,
	output wire       lcd_rst_n,
	input  wire       lcd_fmark,

	// PMOD
	inout  wire [7:0] pmod,

	// IRQ
	output wire       irq_n,

	// Clock
	input  wire       clk_in
);

	localparam integer WN = 4;
	genvar i;


	// Signals
	// -------

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

	// Wishbone
	wire   [23:0] wb_addr;
	wire   [31:0] wb_rdata [0:WN-1];
	wire   [31:0] wb_wdata;
	wire    [3:0] wb_wmsk;
	wire [WN-1:0] wb_cyc;
	wire          wb_we;
	wire [WN-1:0] wb_ack;

	wire [(32*WN)-1:0] wb_rdata_flat;

	// Memory interface
		// Upstream to memcontroller
	wire [31:0] mu_addr;
	wire [ 6:0] mu_len;
	wire        mu_rw;
	wire        mu_valid;
	wire        mu_ready;

	wire [15:0] mu_wdata;
	wire        mu_wack;
	wire        mu_wlast;

	wire [15:0] mu_rdata;
	wire        mu_rstb;
	wire        mu_rlast;

		// Downstream 0 to HDMI reader
	wire [31:0] m0_addr;
	wire [ 6:0] m0_len;
	wire        m0_rw;
	wire        m0_valid;
	wire        m0_ready;

	wire [15:0] m0_wdata;
	wire        m0_wack;
	wire        m0_wlast;

	wire [15:0] m0_rdata;
	wire        m0_rstb;
	wire        m0_rlast;

		// Downstream 1 to SPI writer
	wire [31:0] m1_addr;
	wire [ 6:0] m1_len;
	wire        m1_rw;
	wire        m1_valid;
	wire        m1_ready;

	wire [15:0] m1_wdata;
	wire        m1_wack;
	wire        m1_wlast;

	wire [15:0] m1_rdata;
	wire        m1_rstb;
	wire        m1_rlast;

	// QPI PHY
	wire [15:0] qpi_phy_io_i;
	wire [15:0] qpi_phy_io_o;
	wire [ 3:0] qpi_phy_io_oe;
	wire [ 3:0] qpi_phy_clk_o;
	wire        qpi_phy_cs_o;

	// Clock / Reset
	wire        clk_pix; // 1:5 of clk_4x
	wire        clk_1x;
	wire        clk_4x;
	wire        sync_4x;
	wire        rst;


	// SPI interface
	// -------------

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
	spi_dev_proto #(
		.NO_RESP(0)
	) proto_I (
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

	// IRQ handling
	assign pw_irq = 4'b0000;
	assign irq_n = irq ? 1'b0 : 1'bz;


	// QSPI controller [0]
	// ---------------

	// Arbiter
	memif_arb #(
		.AW(32),
		.DW(16),
		.WRITE_DISABLE(2'b01)
	) memarb_I (
		.u_addr   (mu_addr),
		.u_len    (mu_len),
		.u_rw     (mu_rw),
		.u_valid  (mu_valid),
		.u_ready  (mu_ready),
		.u_wdata  (mu_wdata),
		.u_wack   (mu_wack),
		.u_wlast  (mu_wlast),
		.u_rdata  (mu_rdata),
		.u_rstb   (mu_rstb ),
		.u_rlast  (mu_rlast),
		.d0_addr  (m0_addr),
		.d0_len   (m0_len),
		.d0_rw    (m0_rw),
		.d0_valid (m0_valid),
		.d0_ready (m0_ready),
		.d0_wdata (m0_wdata),
		.d0_wack  (m0_wack),
		.d0_wlast (m0_wlast),
		.d0_rdata (m0_rdata),
		.d0_rstb  (m0_rstb ),
		.d0_rlast (m0_rlast),
		.d1_addr  (m1_addr),
		.d1_len   (m1_len),
		.d1_rw    (m1_rw),
		.d1_valid (m1_valid),
		.d1_ready (m1_ready),
		.d1_wdata (m1_wdata),
		.d1_wack  (m1_wack),
		.d1_wlast (m1_wlast),
		.d1_rdata (m1_rdata),
		.d1_rstb  (m1_rstb ),
		.d1_rlast (m1_rlast),
		.clk      (clk_1x),
		.rst      (rst)
	);

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
		.mi_addr    ({mu_addr[22:0], 1'b0 }),	/* 16 bits aligned */
		.mi_len     (mu_len),
		.mi_rw      (mu_rw),
		.mi_valid   (mu_valid),
		.mi_ready   (mu_ready),
		.mi_wdata   (mu_wdata),
		.mi_wack    (mu_wack),
		.mi_wlast   (mu_wlast),
		.mi_rdata   (mu_rdata),
		.mi_rstb    (mu_rstb),
		.mi_rlast   (mu_rlast),
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
	) memphy_I (
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


	// HDMI [1]
	// ----

	hdmi_top hdmi_I (
		.hdmi_p     ({pmod[3], pmod[0], pmod[1], pmod[2]}),
		.hdmi_n     ({pmod[7], pmod[4], pmod[5], pmod[6]}),
		.mi_addr    (m0_addr),
		.mi_len     (m0_len),
		.mi_rw      (m0_rw),
		.mi_valid   (m0_valid),
		.mi_ready   (m0_ready),
		.mi_wdata   (m0_wdata),
		.mi_wack    (m0_wack),
		.mi_wlast   (m0_wlast),
		.mi_rdata   (m0_rdata),
		.mi_rstb    (m0_rstb),
		.mi_rlast   (m0_rlast),
		.wb_wdata   (wb_wdata),
		.wb_rdata   (wb_rdata[1]),
		.wb_addr    (wb_addr[1:0]),
		.wb_we      (wb_we),
		.wb_cyc     (wb_cyc[1]),
		.wb_ack     (wb_ack[1]),
		.clk_pix    (clk_pix),
		.clk_tmds   (clk_4x),
		.clk        (clk_1x),
		.rst        (rst)
	);


	// SPI memory writer [2]
	// -----------------

	spi_dev_memwr memwr_I (
		.pw_wdata (pw_wdata),
		.pw_wcmd  (pw_wcmd),
		.pw_wstb  (pw_wstb),
		.pw_end   (pw_end),
		.mi_addr  (m1_addr),
		.mi_len   (m1_len),
		.mi_rw    (m1_rw),
		.mi_valid (m1_valid),
		.mi_ready (m1_ready),
		.mi_wdata (m1_wdata),
		.mi_wack  (m1_wack),
		.mi_wlast (m1_wlast),
		.mi_rdata (m1_rdata),
		.mi_rstb  (m1_rstb),
		.mi_rlast (m1_rlast),
		.wb_wdata (wb_wdata),
		.wb_rdata (wb_rdata[2]),
		.wb_addr  (wb_addr[1:0]),
		.wb_we    (wb_we),
		.wb_cyc   (wb_cyc[2]),
		.wb_ack   (wb_ack[2]),
		.clk      (clk_1x),
		.rst      (rst)
	);


	// LCD [3]
	// ---

	lcd_top lcd_I (
		.lcd_d     (lcd_d),
		.lcd_rs    (lcd_rs),
		.lcd_wr_n  (lcd_wr_n),
		.lcd_cs_n  (lcd_cs_n),
		.lcd_mode  (lcd_mode),
		.lcd_rst_n (lcd_rst_n),
		.lcd_fmark (lcd_fmark),
		.wb_wdata  (wb_wdata),
		.wb_rdata  (wb_rdata[3]),
		.wb_addr   (wb_addr[1:0]),
		.wb_we     (wb_we),
		.wb_cyc    (wb_cyc[3]),
		.wb_ack    (wb_ack[3]),
		.clk       (clk_1x),
		.rst       (rst)
	);


	// Clock/Reset Generation
	// ----------------------

	sysmgr sysmgr_I (
		.clk_in  (clk_in),
		.clk_pix (clk_pix),
		.clk_1x  (clk_1x),
		.clk_4x  (clk_4x),
		.sync_4x (sync_4x),
		.rst     (rst)
	);

endmodule // top
