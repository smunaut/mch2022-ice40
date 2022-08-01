/*
 * gpu_tb.v
 *
 * vim: ts=4 sw=4
 *
 * Test bench for the LCD modules
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module gpu_tb;

	// Signals
	// -------

	// PSRAM
	wire  [3:0] ram_io;
	wire        ram_clk;
	wire        ram_cs_n;

	// GPU
		// Command FIFO
	reg  [63:0] gpu_cf_wdata;
	reg         gpu_cf_wen;
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
	reg         clk_2x = 1'b1;
	reg         clk_1x = 1'b1;
	reg         rst = 1'b1;


	// Setup recording
	// ---------------

	initial begin
		$dumpfile("gpu_tb.vcd");
		$dumpvars(0,gpu_tb);
		# 200000 $finish;
	end


	// Clock / Reset
	// -------------

	initial begin
		# 200 rst = 0;
	end

	always #10 clk_1x = !clk_1x;
	always  #5 clk_2x = !clk_2x;


	// DUTs
	// ----

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
		.cmd_data  (gpu_cmd_valid ? gpu_cmd_data : 64'h00000000),
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

	pullup(ram_io[0]);
	pullup(ram_io[1]);
	pullup(ram_io[2]);
	pullup(ram_io[3]);

	wire [7:0] lcd_d;
	wire       lcd_rs;
	wire       lcd_wr_n;
	wire       lcd_cs_n;
	wire       lcd_mode = 1'b1;
	wire       lcd_rst_n;
	wire       lcd_fmark = 1'b0;

	lcd_top lcd_I (
		.lcd_d     (lcd_d),
		.lcd_rs    (lcd_rs),
		.lcd_wr_n  (lcd_wr_n),
		.lcd_cs_n  (lcd_cs_n),
		.lcd_mode  (lcd_mode),
		.lcd_rst_n (lcd_rst_n),
		.lcd_fmark (lcd_fmark),
		.pw_wdata  (8'hxx),
		.pw_wcmd   (1'bx),
		.pw_wstb   (1'b0),
		.pw_end    (1'b0),
		.gpu_data  (gpu_lcd_data),
		.gpu_valid (gpu_lcd_valid),
		.gpu_ready (gpu_lcd_ready),
		.clk       (clk_1x),
		.rst       (rst)
	);



	// Commands
	// --------

	task cmd_write;
		input [63:0] data;
		begin

			gpu_cf_wdata <= data;
			gpu_cf_wen   <= 1'b1;

			@(posedge clk_1x);

			gpu_cf_wdata <= 64'hxxxxxxxxxxxxxxxx;
			gpu_cf_wen   <= 1'b0;

			@(posedge clk_1x);

		end
	endtask

	initial begin
		// Defaults
		gpu_cf_wdata <= 64'hxxxxxxxxxxxxxxxx;
		gpu_cf_wen   <= 1'b0;

		// Wait for reset
		@(negedge rst);
		@(posedge clk_1x);

		// Issue commands
		repeat (20)
			@(posedge clk_1x);

		cmd_write(64'h4321bad0c0000000);
		cmd_write(64'h80000100de45850e);
		cmd_write(64'h0000ffff3fbc0000);
		cmd_write(64'h78000beb3e256447);
		cmd_write(64'h001100197e8e2487);
		cmd_write(64'hffb2002f7d64a89d);
		cmd_write(64'h100004c23efa8c4d);
		cmd_write(64'h106704c23ca80047);
		cmd_write(64'h004600297fc2f8a6);
		cmd_write(64'h00000000c0000001);
		cmd_write(64'h80000100de460504);
		cmd_write(64'h0000ffff3fbc0000);
		cmd_write(64'h7a000bed3e256447);
		cmd_write(64'h001100197e8e2487);
		cmd_write(64'hffb2002f7d64a89d);
		cmd_write(64'h110004c13efa8c4d);
		cmd_write(64'h116704c13ca80047);
		cmd_write(64'h004600297fc2f8a6);
		cmd_write(64'h00000000c0000001);
		cmd_write(64'h80000100de4684fc);
		cmd_write(64'h0000ffff3fbc0000);
		cmd_write(64'h7b000bf03e256447);
		cmd_write(64'h001100197e8e2487);
		cmd_write(64'hffb2002f7d64a89d);
		cmd_write(64'h120004c03efa8c4d);
		cmd_write(64'h126704c03ca80047);
		cmd_write(64'h004600297fc2f8a6);
		cmd_write(64'h00000000c0000001);
		cmd_write(64'h80000100de4704f2);
		cmd_write(64'h0000ffff3fbc0000);
		cmd_write(64'h7d000bf23e256447);
		cmd_write(64'h001100197e8e2487);

	end

endmodule // gpu_tb
