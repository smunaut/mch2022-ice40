/*
 * gpu.v
 *
 * Copyright (C) 2022  Sylvain Munaut <tnt@246tNt.com>
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 */

`default_nettype none

module gpu (
	// Data
	input  wire [63:0] cmd_data,
	input  wire        cmd_valid,
	output wire        cmd_ready,

	// LCD
	output wire [15:0] lcd_data,
	output wire        lcd_valid,
	input  wire        lcd_ready,

	// PSRAM
	inout  wire  [3:0] ram_io,
	output wire        ram_clk,
	output wire        ram_cs_n,

	// Clock / Reset
	input  wire clk_1x,
	input  wire clk_2x,
	input  wire rst
);

	M_DMC_1_gpu_standalone dmc1_I (
		.in_run           (1'b0),
		.out_done         (),
		.in_command       (cmd_data),
		.in_valid         (cmd_valid),
		.out_ready        (cmd_ready),
		.out_screen_data  (lcd_data),
		.out_screen_valid (lcd_valid),
		.in_screen_ready  (lcd_ready),
		.inout_ram_io0    (ram_io[0]),
		.inout_ram_io1    (ram_io[1]),
		.inout_ram_io2    (ram_io[2]),
		.inout_ram_io3    (ram_io[3]),
		.out_ram_clk      (ram_clk),
		.out_ram_csn      (ram_cs_n),
		.in_clock2x       (clk_2x),
		.clock            (clk_1x),
		.reset            (rst)
	);

endmodule // gpu
