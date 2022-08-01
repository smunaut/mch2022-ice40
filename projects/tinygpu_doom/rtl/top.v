/*
 * top.v
 *
 * vim: ts=4 sw=4
 *
 * Top-level module for MCH2022 SPI skeleton
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module top (
	// UART (to RP2040)
	output wire       uart_tx,
	input  wire       uart_rx,

	// IRQ (to ESP32)
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

	// LCD
	output wire [7:0] lcd_d,
	output wire       lcd_rs,
	output wire       lcd_wr_n,
	output wire       lcd_cs_n,
	output wire       lcd_mode,
	output wire       lcd_rst_n,
	input  wire       lcd_fmark,

	// PMOD
	inout  wire [7:0] pmod,

	// RGB Leds
	output wire [2:0] rgb,

	// Clock
	input  wire       clk_in
);

	localparam integer WN = 2;
	genvar i;


	// Signals
	// -------

	// SPI interface
		// Raw core IF
	wire [7:0] usr_mosi_data;
	wire       usr_mosi_stb;
	wire [7:0] usr_miso_data;
	wire       usr_miso_ack;

	wire       csn_state;
	wire       csn_rise;
	wire       csn_fall;

		// Protocol IF
	wire [7:0] pw_wdata;
	wire       pw_wcmd;
	wire       pw_wstb;

	wire       pw_end;

	wire       pw_req;
	wire       pw_gnt;

	wire [7:0] pw_rdata;
	wire       pw_rstb;

	wire [3:0] pw_irq;
	wire       irq;

	// Wishbone
	wire   [23:0] wb_addr;
	wire   [31:0] wb_rdata [0:WN-1];
	wire   [31:0] wb_wdata;
	wire [WN-1:0] wb_cyc;
	wire          wb_we;
	wire [WN-1:0] wb_ack;

	wire [(32*WN)-1:0] wb_rdata_flat;

	// GPU
		// Command FIFO
	wire [63:0] gpu_cf_wdata;
	wire        gpu_cf_wen;
	wire        gpu_cf_full;
	wire [63:0] gpu_cf_rdata;
	wire        gpu_cf_ren;
	wire        gpu_cf_empty;

		// Command port
	wire [63:0] gpu_cmd_data;
	wire        gpu_cmd_valid;
	wire        gpu_cmd_ready;

		// LCD
	wire [15:0] gpu_lcd_data;
	wire        gpu_lcd_valid;
	wire        gpu_lcd_ready;

	// Clock / Reset
	wire        clk_1x;
	wire        clk_2x;
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

	// Command decoder for the E2 command
	spi_dev_scmd #(
		.CMD_BYTE   (8'he2),
		.CMD_LEN    (8),
		.CMD_REPEAT (1)
	) scmd_e2_I (
		.pw_wdata (pw_wdata),
		.pw_wcmd  (pw_wcmd),
		.pw_wstb  (pw_wstb),
		.pw_end   (pw_end),
		.cmd_data (gpu_cf_wdata),
		.cmd_stb  (gpu_cf_wen),
		.clk      (clk_1x),
		.rst      (rst)
	);


	// GPU
	// ---

	// FIFO
	fifo_sync_ram #(
		.DEPTH(256),
		.WIDTH(64)
	) cmd_fifo_I (
		.wr_data  (gpu_cf_wdata),
		.wr_ena   (gpu_cf_wen),
		.wr_full  (gpu_cf_full),
		.rd_data  (gpu_cf_rdata),
		.rd_ena   (gpu_cf_ren),
		.rd_empty (gpu_cf_empty),
		.clk      (clk_1x),
		.rst      (rst)
	);

	assign gpu_cmd_data  =  gpu_cf_rdata;
	assign gpu_cmd_valid = ~gpu_cf_empty;
	assign gpu_cf_ren    = ~gpu_cf_empty & gpu_cmd_ready;

	// Core
	gpu gpu_I (
		.cmd_data  (gpu_cmd_data),
		.cmd_valid (gpu_cmd_valid),
		.cmd_ready (gpu_cmd_ready),
		.lcd_data  (gpu_lcd_data),
		.lcd_valid (gpu_lcd_valid),
		.lcd_ready (gpu_lcd_ready),
		.ram_io    (ram_io),
		.ram_clk   (ram_clk),
		.ram_cs_n  (ram_cs_n),
		.clk_1x    (clk_1x),
		.clk_2x    (clk_2x),
		.rst       (rst)
	);


	// LCD
	// ---

	lcd_top lcd_I (
		.lcd_d     (lcd_d),
		.lcd_rs    (lcd_rs),
		.lcd_wr_n  (lcd_wr_n),
		.lcd_cs_n  (lcd_cs_n),
		.lcd_mode  (lcd_mode),
		.lcd_rst_n (lcd_rst_n),
		.lcd_fmark (lcd_fmark),
		.pw_wdata  (pw_wdata),
		.pw_wcmd   (pw_wcmd),
		.pw_wstb   (pw_wstb),
		.pw_end    (pw_end),
		.gpu_data  (gpu_lcd_data),
		.gpu_valid (gpu_lcd_valid),
		.gpu_ready (gpu_lcd_ready),
		.clk       (clk_1x),
		.rst       (rst)
	);


	// Debug
	// -----

	SB_RGBA_DRV #(
		.CURRENT_MODE("0b1"),       // half current
		.RGB0_CURRENT("0b000011"),  // 4 mA
		.RGB1_CURRENT("0b000011"),  // 4 mA
		.RGB2_CURRENT("0b000011")   // 4 mA
	) RGBA_DRIVER (
		.CURREN   (1'b1),
		.RGBLEDEN (1'b1),
		.RGB0PWM  (gpu_lcd_valid),
		.RGB1PWM  (gpu_lcd_ready),
		.RGB2PWM  (1'b0),
		.RGB0     (rgb[0]),
		.RGB1     (rgb[1]),
		.RGB2     (rgb[2])
	);


	// Clock/Reset Generation
	// ----------------------

	sysmgr sysmgr_I (
		.clk_in (clk_in),
		.clk_1x (clk_1x),
		.clk_2x (clk_2x),
		.rst    (rst)
	);

endmodule // top
