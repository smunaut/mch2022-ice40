`define ICE40 1
`define MCH2022 1
/*
[Bare framework] Leave empty, this is used when exporting to verilog
*/

// SL 2021-12-12
// produces an inverted clock of same frequency through DDR primitives
module ddr_clock(
        input  clock,
        input  enable,
`ifdef ICARUS
        output reg ddr_clock
`else
        output ddr_clock
`endif
    );

`ifdef ICARUS
  reg renable;
  always @(posedge clock) begin
    ddr_clock <= 0;
    renable   <= enable;
  end
  always @(negedge clock) begin
    ddr_clock <= renable;
  end
`endif

`ifdef ICE40
  SB_IO #(
    .PIN_TYPE(6'b1100_11)
  ) sbio_clk (
      .PACKAGE_PIN(ddr_clock),
      .D_OUT_0(1'b0),
      .D_OUT_1(1'b1),
      .OUTPUT_ENABLE(enable),
      .OUTPUT_CLK(clock)
  );
`endif

endmodule


module sb_io_inout(
  input        clock,
	input        oe,
  input        out,
	output       in,
  inout        pin
  );

  SB_IO #(
    // .PIN_TYPE(6'b1010_00) // not registered
    .PIN_TYPE(6'b1101_00) // registered
  ) sbio (
      .PACKAGE_PIN(pin),
			.OUTPUT_ENABLE(oe),
      .D_OUT_0(out),
      //.D_OUT_1(out),
			.D_IN_1(in),
      .OUTPUT_CLK(clock),
      .INPUT_CLK(clock)
  );

endmodule

// http://www.latticesemi.com/~/media/LatticeSemi/Documents/TechnicalBriefs/SBTICETechnologyLibrary201504.pdf


module sb_io(
  input        clock,
  input        out,
  output       pin
  );

  SB_IO #(
    .PIN_TYPE(6'b0101_00)
    //                ^^ ignored (input)
    //           ^^^^ registered output
  ) sbio (
      .PACKAGE_PIN(pin),
      .D_OUT_0(out),
      .OUTPUT_CLK(clock)
  );

endmodule

// http://www.latticesemi.com/~/media/LatticeSemi/Documents/TechnicalBriefs/SBTICETechnologyLibrary201504.pdf


module M_qpsram_qspi__txm_spi (
in_send,
in_trigger,
in_send_else_read,
out_read,
out_clk,
out_csn,
inout_io0,
inout_io1,
inout_io2,
inout_io3,
reset,
out_clock,
clock
);
input  [7:0] in_send;
input  [0:0] in_trigger;
input  [0:0] in_send_else_read;
output  [7:0] out_read;
output  [0:0] out_clk;
output  [0:0] out_csn;
inout  [0:0] inout_io0;
inout  [0:0] inout_io1;
inout  [0:0] inout_io2;
inout  [0:0] inout_io3;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
wire  [0:0] _w_ddr_clock_unnamed_1_ddr_clock;
wire  [0:0] _w_sb_io0_in;
wire  [0:0] _w_sb_io1_in;
wire  [0:0] _w_sb_io2_in;
wire  [0:0] _w_sb_io3_in;
wire  [0:0] _w_sb_csn_pin;
reg  [3:0] _t_io_oe;
reg  [3:0] _t_io_o;
wire  [0:0] _w_nenable;

reg  [7:0] _d_sending = 0;
reg  [7:0] _q_sending = 0;
reg  [0:0] _d_osc = 0;
reg  [0:0] _q_osc = 0;
reg  [0:0] _d_enable = 0;
reg  [0:0] _q_enable = 0;
reg  [7:0] _d_read = 0;
reg  [7:0] _q_read = 0;
assign out_read = _q_read;
assign out_clk = _w_ddr_clock_unnamed_1_ddr_clock;
assign out_csn = _w_sb_csn_pin;
ddr_clock ddr_clock_unnamed_1 (
.clock(clock),
.enable(_q_enable),
.ddr_clock(_w_ddr_clock_unnamed_1_ddr_clock));
sb_io_inout sb_io0 (
.clock(clock),
.oe(_t_io_oe[0+:1]),
.out(_t_io_o[0+:1]),
.in(_w_sb_io0_in),
.pin(inout_io0));
sb_io_inout sb_io1 (
.clock(clock),
.oe(_t_io_oe[1+:1]),
.out(_t_io_o[1+:1]),
.in(_w_sb_io1_in),
.pin(inout_io1));
sb_io_inout sb_io2 (
.clock(clock),
.oe(_t_io_oe[2+:1]),
.out(_t_io_o[2+:1]),
.in(_w_sb_io2_in),
.pin(inout_io2));
sb_io_inout sb_io3 (
.clock(clock),
.oe(_t_io_oe[3+:1]),
.out(_t_io_o[3+:1]),
.in(_w_sb_io3_in),
.pin(inout_io3));
sb_io sb_csn (
.clock(clock),
.out(_w_nenable),
.pin(_w_sb_csn_pin));


assign _w_nenable = ~_q_enable;

`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_sending = _q_sending;
_d_osc = _q_osc;
_d_enable = _q_enable;
_d_read = _q_read;
// _always_pre
// __block_1
_t_io_oe = {4{in_send_else_read}};

_d_read = {_q_read[0+:4],{_w_sb_io3_in[0+:1],_w_sb_io2_in[0+:1],_w_sb_io1_in[0+:1],_w_sb_io0_in[0+:1]}};

_t_io_o = ~_q_osc ? _q_sending[0+:4]:_q_sending[4+:4];

_d_sending = (~_q_osc|~_q_enable) ? in_send:_q_sending;

_d_osc = ~in_trigger ? 1'b0:~_q_osc;

_d_enable = in_trigger;

// __block_2
// _always_post
end

always @(posedge clock) begin
_q_sending <= _d_sending;
_q_osc <= _d_osc;
_q_enable <= _d_enable;
_q_read <= _d_read;
end

endmodule


module M_qpsram_ram__txm (
in_in_ready,
in_addr,
in_wdata,
in_wenable,
out_rdata,
out_busy,
out_rdata_available,
out_ram_csn,
out_ram_clk,
inout_ram_io0,
inout_ram_io1,
inout_ram_io2,
inout_ram_io3,
reset,
out_clock,
clock
);
input  [0:0] in_in_ready;
input  [23:0] in_addr;
input  [7:0] in_wdata;
input  [0:0] in_wenable;
output  [7:0] out_rdata;
output  [0:0] out_busy;
output  [0:0] out_rdata_available;
output  [0:0] out_ram_csn;
output  [0:0] out_ram_clk;
inout  [0:0] inout_ram_io0;
inout  [0:0] inout_ram_io1;
inout  [0:0] inout_ram_io2;
inout  [0:0] inout_ram_io3;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
wire  [7:0] _w_spi_read;
wire  [0:0] _w_spi_clk;
wire  [0:0] _w_spi_csn;
reg  [0:0] _t_accept_in;

reg  [39:0] _d_sendvec = 0;
reg  [39:0] _q_sendvec = 0;
reg  [4:0] _d_wait = 0;
reg  [4:0] _q_wait = 0;
reg  [4:0] _d_sending = 0;
reg  [4:0] _q_sending = 0;
reg  [2:0] _d_stage = 1;
reg  [2:0] _q_stage = 1;
reg  [2:0] _d_after = 0;
reg  [2:0] _q_after = 0;
reg  [0:0] _d_init = 1;
reg  [0:0] _q_init = 1;
reg  [0:0] _d_send_else_read = 0;
reg  [0:0] _q_send_else_read = 0;
reg  [0:0] _d_continue = 0;
reg  [0:0] _q_continue = 0;
reg  [7:0] _d__spi_send = 0;
reg  [7:0] _q__spi_send = 0;
reg  [0:0] _d__spi_trigger = 0;
reg  [0:0] _q__spi_trigger = 0;
reg  [0:0] _d__spi_send_else_read = 0;
reg  [0:0] _q__spi_send_else_read = 0;
reg  [7:0] _d_rdata = 0;
reg  [7:0] _q_rdata = 0;
reg  [0:0] _d_busy = 1;
reg  [0:0] _q_busy = 1;
reg  [0:0] _d_rdata_available = 0;
reg  [0:0] _q_rdata_available = 0;
assign out_rdata = _q_rdata;
assign out_busy = _q_busy;
assign out_rdata_available = _q_rdata_available;
assign out_ram_csn = _w_spi_csn;
assign out_ram_clk = _w_spi_clk;
M_qpsram_qspi__txm_spi spi (
.in_send(_q__spi_send),
.in_trigger(_q__spi_trigger),
.in_send_else_read(_q__spi_send_else_read),
.out_read(_w_spi_read),
.out_clk(_w_spi_clk),
.out_csn(_w_spi_csn),
.inout_io0(inout_ram_io0),
.inout_io1(inout_ram_io1),
.inout_io2(inout_ram_io2),
.inout_io3(inout_ram_io3),
.reset(reset),
.clock(clock));



`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_sendvec = _q_sendvec;
_d_wait = _q_wait;
_d_sending = _q_sending;
_d_stage = _q_stage;
_d_after = _q_after;
_d_init = _q_init;
_d_send_else_read = _q_send_else_read;
_d_continue = _q_continue;
_d__spi_send = _q__spi_send;
_d__spi_trigger = _q__spi_trigger;
_d__spi_send_else_read = _q__spi_send_else_read;
_d_rdata = _q_rdata;
_d_busy = _q_busy;
_d_rdata_available = _q_rdata_available;
// _always_pre
// __block_1
_d__spi_send_else_read = _q_send_else_read;

_t_accept_in = 0;

_d_rdata_available = 0;

_d_continue = _q_continue&in_in_ready;

  case (_q_stage)
  0: begin
// __block_3_case
// __block_4
_d_stage = _q_wait[4+:1] ? _q_after:0;

_d_wait = _q_wait+1;

// __block_5
  end
  1: begin
// __block_6_case
// __block_7
_t_accept_in = 1;

// __block_8
  end
  2: begin
// __block_9_case
// __block_10
_d__spi_trigger = 1;

_d__spi_send = _q_sendvec[32+:8];

_d_sendvec = _q_sendvec<<8;

_d_stage = 0;

_d_wait = 16;

_d_after = _q_sending[0+:1] ? (in_wenable ? 4:3):2;

_d_sending = _q_sending>>1;

// __block_11
  end
  3: begin
// __block_12_case
// __block_13
_d__spi_trigger = ~_q_init;

_d_send_else_read = 0;

_d__spi_send = 0;

_d_stage = 0;

_d_wait = 7;

_d_after = 4;

// __block_14
  end
  4: begin
// __block_15_case
// __block_16
_d_rdata = _w_spi_read;

_d_rdata_available = 1;

_d__spi_trigger = _d_continue;

_d_busy = _d_continue;

_d_init = 0;

_d_wait = 16;

_d_stage = ~_d_continue ? 1:0;

_d_after = 4;

_t_accept_in = ~_d_continue;

// __block_17
  end
endcase
// __block_2
if ((in_in_ready|_d_init)&_t_accept_in&~reset) begin
// __block_18
// __block_20
_d_sending = in_wenable ? 5'b10000:5'b01000;

_d_sendvec = _d_init ? {32'b00000000000100010000000100000001,8'b0}:{in_wenable ? 8'h02:8'hEB,in_addr,in_wdata};

_d_send_else_read = 1;

_d_busy = 1;

_d_stage = 2;

_d_continue = 1;

// __block_21
end else begin
// __block_19
end
// __block_22
// __block_23
// _always_post
end

always @(posedge clock) begin
_q_sendvec <= _d_sendvec;
_q_wait <= _d_wait;
_q_sending <= _d_sending;
_q_stage <= _d_stage;
_q_after <= _d_after;
_q_init <= _d_init;
_q_send_else_read <= _d_send_else_read;
_q_continue <= _d_continue;
_q__spi_send <= _d__spi_send;
_q__spi_trigger <= _d__spi_trigger;
_q__spi_send_else_read <= _d__spi_send_else_read;
_q_rdata <= _d_rdata;
_q_busy <= _d_busy;
_q_rdata_available <= _d_rdata_available;
end

endmodule


module M_adapterDataAvailable__adapterDataAvailable_unnamed_0 (
in_valid,
in_data_avail_pulse,
out_data_avail_high,
out_clock,
clock
);
input  [0:0] in_valid;
input  [0:0] in_data_avail_pulse;
output  [0:0] out_data_avail_high;
output out_clock;
input clock;
assign out_clock = clock;

reg  [0:0] _d_data_avail_high = 0;
reg  [0:0] _q_data_avail_high = 0;
assign out_data_avail_high = _d_data_avail_high;



`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_data_avail_high = _q_data_avail_high;
// _always_pre
// __block_1
_d_data_avail_high = ~in_valid ? 0:(_q_data_avail_high|in_data_avail_pulse);

// __block_2
// _always_post
end

always @(posedge clock) begin
_q_data_avail_high <= _d_data_avail_high;
end

endmodule


module M_texture_sampler__gpu_drawer_sampler (
in_smplr_do_bind,
in_smplr_do_fetch,
in_smplr_tex_id,
in_smplr_u,
in_smplr_v,
in_txm_data,
in_txm_data_available,
in_txm_busy,
out_smplr_texel,
out_smplr_ready,
out_txm_in_ready,
out_txm_addr,
reset,
out_clock,
clock
);
input  [1-1:0] in_smplr_do_bind;
input  [1-1:0] in_smplr_do_fetch;
input  [10-1:0] in_smplr_tex_id;
input  [11-1:0] in_smplr_u;
input  [11-1:0] in_smplr_v;
input  [8-1:0] in_txm_data;
input  [1-1:0] in_txm_data_available;
input  [1-1:0] in_txm_busy;
output  [8-1:0] out_smplr_texel;
output  [1-1:0] out_smplr_ready;
output  [1-1:0] out_txm_in_ready;
output  [24-1:0] out_txm_addr;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
reg  [0:0] _t_fetch_next;
reg  [23:0] _t_fetch_addr;
wire  [12:0] _w_tbl_addr;
wire  [0:0] _w___block_1_startbind;
wire  [10:0] _w___block_1_modu;
wire  [10:0] _w___block_1_modv;

reg  [4:0] _d_binding = 0;
reg  [4:0] _q_binding = 0;
reg  [23:0] _d_tex_addr = 0;
reg  [23:0] _q_tex_addr = 0;
reg  [3:0] _d_tex_wp2 = 0;
reg  [3:0] _q_tex_wp2 = 0;
reg  [3:0] _d_tex_hp2 = 0;
reg  [3:0] _q_tex_hp2 = 0;
reg  [10:0] _d_u = 0;
reg  [10:0] _q_u = 0;
reg  [10:0] _d_v = 0;
reg  [10:0] _q_v = 0;
reg  [8-1:0] _d_smplr_texel = 0;
reg  [8-1:0] _q_smplr_texel = 0;
reg  [1-1:0] _d_smplr_ready = 0;
reg  [1-1:0] _q_smplr_ready = 0;
reg  [1-1:0] _d_txm_in_ready = 0;
reg  [1-1:0] _q_txm_in_ready = 0;
reg  [24-1:0] _d_txm_addr = 0;
reg  [24-1:0] _q_txm_addr = 0;
assign out_smplr_texel = _q_smplr_texel;
assign out_smplr_ready = _q_smplr_ready;
assign out_txm_in_ready = _q_txm_in_ready;
assign out_txm_addr = _q_txm_addr;


assign _w_tbl_addr = {in_smplr_tex_id,3'b000};
assign _w___block_1_startbind = (~_q_binding[0+:1])&in_smplr_do_bind;
assign _w___block_1_modu = ((1<<_q_tex_wp2)-1);
assign _w___block_1_modv = ((1<<_q_tex_hp2)-1);

`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_binding = _q_binding;
_d_tex_addr = _q_tex_addr;
_d_tex_wp2 = _q_tex_wp2;
_d_tex_hp2 = _q_tex_hp2;
_d_u = _q_u;
_d_v = _q_v;
_d_smplr_texel = _q_smplr_texel;
_d_smplr_ready = _q_smplr_ready;
_d_txm_in_ready = _q_txm_in_ready;
_d_txm_addr = _q_txm_addr;
// _always_pre
// __block_1
_d_binding = reset ? 0:_w___block_1_startbind ? 5'b11111:(in_txm_data_available ? _q_binding>>1:_q_binding);

_d_txm_in_ready = _d_binding[0+:1]&(~in_txm_data_available|_d_binding[1+:1]);

_d_smplr_ready = ~_d_txm_in_ready;

_t_fetch_next = in_smplr_do_fetch;

_t_fetch_addr = _q_tex_addr+(_q_u|(_q_v<<_q_tex_wp2));

_d_u = in_smplr_u&_w___block_1_modu;

_d_v = in_smplr_v&_w___block_1_modv;

_d_smplr_texel = in_smplr_tex_id==0 ? 99:in_txm_data;

if (_d_binding[0+:1]) begin
// __block_2
// __block_4
_d_txm_addr = {11'b00100000000,_w_tbl_addr};

if (in_txm_data_available) begin
// __block_5
// __block_7
  case (_d_binding[1+:3])
  3'b111: begin
// __block_9_case
// __block_10
_d_tex_addr[0+:8] = in_txm_data;

// __block_11
  end
  3'b011: begin
// __block_12_case
// __block_13
_d_tex_addr[8+:8] = in_txm_data;

// __block_14
  end
  3'b001: begin
// __block_15_case
// __block_16
_d_tex_addr[16+:8] = in_txm_data;

// __block_17
  end
  default: begin
// __block_18_case
// __block_19
// __block_20
  end
endcase
// __block_8
_d_tex_wp2 = in_txm_data[0+:4];

_d_tex_hp2 = in_txm_data[4+:4];

// __block_21
end else begin
// __block_6
end
// __block_22
// __block_23
end else begin
// __block_3
// __block_24
_d_txm_addr = _t_fetch_addr;

_d_txm_in_ready = _t_fetch_next;

// __block_25
end
// __block_26
// __block_27
// _always_post
end

always @(posedge clock) begin
_q_binding <= _d_binding;
_q_tex_addr <= _d_tex_addr;
_q_tex_wp2 <= _d_tex_wp2;
_q_tex_hp2 <= _d_tex_hp2;
_q_u <= _d_u;
_q_v <= _d_v;
_q_smplr_texel <= (reset) ? 0 : _d_smplr_texel;
_q_smplr_ready <= (reset) ? 0 : _d_smplr_ready;
_q_txm_in_ready <= (reset) ? 0 : _d_txm_in_ready;
_q_txm_addr <= (reset) ? 0 : _d_txm_addr;
end

endmodule


// SL 2019, MIT license
module M_span_drawer__gpu_drawer_mem_depths(
input      [8-1:0]                in_addr0,
output reg  [16-1:0]     out_rdata0,
output reg  [16-1:0]     out_rdata1,
input      [1-1:0]             in_wenable1,
input      [16-1:0]                 in_wdata1,
input      [8-1:0]                in_addr1,
input      clock0,
input      clock1
);
(* no_rw_check *) reg  [16-1:0] buffer[240-1:0];
always @(posedge clock0) begin
  out_rdata0 <= buffer[in_addr0];
end
always @(posedge clock1) begin
  if (in_wenable1) begin
    buffer[in_addr1] <= in_wdata1;
  end
end

endmodule

// SL 2019, MIT license
module M_span_drawer__gpu_drawer_mem_inv_y(
input                  [1-1:0] in_wenable,
input       [16-1:0]    in_wdata,
input                  [11-1:0]    in_addr,
output reg  [16-1:0]    out_rdata,
input                                        clock
);
(* no_rw_check *) reg  [16-1:0] buffer[2048-1:0];
always @(posedge clock) begin
  if (in_wenable) begin
    buffer[in_addr] <= in_wdata;
  end
  out_rdata <= buffer[in_addr];
end
initial begin
 buffer[0] = 65535;
 buffer[1] = 65535;
 buffer[2] = 32768;
 buffer[3] = 21845;
 buffer[4] = 16384;
 buffer[5] = 13107;
 buffer[6] = 10922;
 buffer[7] = 9362;
 buffer[8] = 8192;
 buffer[9] = 7281;
 buffer[10] = 6553;
 buffer[11] = 5957;
 buffer[12] = 5461;
 buffer[13] = 5041;
 buffer[14] = 4681;
 buffer[15] = 4369;
 buffer[16] = 4096;
 buffer[17] = 3855;
 buffer[18] = 3640;
 buffer[19] = 3449;
 buffer[20] = 3276;
 buffer[21] = 3120;
 buffer[22] = 2978;
 buffer[23] = 2849;
 buffer[24] = 2730;
 buffer[25] = 2621;
 buffer[26] = 2520;
 buffer[27] = 2427;
 buffer[28] = 2340;
 buffer[29] = 2259;
 buffer[30] = 2184;
 buffer[31] = 2114;
 buffer[32] = 2048;
 buffer[33] = 1985;
 buffer[34] = 1927;
 buffer[35] = 1872;
 buffer[36] = 1820;
 buffer[37] = 1771;
 buffer[38] = 1724;
 buffer[39] = 1680;
 buffer[40] = 1638;
 buffer[41] = 1598;
 buffer[42] = 1560;
 buffer[43] = 1524;
 buffer[44] = 1489;
 buffer[45] = 1456;
 buffer[46] = 1424;
 buffer[47] = 1394;
 buffer[48] = 1365;
 buffer[49] = 1337;
 buffer[50] = 1310;
 buffer[51] = 1285;
 buffer[52] = 1260;
 buffer[53] = 1236;
 buffer[54] = 1213;
 buffer[55] = 1191;
 buffer[56] = 1170;
 buffer[57] = 1149;
 buffer[58] = 1129;
 buffer[59] = 1110;
 buffer[60] = 1092;
 buffer[61] = 1074;
 buffer[62] = 1057;
 buffer[63] = 1040;
 buffer[64] = 1024;
 buffer[65] = 1008;
 buffer[66] = 992;
 buffer[67] = 978;
 buffer[68] = 963;
 buffer[69] = 949;
 buffer[70] = 936;
 buffer[71] = 923;
 buffer[72] = 910;
 buffer[73] = 897;
 buffer[74] = 885;
 buffer[75] = 873;
 buffer[76] = 862;
 buffer[77] = 851;
 buffer[78] = 840;
 buffer[79] = 829;
 buffer[80] = 819;
 buffer[81] = 809;
 buffer[82] = 799;
 buffer[83] = 789;
 buffer[84] = 780;
 buffer[85] = 771;
 buffer[86] = 762;
 buffer[87] = 753;
 buffer[88] = 744;
 buffer[89] = 736;
 buffer[90] = 728;
 buffer[91] = 720;
 buffer[92] = 712;
 buffer[93] = 704;
 buffer[94] = 697;
 buffer[95] = 689;
 buffer[96] = 682;
 buffer[97] = 675;
 buffer[98] = 668;
 buffer[99] = 661;
 buffer[100] = 655;
 buffer[101] = 648;
 buffer[102] = 642;
 buffer[103] = 636;
 buffer[104] = 630;
 buffer[105] = 624;
 buffer[106] = 618;
 buffer[107] = 612;
 buffer[108] = 606;
 buffer[109] = 601;
 buffer[110] = 595;
 buffer[111] = 590;
 buffer[112] = 585;
 buffer[113] = 579;
 buffer[114] = 574;
 buffer[115] = 569;
 buffer[116] = 564;
 buffer[117] = 560;
 buffer[118] = 555;
 buffer[119] = 550;
 buffer[120] = 546;
 buffer[121] = 541;
 buffer[122] = 537;
 buffer[123] = 532;
 buffer[124] = 528;
 buffer[125] = 524;
 buffer[126] = 520;
 buffer[127] = 516;
 buffer[128] = 512;
 buffer[129] = 508;
 buffer[130] = 504;
 buffer[131] = 500;
 buffer[132] = 496;
 buffer[133] = 492;
 buffer[134] = 489;
 buffer[135] = 485;
 buffer[136] = 481;
 buffer[137] = 478;
 buffer[138] = 474;
 buffer[139] = 471;
 buffer[140] = 468;
 buffer[141] = 464;
 buffer[142] = 461;
 buffer[143] = 458;
 buffer[144] = 455;
 buffer[145] = 451;
 buffer[146] = 448;
 buffer[147] = 445;
 buffer[148] = 442;
 buffer[149] = 439;
 buffer[150] = 436;
 buffer[151] = 434;
 buffer[152] = 431;
 buffer[153] = 428;
 buffer[154] = 425;
 buffer[155] = 422;
 buffer[156] = 420;
 buffer[157] = 417;
 buffer[158] = 414;
 buffer[159] = 412;
 buffer[160] = 409;
 buffer[161] = 407;
 buffer[162] = 404;
 buffer[163] = 402;
 buffer[164] = 399;
 buffer[165] = 397;
 buffer[166] = 394;
 buffer[167] = 392;
 buffer[168] = 390;
 buffer[169] = 387;
 buffer[170] = 385;
 buffer[171] = 383;
 buffer[172] = 381;
 buffer[173] = 378;
 buffer[174] = 376;
 buffer[175] = 374;
 buffer[176] = 372;
 buffer[177] = 370;
 buffer[178] = 368;
 buffer[179] = 366;
 buffer[180] = 364;
 buffer[181] = 362;
 buffer[182] = 360;
 buffer[183] = 358;
 buffer[184] = 356;
 buffer[185] = 354;
 buffer[186] = 352;
 buffer[187] = 350;
 buffer[188] = 348;
 buffer[189] = 346;
 buffer[190] = 344;
 buffer[191] = 343;
 buffer[192] = 341;
 buffer[193] = 339;
 buffer[194] = 337;
 buffer[195] = 336;
 buffer[196] = 334;
 buffer[197] = 332;
 buffer[198] = 330;
 buffer[199] = 329;
 buffer[200] = 327;
 buffer[201] = 326;
 buffer[202] = 324;
 buffer[203] = 322;
 buffer[204] = 321;
 buffer[205] = 319;
 buffer[206] = 318;
 buffer[207] = 316;
 buffer[208] = 315;
 buffer[209] = 313;
 buffer[210] = 312;
 buffer[211] = 310;
 buffer[212] = 309;
 buffer[213] = 307;
 buffer[214] = 306;
 buffer[215] = 304;
 buffer[216] = 303;
 buffer[217] = 302;
 buffer[218] = 300;
 buffer[219] = 299;
 buffer[220] = 297;
 buffer[221] = 296;
 buffer[222] = 295;
 buffer[223] = 293;
 buffer[224] = 292;
 buffer[225] = 291;
 buffer[226] = 289;
 buffer[227] = 288;
 buffer[228] = 287;
 buffer[229] = 286;
 buffer[230] = 284;
 buffer[231] = 283;
 buffer[232] = 282;
 buffer[233] = 281;
 buffer[234] = 280;
 buffer[235] = 278;
 buffer[236] = 277;
 buffer[237] = 276;
 buffer[238] = 275;
 buffer[239] = 274;
 buffer[240] = 273;
 buffer[241] = 271;
 buffer[242] = 270;
 buffer[243] = 269;
 buffer[244] = 268;
 buffer[245] = 267;
 buffer[246] = 266;
 buffer[247] = 265;
 buffer[248] = 264;
 buffer[249] = 263;
 buffer[250] = 262;
 buffer[251] = 261;
 buffer[252] = 260;
 buffer[253] = 259;
 buffer[254] = 258;
 buffer[255] = 257;
 buffer[256] = 256;
 buffer[257] = 255;
 buffer[258] = 254;
 buffer[259] = 253;
 buffer[260] = 252;
 buffer[261] = 251;
 buffer[262] = 250;
 buffer[263] = 249;
 buffer[264] = 248;
 buffer[265] = 247;
 buffer[266] = 246;
 buffer[267] = 245;
 buffer[268] = 244;
 buffer[269] = 243;
 buffer[270] = 242;
 buffer[271] = 241;
 buffer[272] = 240;
 buffer[273] = 240;
 buffer[274] = 239;
 buffer[275] = 238;
 buffer[276] = 237;
 buffer[277] = 236;
 buffer[278] = 235;
 buffer[279] = 234;
 buffer[280] = 234;
 buffer[281] = 233;
 buffer[282] = 232;
 buffer[283] = 231;
 buffer[284] = 230;
 buffer[285] = 229;
 buffer[286] = 229;
 buffer[287] = 228;
 buffer[288] = 227;
 buffer[289] = 226;
 buffer[290] = 225;
 buffer[291] = 225;
 buffer[292] = 224;
 buffer[293] = 223;
 buffer[294] = 222;
 buffer[295] = 222;
 buffer[296] = 221;
 buffer[297] = 220;
 buffer[298] = 219;
 buffer[299] = 219;
 buffer[300] = 218;
 buffer[301] = 217;
 buffer[302] = 217;
 buffer[303] = 216;
 buffer[304] = 215;
 buffer[305] = 214;
 buffer[306] = 214;
 buffer[307] = 213;
 buffer[308] = 212;
 buffer[309] = 212;
 buffer[310] = 211;
 buffer[311] = 210;
 buffer[312] = 210;
 buffer[313] = 209;
 buffer[314] = 208;
 buffer[315] = 208;
 buffer[316] = 207;
 buffer[317] = 206;
 buffer[318] = 206;
 buffer[319] = 205;
 buffer[320] = 204;
 buffer[321] = 204;
 buffer[322] = 203;
 buffer[323] = 202;
 buffer[324] = 202;
 buffer[325] = 201;
 buffer[326] = 201;
 buffer[327] = 200;
 buffer[328] = 199;
 buffer[329] = 199;
 buffer[330] = 198;
 buffer[331] = 197;
 buffer[332] = 197;
 buffer[333] = 196;
 buffer[334] = 196;
 buffer[335] = 195;
 buffer[336] = 195;
 buffer[337] = 194;
 buffer[338] = 193;
 buffer[339] = 193;
 buffer[340] = 192;
 buffer[341] = 192;
 buffer[342] = 191;
 buffer[343] = 191;
 buffer[344] = 190;
 buffer[345] = 189;
 buffer[346] = 189;
 buffer[347] = 188;
 buffer[348] = 188;
 buffer[349] = 187;
 buffer[350] = 187;
 buffer[351] = 186;
 buffer[352] = 186;
 buffer[353] = 185;
 buffer[354] = 185;
 buffer[355] = 184;
 buffer[356] = 184;
 buffer[357] = 183;
 buffer[358] = 183;
 buffer[359] = 182;
 buffer[360] = 182;
 buffer[361] = 181;
 buffer[362] = 181;
 buffer[363] = 180;
 buffer[364] = 180;
 buffer[365] = 179;
 buffer[366] = 179;
 buffer[367] = 178;
 buffer[368] = 178;
 buffer[369] = 177;
 buffer[370] = 177;
 buffer[371] = 176;
 buffer[372] = 176;
 buffer[373] = 175;
 buffer[374] = 175;
 buffer[375] = 174;
 buffer[376] = 174;
 buffer[377] = 173;
 buffer[378] = 173;
 buffer[379] = 172;
 buffer[380] = 172;
 buffer[381] = 172;
 buffer[382] = 171;
 buffer[383] = 171;
 buffer[384] = 170;
 buffer[385] = 170;
 buffer[386] = 169;
 buffer[387] = 169;
 buffer[388] = 168;
 buffer[389] = 168;
 buffer[390] = 168;
 buffer[391] = 167;
 buffer[392] = 167;
 buffer[393] = 166;
 buffer[394] = 166;
 buffer[395] = 165;
 buffer[396] = 165;
 buffer[397] = 165;
 buffer[398] = 164;
 buffer[399] = 164;
 buffer[400] = 163;
 buffer[401] = 163;
 buffer[402] = 163;
 buffer[403] = 162;
 buffer[404] = 162;
 buffer[405] = 161;
 buffer[406] = 161;
 buffer[407] = 161;
 buffer[408] = 160;
 buffer[409] = 160;
 buffer[410] = 159;
 buffer[411] = 159;
 buffer[412] = 159;
 buffer[413] = 158;
 buffer[414] = 158;
 buffer[415] = 157;
 buffer[416] = 157;
 buffer[417] = 157;
 buffer[418] = 156;
 buffer[419] = 156;
 buffer[420] = 156;
 buffer[421] = 155;
 buffer[422] = 155;
 buffer[423] = 154;
 buffer[424] = 154;
 buffer[425] = 154;
 buffer[426] = 153;
 buffer[427] = 153;
 buffer[428] = 153;
 buffer[429] = 152;
 buffer[430] = 152;
 buffer[431] = 152;
 buffer[432] = 151;
 buffer[433] = 151;
 buffer[434] = 151;
 buffer[435] = 150;
 buffer[436] = 150;
 buffer[437] = 149;
 buffer[438] = 149;
 buffer[439] = 149;
 buffer[440] = 148;
 buffer[441] = 148;
 buffer[442] = 148;
 buffer[443] = 147;
 buffer[444] = 147;
 buffer[445] = 147;
 buffer[446] = 146;
 buffer[447] = 146;
 buffer[448] = 146;
 buffer[449] = 145;
 buffer[450] = 145;
 buffer[451] = 145;
 buffer[452] = 144;
 buffer[453] = 144;
 buffer[454] = 144;
 buffer[455] = 144;
 buffer[456] = 143;
 buffer[457] = 143;
 buffer[458] = 143;
 buffer[459] = 142;
 buffer[460] = 142;
 buffer[461] = 142;
 buffer[462] = 141;
 buffer[463] = 141;
 buffer[464] = 141;
 buffer[465] = 140;
 buffer[466] = 140;
 buffer[467] = 140;
 buffer[468] = 140;
 buffer[469] = 139;
 buffer[470] = 139;
 buffer[471] = 139;
 buffer[472] = 138;
 buffer[473] = 138;
 buffer[474] = 138;
 buffer[475] = 137;
 buffer[476] = 137;
 buffer[477] = 137;
 buffer[478] = 137;
 buffer[479] = 136;
 buffer[480] = 136;
 buffer[481] = 136;
 buffer[482] = 135;
 buffer[483] = 135;
 buffer[484] = 135;
 buffer[485] = 135;
 buffer[486] = 134;
 buffer[487] = 134;
 buffer[488] = 134;
 buffer[489] = 134;
 buffer[490] = 133;
 buffer[491] = 133;
 buffer[492] = 133;
 buffer[493] = 132;
 buffer[494] = 132;
 buffer[495] = 132;
 buffer[496] = 132;
 buffer[497] = 131;
 buffer[498] = 131;
 buffer[499] = 131;
 buffer[500] = 131;
 buffer[501] = 130;
 buffer[502] = 130;
 buffer[503] = 130;
 buffer[504] = 130;
 buffer[505] = 129;
 buffer[506] = 129;
 buffer[507] = 129;
 buffer[508] = 129;
 buffer[509] = 128;
 buffer[510] = 128;
 buffer[511] = 128;
 buffer[512] = 128;
 buffer[513] = 127;
 buffer[514] = 127;
 buffer[515] = 127;
 buffer[516] = 127;
 buffer[517] = 126;
 buffer[518] = 126;
 buffer[519] = 126;
 buffer[520] = 126;
 buffer[521] = 125;
 buffer[522] = 125;
 buffer[523] = 125;
 buffer[524] = 125;
 buffer[525] = 124;
 buffer[526] = 124;
 buffer[527] = 124;
 buffer[528] = 124;
 buffer[529] = 123;
 buffer[530] = 123;
 buffer[531] = 123;
 buffer[532] = 123;
 buffer[533] = 122;
 buffer[534] = 122;
 buffer[535] = 122;
 buffer[536] = 122;
 buffer[537] = 122;
 buffer[538] = 121;
 buffer[539] = 121;
 buffer[540] = 121;
 buffer[541] = 121;
 buffer[542] = 120;
 buffer[543] = 120;
 buffer[544] = 120;
 buffer[545] = 120;
 buffer[546] = 120;
 buffer[547] = 119;
 buffer[548] = 119;
 buffer[549] = 119;
 buffer[550] = 119;
 buffer[551] = 118;
 buffer[552] = 118;
 buffer[553] = 118;
 buffer[554] = 118;
 buffer[555] = 118;
 buffer[556] = 117;
 buffer[557] = 117;
 buffer[558] = 117;
 buffer[559] = 117;
 buffer[560] = 117;
 buffer[561] = 116;
 buffer[562] = 116;
 buffer[563] = 116;
 buffer[564] = 116;
 buffer[565] = 115;
 buffer[566] = 115;
 buffer[567] = 115;
 buffer[568] = 115;
 buffer[569] = 115;
 buffer[570] = 114;
 buffer[571] = 114;
 buffer[572] = 114;
 buffer[573] = 114;
 buffer[574] = 114;
 buffer[575] = 113;
 buffer[576] = 113;
 buffer[577] = 113;
 buffer[578] = 113;
 buffer[579] = 113;
 buffer[580] = 112;
 buffer[581] = 112;
 buffer[582] = 112;
 buffer[583] = 112;
 buffer[584] = 112;
 buffer[585] = 112;
 buffer[586] = 111;
 buffer[587] = 111;
 buffer[588] = 111;
 buffer[589] = 111;
 buffer[590] = 111;
 buffer[591] = 110;
 buffer[592] = 110;
 buffer[593] = 110;
 buffer[594] = 110;
 buffer[595] = 110;
 buffer[596] = 109;
 buffer[597] = 109;
 buffer[598] = 109;
 buffer[599] = 109;
 buffer[600] = 109;
 buffer[601] = 109;
 buffer[602] = 108;
 buffer[603] = 108;
 buffer[604] = 108;
 buffer[605] = 108;
 buffer[606] = 108;
 buffer[607] = 107;
 buffer[608] = 107;
 buffer[609] = 107;
 buffer[610] = 107;
 buffer[611] = 107;
 buffer[612] = 107;
 buffer[613] = 106;
 buffer[614] = 106;
 buffer[615] = 106;
 buffer[616] = 106;
 buffer[617] = 106;
 buffer[618] = 106;
 buffer[619] = 105;
 buffer[620] = 105;
 buffer[621] = 105;
 buffer[622] = 105;
 buffer[623] = 105;
 buffer[624] = 105;
 buffer[625] = 104;
 buffer[626] = 104;
 buffer[627] = 104;
 buffer[628] = 104;
 buffer[629] = 104;
 buffer[630] = 104;
 buffer[631] = 103;
 buffer[632] = 103;
 buffer[633] = 103;
 buffer[634] = 103;
 buffer[635] = 103;
 buffer[636] = 103;
 buffer[637] = 102;
 buffer[638] = 102;
 buffer[639] = 102;
 buffer[640] = 102;
 buffer[641] = 102;
 buffer[642] = 102;
 buffer[643] = 101;
 buffer[644] = 101;
 buffer[645] = 101;
 buffer[646] = 101;
 buffer[647] = 101;
 buffer[648] = 101;
 buffer[649] = 100;
 buffer[650] = 100;
 buffer[651] = 100;
 buffer[652] = 100;
 buffer[653] = 100;
 buffer[654] = 100;
 buffer[655] = 100;
 buffer[656] = 99;
 buffer[657] = 99;
 buffer[658] = 99;
 buffer[659] = 99;
 buffer[660] = 99;
 buffer[661] = 99;
 buffer[662] = 98;
 buffer[663] = 98;
 buffer[664] = 98;
 buffer[665] = 98;
 buffer[666] = 98;
 buffer[667] = 98;
 buffer[668] = 98;
 buffer[669] = 97;
 buffer[670] = 97;
 buffer[671] = 97;
 buffer[672] = 97;
 buffer[673] = 97;
 buffer[674] = 97;
 buffer[675] = 97;
 buffer[676] = 96;
 buffer[677] = 96;
 buffer[678] = 96;
 buffer[679] = 96;
 buffer[680] = 96;
 buffer[681] = 96;
 buffer[682] = 96;
 buffer[683] = 95;
 buffer[684] = 95;
 buffer[685] = 95;
 buffer[686] = 95;
 buffer[687] = 95;
 buffer[688] = 95;
 buffer[689] = 95;
 buffer[690] = 94;
 buffer[691] = 94;
 buffer[692] = 94;
 buffer[693] = 94;
 buffer[694] = 94;
 buffer[695] = 94;
 buffer[696] = 94;
 buffer[697] = 94;
 buffer[698] = 93;
 buffer[699] = 93;
 buffer[700] = 93;
 buffer[701] = 93;
 buffer[702] = 93;
 buffer[703] = 93;
 buffer[704] = 93;
 buffer[705] = 92;
 buffer[706] = 92;
 buffer[707] = 92;
 buffer[708] = 92;
 buffer[709] = 92;
 buffer[710] = 92;
 buffer[711] = 92;
 buffer[712] = 92;
 buffer[713] = 91;
 buffer[714] = 91;
 buffer[715] = 91;
 buffer[716] = 91;
 buffer[717] = 91;
 buffer[718] = 91;
 buffer[719] = 91;
 buffer[720] = 91;
 buffer[721] = 90;
 buffer[722] = 90;
 buffer[723] = 90;
 buffer[724] = 90;
 buffer[725] = 90;
 buffer[726] = 90;
 buffer[727] = 90;
 buffer[728] = 90;
 buffer[729] = 89;
 buffer[730] = 89;
 buffer[731] = 89;
 buffer[732] = 89;
 buffer[733] = 89;
 buffer[734] = 89;
 buffer[735] = 89;
 buffer[736] = 89;
 buffer[737] = 88;
 buffer[738] = 88;
 buffer[739] = 88;
 buffer[740] = 88;
 buffer[741] = 88;
 buffer[742] = 88;
 buffer[743] = 88;
 buffer[744] = 88;
 buffer[745] = 87;
 buffer[746] = 87;
 buffer[747] = 87;
 buffer[748] = 87;
 buffer[749] = 87;
 buffer[750] = 87;
 buffer[751] = 87;
 buffer[752] = 87;
 buffer[753] = 87;
 buffer[754] = 86;
 buffer[755] = 86;
 buffer[756] = 86;
 buffer[757] = 86;
 buffer[758] = 86;
 buffer[759] = 86;
 buffer[760] = 86;
 buffer[761] = 86;
 buffer[762] = 86;
 buffer[763] = 85;
 buffer[764] = 85;
 buffer[765] = 85;
 buffer[766] = 85;
 buffer[767] = 85;
 buffer[768] = 85;
 buffer[769] = 85;
 buffer[770] = 85;
 buffer[771] = 85;
 buffer[772] = 84;
 buffer[773] = 84;
 buffer[774] = 84;
 buffer[775] = 84;
 buffer[776] = 84;
 buffer[777] = 84;
 buffer[778] = 84;
 buffer[779] = 84;
 buffer[780] = 84;
 buffer[781] = 83;
 buffer[782] = 83;
 buffer[783] = 83;
 buffer[784] = 83;
 buffer[785] = 83;
 buffer[786] = 83;
 buffer[787] = 83;
 buffer[788] = 83;
 buffer[789] = 83;
 buffer[790] = 82;
 buffer[791] = 82;
 buffer[792] = 82;
 buffer[793] = 82;
 buffer[794] = 82;
 buffer[795] = 82;
 buffer[796] = 82;
 buffer[797] = 82;
 buffer[798] = 82;
 buffer[799] = 82;
 buffer[800] = 81;
 buffer[801] = 81;
 buffer[802] = 81;
 buffer[803] = 81;
 buffer[804] = 81;
 buffer[805] = 81;
 buffer[806] = 81;
 buffer[807] = 81;
 buffer[808] = 81;
 buffer[809] = 81;
 buffer[810] = 80;
 buffer[811] = 80;
 buffer[812] = 80;
 buffer[813] = 80;
 buffer[814] = 80;
 buffer[815] = 80;
 buffer[816] = 80;
 buffer[817] = 80;
 buffer[818] = 80;
 buffer[819] = 80;
 buffer[820] = 79;
 buffer[821] = 79;
 buffer[822] = 79;
 buffer[823] = 79;
 buffer[824] = 79;
 buffer[825] = 79;
 buffer[826] = 79;
 buffer[827] = 79;
 buffer[828] = 79;
 buffer[829] = 79;
 buffer[830] = 78;
 buffer[831] = 78;
 buffer[832] = 78;
 buffer[833] = 78;
 buffer[834] = 78;
 buffer[835] = 78;
 buffer[836] = 78;
 buffer[837] = 78;
 buffer[838] = 78;
 buffer[839] = 78;
 buffer[840] = 78;
 buffer[841] = 77;
 buffer[842] = 77;
 buffer[843] = 77;
 buffer[844] = 77;
 buffer[845] = 77;
 buffer[846] = 77;
 buffer[847] = 77;
 buffer[848] = 77;
 buffer[849] = 77;
 buffer[850] = 77;
 buffer[851] = 77;
 buffer[852] = 76;
 buffer[853] = 76;
 buffer[854] = 76;
 buffer[855] = 76;
 buffer[856] = 76;
 buffer[857] = 76;
 buffer[858] = 76;
 buffer[859] = 76;
 buffer[860] = 76;
 buffer[861] = 76;
 buffer[862] = 76;
 buffer[863] = 75;
 buffer[864] = 75;
 buffer[865] = 75;
 buffer[866] = 75;
 buffer[867] = 75;
 buffer[868] = 75;
 buffer[869] = 75;
 buffer[870] = 75;
 buffer[871] = 75;
 buffer[872] = 75;
 buffer[873] = 75;
 buffer[874] = 74;
 buffer[875] = 74;
 buffer[876] = 74;
 buffer[877] = 74;
 buffer[878] = 74;
 buffer[879] = 74;
 buffer[880] = 74;
 buffer[881] = 74;
 buffer[882] = 74;
 buffer[883] = 74;
 buffer[884] = 74;
 buffer[885] = 74;
 buffer[886] = 73;
 buffer[887] = 73;
 buffer[888] = 73;
 buffer[889] = 73;
 buffer[890] = 73;
 buffer[891] = 73;
 buffer[892] = 73;
 buffer[893] = 73;
 buffer[894] = 73;
 buffer[895] = 73;
 buffer[896] = 73;
 buffer[897] = 73;
 buffer[898] = 72;
 buffer[899] = 72;
 buffer[900] = 72;
 buffer[901] = 72;
 buffer[902] = 72;
 buffer[903] = 72;
 buffer[904] = 72;
 buffer[905] = 72;
 buffer[906] = 72;
 buffer[907] = 72;
 buffer[908] = 72;
 buffer[909] = 72;
 buffer[910] = 72;
 buffer[911] = 71;
 buffer[912] = 71;
 buffer[913] = 71;
 buffer[914] = 71;
 buffer[915] = 71;
 buffer[916] = 71;
 buffer[917] = 71;
 buffer[918] = 71;
 buffer[919] = 71;
 buffer[920] = 71;
 buffer[921] = 71;
 buffer[922] = 71;
 buffer[923] = 71;
 buffer[924] = 70;
 buffer[925] = 70;
 buffer[926] = 70;
 buffer[927] = 70;
 buffer[928] = 70;
 buffer[929] = 70;
 buffer[930] = 70;
 buffer[931] = 70;
 buffer[932] = 70;
 buffer[933] = 70;
 buffer[934] = 70;
 buffer[935] = 70;
 buffer[936] = 70;
 buffer[937] = 69;
 buffer[938] = 69;
 buffer[939] = 69;
 buffer[940] = 69;
 buffer[941] = 69;
 buffer[942] = 69;
 buffer[943] = 69;
 buffer[944] = 69;
 buffer[945] = 69;
 buffer[946] = 69;
 buffer[947] = 69;
 buffer[948] = 69;
 buffer[949] = 69;
 buffer[950] = 68;
 buffer[951] = 68;
 buffer[952] = 68;
 buffer[953] = 68;
 buffer[954] = 68;
 buffer[955] = 68;
 buffer[956] = 68;
 buffer[957] = 68;
 buffer[958] = 68;
 buffer[959] = 68;
 buffer[960] = 68;
 buffer[961] = 68;
 buffer[962] = 68;
 buffer[963] = 68;
 buffer[964] = 67;
 buffer[965] = 67;
 buffer[966] = 67;
 buffer[967] = 67;
 buffer[968] = 67;
 buffer[969] = 67;
 buffer[970] = 67;
 buffer[971] = 67;
 buffer[972] = 67;
 buffer[973] = 67;
 buffer[974] = 67;
 buffer[975] = 67;
 buffer[976] = 67;
 buffer[977] = 67;
 buffer[978] = 67;
 buffer[979] = 66;
 buffer[980] = 66;
 buffer[981] = 66;
 buffer[982] = 66;
 buffer[983] = 66;
 buffer[984] = 66;
 buffer[985] = 66;
 buffer[986] = 66;
 buffer[987] = 66;
 buffer[988] = 66;
 buffer[989] = 66;
 buffer[990] = 66;
 buffer[991] = 66;
 buffer[992] = 66;
 buffer[993] = 65;
 buffer[994] = 65;
 buffer[995] = 65;
 buffer[996] = 65;
 buffer[997] = 65;
 buffer[998] = 65;
 buffer[999] = 65;
 buffer[1000] = 65;
 buffer[1001] = 65;
 buffer[1002] = 65;
 buffer[1003] = 65;
 buffer[1004] = 65;
 buffer[1005] = 65;
 buffer[1006] = 65;
 buffer[1007] = 65;
 buffer[1008] = 65;
 buffer[1009] = 64;
 buffer[1010] = 64;
 buffer[1011] = 64;
 buffer[1012] = 64;
 buffer[1013] = 64;
 buffer[1014] = 64;
 buffer[1015] = 64;
 buffer[1016] = 64;
 buffer[1017] = 64;
 buffer[1018] = 64;
 buffer[1019] = 64;
 buffer[1020] = 64;
 buffer[1021] = 64;
 buffer[1022] = 64;
 buffer[1023] = 64;
 buffer[1024] = 64;
 buffer[1025] = 63;
 buffer[1026] = 63;
 buffer[1027] = 63;
 buffer[1028] = 63;
 buffer[1029] = 63;
 buffer[1030] = 63;
 buffer[1031] = 63;
 buffer[1032] = 63;
 buffer[1033] = 63;
 buffer[1034] = 63;
 buffer[1035] = 63;
 buffer[1036] = 63;
 buffer[1037] = 63;
 buffer[1038] = 63;
 buffer[1039] = 63;
 buffer[1040] = 63;
 buffer[1041] = 62;
 buffer[1042] = 62;
 buffer[1043] = 62;
 buffer[1044] = 62;
 buffer[1045] = 62;
 buffer[1046] = 62;
 buffer[1047] = 62;
 buffer[1048] = 62;
 buffer[1049] = 62;
 buffer[1050] = 62;
 buffer[1051] = 62;
 buffer[1052] = 62;
 buffer[1053] = 62;
 buffer[1054] = 62;
 buffer[1055] = 62;
 buffer[1056] = 62;
 buffer[1057] = 62;
 buffer[1058] = 61;
 buffer[1059] = 61;
 buffer[1060] = 61;
 buffer[1061] = 61;
 buffer[1062] = 61;
 buffer[1063] = 61;
 buffer[1064] = 61;
 buffer[1065] = 61;
 buffer[1066] = 61;
 buffer[1067] = 61;
 buffer[1068] = 61;
 buffer[1069] = 61;
 buffer[1070] = 61;
 buffer[1071] = 61;
 buffer[1072] = 61;
 buffer[1073] = 61;
 buffer[1074] = 61;
 buffer[1075] = 60;
 buffer[1076] = 60;
 buffer[1077] = 60;
 buffer[1078] = 60;
 buffer[1079] = 60;
 buffer[1080] = 60;
 buffer[1081] = 60;
 buffer[1082] = 60;
 buffer[1083] = 60;
 buffer[1084] = 60;
 buffer[1085] = 60;
 buffer[1086] = 60;
 buffer[1087] = 60;
 buffer[1088] = 60;
 buffer[1089] = 60;
 buffer[1090] = 60;
 buffer[1091] = 60;
 buffer[1092] = 60;
 buffer[1093] = 59;
 buffer[1094] = 59;
 buffer[1095] = 59;
 buffer[1096] = 59;
 buffer[1097] = 59;
 buffer[1098] = 59;
 buffer[1099] = 59;
 buffer[1100] = 59;
 buffer[1101] = 59;
 buffer[1102] = 59;
 buffer[1103] = 59;
 buffer[1104] = 59;
 buffer[1105] = 59;
 buffer[1106] = 59;
 buffer[1107] = 59;
 buffer[1108] = 59;
 buffer[1109] = 59;
 buffer[1110] = 59;
 buffer[1111] = 58;
 buffer[1112] = 58;
 buffer[1113] = 58;
 buffer[1114] = 58;
 buffer[1115] = 58;
 buffer[1116] = 58;
 buffer[1117] = 58;
 buffer[1118] = 58;
 buffer[1119] = 58;
 buffer[1120] = 58;
 buffer[1121] = 58;
 buffer[1122] = 58;
 buffer[1123] = 58;
 buffer[1124] = 58;
 buffer[1125] = 58;
 buffer[1126] = 58;
 buffer[1127] = 58;
 buffer[1128] = 58;
 buffer[1129] = 58;
 buffer[1130] = 57;
 buffer[1131] = 57;
 buffer[1132] = 57;
 buffer[1133] = 57;
 buffer[1134] = 57;
 buffer[1135] = 57;
 buffer[1136] = 57;
 buffer[1137] = 57;
 buffer[1138] = 57;
 buffer[1139] = 57;
 buffer[1140] = 57;
 buffer[1141] = 57;
 buffer[1142] = 57;
 buffer[1143] = 57;
 buffer[1144] = 57;
 buffer[1145] = 57;
 buffer[1146] = 57;
 buffer[1147] = 57;
 buffer[1148] = 57;
 buffer[1149] = 57;
 buffer[1150] = 56;
 buffer[1151] = 56;
 buffer[1152] = 56;
 buffer[1153] = 56;
 buffer[1154] = 56;
 buffer[1155] = 56;
 buffer[1156] = 56;
 buffer[1157] = 56;
 buffer[1158] = 56;
 buffer[1159] = 56;
 buffer[1160] = 56;
 buffer[1161] = 56;
 buffer[1162] = 56;
 buffer[1163] = 56;
 buffer[1164] = 56;
 buffer[1165] = 56;
 buffer[1166] = 56;
 buffer[1167] = 56;
 buffer[1168] = 56;
 buffer[1169] = 56;
 buffer[1170] = 56;
 buffer[1171] = 55;
 buffer[1172] = 55;
 buffer[1173] = 55;
 buffer[1174] = 55;
 buffer[1175] = 55;
 buffer[1176] = 55;
 buffer[1177] = 55;
 buffer[1178] = 55;
 buffer[1179] = 55;
 buffer[1180] = 55;
 buffer[1181] = 55;
 buffer[1182] = 55;
 buffer[1183] = 55;
 buffer[1184] = 55;
 buffer[1185] = 55;
 buffer[1186] = 55;
 buffer[1187] = 55;
 buffer[1188] = 55;
 buffer[1189] = 55;
 buffer[1190] = 55;
 buffer[1191] = 55;
 buffer[1192] = 54;
 buffer[1193] = 54;
 buffer[1194] = 54;
 buffer[1195] = 54;
 buffer[1196] = 54;
 buffer[1197] = 54;
 buffer[1198] = 54;
 buffer[1199] = 54;
 buffer[1200] = 54;
 buffer[1201] = 54;
 buffer[1202] = 54;
 buffer[1203] = 54;
 buffer[1204] = 54;
 buffer[1205] = 54;
 buffer[1206] = 54;
 buffer[1207] = 54;
 buffer[1208] = 54;
 buffer[1209] = 54;
 buffer[1210] = 54;
 buffer[1211] = 54;
 buffer[1212] = 54;
 buffer[1213] = 54;
 buffer[1214] = 53;
 buffer[1215] = 53;
 buffer[1216] = 53;
 buffer[1217] = 53;
 buffer[1218] = 53;
 buffer[1219] = 53;
 buffer[1220] = 53;
 buffer[1221] = 53;
 buffer[1222] = 53;
 buffer[1223] = 53;
 buffer[1224] = 53;
 buffer[1225] = 53;
 buffer[1226] = 53;
 buffer[1227] = 53;
 buffer[1228] = 53;
 buffer[1229] = 53;
 buffer[1230] = 53;
 buffer[1231] = 53;
 buffer[1232] = 53;
 buffer[1233] = 53;
 buffer[1234] = 53;
 buffer[1235] = 53;
 buffer[1236] = 53;
 buffer[1237] = 52;
 buffer[1238] = 52;
 buffer[1239] = 52;
 buffer[1240] = 52;
 buffer[1241] = 52;
 buffer[1242] = 52;
 buffer[1243] = 52;
 buffer[1244] = 52;
 buffer[1245] = 52;
 buffer[1246] = 52;
 buffer[1247] = 52;
 buffer[1248] = 52;
 buffer[1249] = 52;
 buffer[1250] = 52;
 buffer[1251] = 52;
 buffer[1252] = 52;
 buffer[1253] = 52;
 buffer[1254] = 52;
 buffer[1255] = 52;
 buffer[1256] = 52;
 buffer[1257] = 52;
 buffer[1258] = 52;
 buffer[1259] = 52;
 buffer[1260] = 52;
 buffer[1261] = 51;
 buffer[1262] = 51;
 buffer[1263] = 51;
 buffer[1264] = 51;
 buffer[1265] = 51;
 buffer[1266] = 51;
 buffer[1267] = 51;
 buffer[1268] = 51;
 buffer[1269] = 51;
 buffer[1270] = 51;
 buffer[1271] = 51;
 buffer[1272] = 51;
 buffer[1273] = 51;
 buffer[1274] = 51;
 buffer[1275] = 51;
 buffer[1276] = 51;
 buffer[1277] = 51;
 buffer[1278] = 51;
 buffer[1279] = 51;
 buffer[1280] = 51;
 buffer[1281] = 51;
 buffer[1282] = 51;
 buffer[1283] = 51;
 buffer[1284] = 51;
 buffer[1285] = 51;
 buffer[1286] = 50;
 buffer[1287] = 50;
 buffer[1288] = 50;
 buffer[1289] = 50;
 buffer[1290] = 50;
 buffer[1291] = 50;
 buffer[1292] = 50;
 buffer[1293] = 50;
 buffer[1294] = 50;
 buffer[1295] = 50;
 buffer[1296] = 50;
 buffer[1297] = 50;
 buffer[1298] = 50;
 buffer[1299] = 50;
 buffer[1300] = 50;
 buffer[1301] = 50;
 buffer[1302] = 50;
 buffer[1303] = 50;
 buffer[1304] = 50;
 buffer[1305] = 50;
 buffer[1306] = 50;
 buffer[1307] = 50;
 buffer[1308] = 50;
 buffer[1309] = 50;
 buffer[1310] = 50;
 buffer[1311] = 49;
 buffer[1312] = 49;
 buffer[1313] = 49;
 buffer[1314] = 49;
 buffer[1315] = 49;
 buffer[1316] = 49;
 buffer[1317] = 49;
 buffer[1318] = 49;
 buffer[1319] = 49;
 buffer[1320] = 49;
 buffer[1321] = 49;
 buffer[1322] = 49;
 buffer[1323] = 49;
 buffer[1324] = 49;
 buffer[1325] = 49;
 buffer[1326] = 49;
 buffer[1327] = 49;
 buffer[1328] = 49;
 buffer[1329] = 49;
 buffer[1330] = 49;
 buffer[1331] = 49;
 buffer[1332] = 49;
 buffer[1333] = 49;
 buffer[1334] = 49;
 buffer[1335] = 49;
 buffer[1336] = 49;
 buffer[1337] = 49;
 buffer[1338] = 48;
 buffer[1339] = 48;
 buffer[1340] = 48;
 buffer[1341] = 48;
 buffer[1342] = 48;
 buffer[1343] = 48;
 buffer[1344] = 48;
 buffer[1345] = 48;
 buffer[1346] = 48;
 buffer[1347] = 48;
 buffer[1348] = 48;
 buffer[1349] = 48;
 buffer[1350] = 48;
 buffer[1351] = 48;
 buffer[1352] = 48;
 buffer[1353] = 48;
 buffer[1354] = 48;
 buffer[1355] = 48;
 buffer[1356] = 48;
 buffer[1357] = 48;
 buffer[1358] = 48;
 buffer[1359] = 48;
 buffer[1360] = 48;
 buffer[1361] = 48;
 buffer[1362] = 48;
 buffer[1363] = 48;
 buffer[1364] = 48;
 buffer[1365] = 48;
 buffer[1366] = 47;
 buffer[1367] = 47;
 buffer[1368] = 47;
 buffer[1369] = 47;
 buffer[1370] = 47;
 buffer[1371] = 47;
 buffer[1372] = 47;
 buffer[1373] = 47;
 buffer[1374] = 47;
 buffer[1375] = 47;
 buffer[1376] = 47;
 buffer[1377] = 47;
 buffer[1378] = 47;
 buffer[1379] = 47;
 buffer[1380] = 47;
 buffer[1381] = 47;
 buffer[1382] = 47;
 buffer[1383] = 47;
 buffer[1384] = 47;
 buffer[1385] = 47;
 buffer[1386] = 47;
 buffer[1387] = 47;
 buffer[1388] = 47;
 buffer[1389] = 47;
 buffer[1390] = 47;
 buffer[1391] = 47;
 buffer[1392] = 47;
 buffer[1393] = 47;
 buffer[1394] = 47;
 buffer[1395] = 46;
 buffer[1396] = 46;
 buffer[1397] = 46;
 buffer[1398] = 46;
 buffer[1399] = 46;
 buffer[1400] = 46;
 buffer[1401] = 46;
 buffer[1402] = 46;
 buffer[1403] = 46;
 buffer[1404] = 46;
 buffer[1405] = 46;
 buffer[1406] = 46;
 buffer[1407] = 46;
 buffer[1408] = 46;
 buffer[1409] = 46;
 buffer[1410] = 46;
 buffer[1411] = 46;
 buffer[1412] = 46;
 buffer[1413] = 46;
 buffer[1414] = 46;
 buffer[1415] = 46;
 buffer[1416] = 46;
 buffer[1417] = 46;
 buffer[1418] = 46;
 buffer[1419] = 46;
 buffer[1420] = 46;
 buffer[1421] = 46;
 buffer[1422] = 46;
 buffer[1423] = 46;
 buffer[1424] = 46;
 buffer[1425] = 45;
 buffer[1426] = 45;
 buffer[1427] = 45;
 buffer[1428] = 45;
 buffer[1429] = 45;
 buffer[1430] = 45;
 buffer[1431] = 45;
 buffer[1432] = 45;
 buffer[1433] = 45;
 buffer[1434] = 45;
 buffer[1435] = 45;
 buffer[1436] = 45;
 buffer[1437] = 45;
 buffer[1438] = 45;
 buffer[1439] = 45;
 buffer[1440] = 45;
 buffer[1441] = 45;
 buffer[1442] = 45;
 buffer[1443] = 45;
 buffer[1444] = 45;
 buffer[1445] = 45;
 buffer[1446] = 45;
 buffer[1447] = 45;
 buffer[1448] = 45;
 buffer[1449] = 45;
 buffer[1450] = 45;
 buffer[1451] = 45;
 buffer[1452] = 45;
 buffer[1453] = 45;
 buffer[1454] = 45;
 buffer[1455] = 45;
 buffer[1456] = 45;
 buffer[1457] = 44;
 buffer[1458] = 44;
 buffer[1459] = 44;
 buffer[1460] = 44;
 buffer[1461] = 44;
 buffer[1462] = 44;
 buffer[1463] = 44;
 buffer[1464] = 44;
 buffer[1465] = 44;
 buffer[1466] = 44;
 buffer[1467] = 44;
 buffer[1468] = 44;
 buffer[1469] = 44;
 buffer[1470] = 44;
 buffer[1471] = 44;
 buffer[1472] = 44;
 buffer[1473] = 44;
 buffer[1474] = 44;
 buffer[1475] = 44;
 buffer[1476] = 44;
 buffer[1477] = 44;
 buffer[1478] = 44;
 buffer[1479] = 44;
 buffer[1480] = 44;
 buffer[1481] = 44;
 buffer[1482] = 44;
 buffer[1483] = 44;
 buffer[1484] = 44;
 buffer[1485] = 44;
 buffer[1486] = 44;
 buffer[1487] = 44;
 buffer[1488] = 44;
 buffer[1489] = 44;
 buffer[1490] = 43;
 buffer[1491] = 43;
 buffer[1492] = 43;
 buffer[1493] = 43;
 buffer[1494] = 43;
 buffer[1495] = 43;
 buffer[1496] = 43;
 buffer[1497] = 43;
 buffer[1498] = 43;
 buffer[1499] = 43;
 buffer[1500] = 43;
 buffer[1501] = 43;
 buffer[1502] = 43;
 buffer[1503] = 43;
 buffer[1504] = 43;
 buffer[1505] = 43;
 buffer[1506] = 43;
 buffer[1507] = 43;
 buffer[1508] = 43;
 buffer[1509] = 43;
 buffer[1510] = 43;
 buffer[1511] = 43;
 buffer[1512] = 43;
 buffer[1513] = 43;
 buffer[1514] = 43;
 buffer[1515] = 43;
 buffer[1516] = 43;
 buffer[1517] = 43;
 buffer[1518] = 43;
 buffer[1519] = 43;
 buffer[1520] = 43;
 buffer[1521] = 43;
 buffer[1522] = 43;
 buffer[1523] = 43;
 buffer[1524] = 43;
 buffer[1525] = 42;
 buffer[1526] = 42;
 buffer[1527] = 42;
 buffer[1528] = 42;
 buffer[1529] = 42;
 buffer[1530] = 42;
 buffer[1531] = 42;
 buffer[1532] = 42;
 buffer[1533] = 42;
 buffer[1534] = 42;
 buffer[1535] = 42;
 buffer[1536] = 42;
 buffer[1537] = 42;
 buffer[1538] = 42;
 buffer[1539] = 42;
 buffer[1540] = 42;
 buffer[1541] = 42;
 buffer[1542] = 42;
 buffer[1543] = 42;
 buffer[1544] = 42;
 buffer[1545] = 42;
 buffer[1546] = 42;
 buffer[1547] = 42;
 buffer[1548] = 42;
 buffer[1549] = 42;
 buffer[1550] = 42;
 buffer[1551] = 42;
 buffer[1552] = 42;
 buffer[1553] = 42;
 buffer[1554] = 42;
 buffer[1555] = 42;
 buffer[1556] = 42;
 buffer[1557] = 42;
 buffer[1558] = 42;
 buffer[1559] = 42;
 buffer[1560] = 42;
 buffer[1561] = 41;
 buffer[1562] = 41;
 buffer[1563] = 41;
 buffer[1564] = 41;
 buffer[1565] = 41;
 buffer[1566] = 41;
 buffer[1567] = 41;
 buffer[1568] = 41;
 buffer[1569] = 41;
 buffer[1570] = 41;
 buffer[1571] = 41;
 buffer[1572] = 41;
 buffer[1573] = 41;
 buffer[1574] = 41;
 buffer[1575] = 41;
 buffer[1576] = 41;
 buffer[1577] = 41;
 buffer[1578] = 41;
 buffer[1579] = 41;
 buffer[1580] = 41;
 buffer[1581] = 41;
 buffer[1582] = 41;
 buffer[1583] = 41;
 buffer[1584] = 41;
 buffer[1585] = 41;
 buffer[1586] = 41;
 buffer[1587] = 41;
 buffer[1588] = 41;
 buffer[1589] = 41;
 buffer[1590] = 41;
 buffer[1591] = 41;
 buffer[1592] = 41;
 buffer[1593] = 41;
 buffer[1594] = 41;
 buffer[1595] = 41;
 buffer[1596] = 41;
 buffer[1597] = 41;
 buffer[1598] = 41;
 buffer[1599] = 40;
 buffer[1600] = 40;
 buffer[1601] = 40;
 buffer[1602] = 40;
 buffer[1603] = 40;
 buffer[1604] = 40;
 buffer[1605] = 40;
 buffer[1606] = 40;
 buffer[1607] = 40;
 buffer[1608] = 40;
 buffer[1609] = 40;
 buffer[1610] = 40;
 buffer[1611] = 40;
 buffer[1612] = 40;
 buffer[1613] = 40;
 buffer[1614] = 40;
 buffer[1615] = 40;
 buffer[1616] = 40;
 buffer[1617] = 40;
 buffer[1618] = 40;
 buffer[1619] = 40;
 buffer[1620] = 40;
 buffer[1621] = 40;
 buffer[1622] = 40;
 buffer[1623] = 40;
 buffer[1624] = 40;
 buffer[1625] = 40;
 buffer[1626] = 40;
 buffer[1627] = 40;
 buffer[1628] = 40;
 buffer[1629] = 40;
 buffer[1630] = 40;
 buffer[1631] = 40;
 buffer[1632] = 40;
 buffer[1633] = 40;
 buffer[1634] = 40;
 buffer[1635] = 40;
 buffer[1636] = 40;
 buffer[1637] = 40;
 buffer[1638] = 40;
 buffer[1639] = 39;
 buffer[1640] = 39;
 buffer[1641] = 39;
 buffer[1642] = 39;
 buffer[1643] = 39;
 buffer[1644] = 39;
 buffer[1645] = 39;
 buffer[1646] = 39;
 buffer[1647] = 39;
 buffer[1648] = 39;
 buffer[1649] = 39;
 buffer[1650] = 39;
 buffer[1651] = 39;
 buffer[1652] = 39;
 buffer[1653] = 39;
 buffer[1654] = 39;
 buffer[1655] = 39;
 buffer[1656] = 39;
 buffer[1657] = 39;
 buffer[1658] = 39;
 buffer[1659] = 39;
 buffer[1660] = 39;
 buffer[1661] = 39;
 buffer[1662] = 39;
 buffer[1663] = 39;
 buffer[1664] = 39;
 buffer[1665] = 39;
 buffer[1666] = 39;
 buffer[1667] = 39;
 buffer[1668] = 39;
 buffer[1669] = 39;
 buffer[1670] = 39;
 buffer[1671] = 39;
 buffer[1672] = 39;
 buffer[1673] = 39;
 buffer[1674] = 39;
 buffer[1675] = 39;
 buffer[1676] = 39;
 buffer[1677] = 39;
 buffer[1678] = 39;
 buffer[1679] = 39;
 buffer[1680] = 39;
 buffer[1681] = 38;
 buffer[1682] = 38;
 buffer[1683] = 38;
 buffer[1684] = 38;
 buffer[1685] = 38;
 buffer[1686] = 38;
 buffer[1687] = 38;
 buffer[1688] = 38;
 buffer[1689] = 38;
 buffer[1690] = 38;
 buffer[1691] = 38;
 buffer[1692] = 38;
 buffer[1693] = 38;
 buffer[1694] = 38;
 buffer[1695] = 38;
 buffer[1696] = 38;
 buffer[1697] = 38;
 buffer[1698] = 38;
 buffer[1699] = 38;
 buffer[1700] = 38;
 buffer[1701] = 38;
 buffer[1702] = 38;
 buffer[1703] = 38;
 buffer[1704] = 38;
 buffer[1705] = 38;
 buffer[1706] = 38;
 buffer[1707] = 38;
 buffer[1708] = 38;
 buffer[1709] = 38;
 buffer[1710] = 38;
 buffer[1711] = 38;
 buffer[1712] = 38;
 buffer[1713] = 38;
 buffer[1714] = 38;
 buffer[1715] = 38;
 buffer[1716] = 38;
 buffer[1717] = 38;
 buffer[1718] = 38;
 buffer[1719] = 38;
 buffer[1720] = 38;
 buffer[1721] = 38;
 buffer[1722] = 38;
 buffer[1723] = 38;
 buffer[1724] = 38;
 buffer[1725] = 37;
 buffer[1726] = 37;
 buffer[1727] = 37;
 buffer[1728] = 37;
 buffer[1729] = 37;
 buffer[1730] = 37;
 buffer[1731] = 37;
 buffer[1732] = 37;
 buffer[1733] = 37;
 buffer[1734] = 37;
 buffer[1735] = 37;
 buffer[1736] = 37;
 buffer[1737] = 37;
 buffer[1738] = 37;
 buffer[1739] = 37;
 buffer[1740] = 37;
 buffer[1741] = 37;
 buffer[1742] = 37;
 buffer[1743] = 37;
 buffer[1744] = 37;
 buffer[1745] = 37;
 buffer[1746] = 37;
 buffer[1747] = 37;
 buffer[1748] = 37;
 buffer[1749] = 37;
 buffer[1750] = 37;
 buffer[1751] = 37;
 buffer[1752] = 37;
 buffer[1753] = 37;
 buffer[1754] = 37;
 buffer[1755] = 37;
 buffer[1756] = 37;
 buffer[1757] = 37;
 buffer[1758] = 37;
 buffer[1759] = 37;
 buffer[1760] = 37;
 buffer[1761] = 37;
 buffer[1762] = 37;
 buffer[1763] = 37;
 buffer[1764] = 37;
 buffer[1765] = 37;
 buffer[1766] = 37;
 buffer[1767] = 37;
 buffer[1768] = 37;
 buffer[1769] = 37;
 buffer[1770] = 37;
 buffer[1771] = 37;
 buffer[1772] = 36;
 buffer[1773] = 36;
 buffer[1774] = 36;
 buffer[1775] = 36;
 buffer[1776] = 36;
 buffer[1777] = 36;
 buffer[1778] = 36;
 buffer[1779] = 36;
 buffer[1780] = 36;
 buffer[1781] = 36;
 buffer[1782] = 36;
 buffer[1783] = 36;
 buffer[1784] = 36;
 buffer[1785] = 36;
 buffer[1786] = 36;
 buffer[1787] = 36;
 buffer[1788] = 36;
 buffer[1789] = 36;
 buffer[1790] = 36;
 buffer[1791] = 36;
 buffer[1792] = 36;
 buffer[1793] = 36;
 buffer[1794] = 36;
 buffer[1795] = 36;
 buffer[1796] = 36;
 buffer[1797] = 36;
 buffer[1798] = 36;
 buffer[1799] = 36;
 buffer[1800] = 36;
 buffer[1801] = 36;
 buffer[1802] = 36;
 buffer[1803] = 36;
 buffer[1804] = 36;
 buffer[1805] = 36;
 buffer[1806] = 36;
 buffer[1807] = 36;
 buffer[1808] = 36;
 buffer[1809] = 36;
 buffer[1810] = 36;
 buffer[1811] = 36;
 buffer[1812] = 36;
 buffer[1813] = 36;
 buffer[1814] = 36;
 buffer[1815] = 36;
 buffer[1816] = 36;
 buffer[1817] = 36;
 buffer[1818] = 36;
 buffer[1819] = 36;
 buffer[1820] = 36;
 buffer[1821] = 35;
 buffer[1822] = 35;
 buffer[1823] = 35;
 buffer[1824] = 35;
 buffer[1825] = 35;
 buffer[1826] = 35;
 buffer[1827] = 35;
 buffer[1828] = 35;
 buffer[1829] = 35;
 buffer[1830] = 35;
 buffer[1831] = 35;
 buffer[1832] = 35;
 buffer[1833] = 35;
 buffer[1834] = 35;
 buffer[1835] = 35;
 buffer[1836] = 35;
 buffer[1837] = 35;
 buffer[1838] = 35;
 buffer[1839] = 35;
 buffer[1840] = 35;
 buffer[1841] = 35;
 buffer[1842] = 35;
 buffer[1843] = 35;
 buffer[1844] = 35;
 buffer[1845] = 35;
 buffer[1846] = 35;
 buffer[1847] = 35;
 buffer[1848] = 35;
 buffer[1849] = 35;
 buffer[1850] = 35;
 buffer[1851] = 35;
 buffer[1852] = 35;
 buffer[1853] = 35;
 buffer[1854] = 35;
 buffer[1855] = 35;
 buffer[1856] = 35;
 buffer[1857] = 35;
 buffer[1858] = 35;
 buffer[1859] = 35;
 buffer[1860] = 35;
 buffer[1861] = 35;
 buffer[1862] = 35;
 buffer[1863] = 35;
 buffer[1864] = 35;
 buffer[1865] = 35;
 buffer[1866] = 35;
 buffer[1867] = 35;
 buffer[1868] = 35;
 buffer[1869] = 35;
 buffer[1870] = 35;
 buffer[1871] = 35;
 buffer[1872] = 35;
 buffer[1873] = 34;
 buffer[1874] = 34;
 buffer[1875] = 34;
 buffer[1876] = 34;
 buffer[1877] = 34;
 buffer[1878] = 34;
 buffer[1879] = 34;
 buffer[1880] = 34;
 buffer[1881] = 34;
 buffer[1882] = 34;
 buffer[1883] = 34;
 buffer[1884] = 34;
 buffer[1885] = 34;
 buffer[1886] = 34;
 buffer[1887] = 34;
 buffer[1888] = 34;
 buffer[1889] = 34;
 buffer[1890] = 34;
 buffer[1891] = 34;
 buffer[1892] = 34;
 buffer[1893] = 34;
 buffer[1894] = 34;
 buffer[1895] = 34;
 buffer[1896] = 34;
 buffer[1897] = 34;
 buffer[1898] = 34;
 buffer[1899] = 34;
 buffer[1900] = 34;
 buffer[1901] = 34;
 buffer[1902] = 34;
 buffer[1903] = 34;
 buffer[1904] = 34;
 buffer[1905] = 34;
 buffer[1906] = 34;
 buffer[1907] = 34;
 buffer[1908] = 34;
 buffer[1909] = 34;
 buffer[1910] = 34;
 buffer[1911] = 34;
 buffer[1912] = 34;
 buffer[1913] = 34;
 buffer[1914] = 34;
 buffer[1915] = 34;
 buffer[1916] = 34;
 buffer[1917] = 34;
 buffer[1918] = 34;
 buffer[1919] = 34;
 buffer[1920] = 34;
 buffer[1921] = 34;
 buffer[1922] = 34;
 buffer[1923] = 34;
 buffer[1924] = 34;
 buffer[1925] = 34;
 buffer[1926] = 34;
 buffer[1927] = 34;
 buffer[1928] = 33;
 buffer[1929] = 33;
 buffer[1930] = 33;
 buffer[1931] = 33;
 buffer[1932] = 33;
 buffer[1933] = 33;
 buffer[1934] = 33;
 buffer[1935] = 33;
 buffer[1936] = 33;
 buffer[1937] = 33;
 buffer[1938] = 33;
 buffer[1939] = 33;
 buffer[1940] = 33;
 buffer[1941] = 33;
 buffer[1942] = 33;
 buffer[1943] = 33;
 buffer[1944] = 33;
 buffer[1945] = 33;
 buffer[1946] = 33;
 buffer[1947] = 33;
 buffer[1948] = 33;
 buffer[1949] = 33;
 buffer[1950] = 33;
 buffer[1951] = 33;
 buffer[1952] = 33;
 buffer[1953] = 33;
 buffer[1954] = 33;
 buffer[1955] = 33;
 buffer[1956] = 33;
 buffer[1957] = 33;
 buffer[1958] = 33;
 buffer[1959] = 33;
 buffer[1960] = 33;
 buffer[1961] = 33;
 buffer[1962] = 33;
 buffer[1963] = 33;
 buffer[1964] = 33;
 buffer[1965] = 33;
 buffer[1966] = 33;
 buffer[1967] = 33;
 buffer[1968] = 33;
 buffer[1969] = 33;
 buffer[1970] = 33;
 buffer[1971] = 33;
 buffer[1972] = 33;
 buffer[1973] = 33;
 buffer[1974] = 33;
 buffer[1975] = 33;
 buffer[1976] = 33;
 buffer[1977] = 33;
 buffer[1978] = 33;
 buffer[1979] = 33;
 buffer[1980] = 33;
 buffer[1981] = 33;
 buffer[1982] = 33;
 buffer[1983] = 33;
 buffer[1984] = 33;
 buffer[1985] = 33;
 buffer[1986] = 32;
 buffer[1987] = 32;
 buffer[1988] = 32;
 buffer[1989] = 32;
 buffer[1990] = 32;
 buffer[1991] = 32;
 buffer[1992] = 32;
 buffer[1993] = 32;
 buffer[1994] = 32;
 buffer[1995] = 32;
 buffer[1996] = 32;
 buffer[1997] = 32;
 buffer[1998] = 32;
 buffer[1999] = 32;
 buffer[2000] = 32;
 buffer[2001] = 32;
 buffer[2002] = 32;
 buffer[2003] = 32;
 buffer[2004] = 32;
 buffer[2005] = 32;
 buffer[2006] = 32;
 buffer[2007] = 32;
 buffer[2008] = 32;
 buffer[2009] = 32;
 buffer[2010] = 32;
 buffer[2011] = 32;
 buffer[2012] = 32;
 buffer[2013] = 32;
 buffer[2014] = 32;
 buffer[2015] = 32;
 buffer[2016] = 32;
 buffer[2017] = 32;
 buffer[2018] = 32;
 buffer[2019] = 32;
 buffer[2020] = 32;
 buffer[2021] = 32;
 buffer[2022] = 32;
 buffer[2023] = 32;
 buffer[2024] = 32;
 buffer[2025] = 32;
 buffer[2026] = 32;
 buffer[2027] = 32;
 buffer[2028] = 32;
 buffer[2029] = 32;
 buffer[2030] = 32;
 buffer[2031] = 32;
 buffer[2032] = 32;
 buffer[2033] = 32;
 buffer[2034] = 32;
 buffer[2035] = 32;
 buffer[2036] = 32;
 buffer[2037] = 32;
 buffer[2038] = 32;
 buffer[2039] = 32;
 buffer[2040] = 32;
 buffer[2041] = 32;
 buffer[2042] = 32;
 buffer[2043] = 32;
 buffer[2044] = 32;
 buffer[2045] = 32;
 buffer[2046] = 32;
 buffer[2047] = 32;
end

endmodule

module M_span_drawer__gpu_drawer (
in_in_start,
in_in_command,
in_buffer,
in_txm_data,
in_txm_data_available,
in_txm_busy,
out_colbufs_addr1,
out_colbufs_wenable1,
out_colbufs_wdata1,
out_busy,
out_pickedh,
out_txm_in_ready,
out_txm_addr,
reset,
out_clock,
clock
);
input  [0:0] in_in_start;
input  [63:0] in_in_command;
input  [0:0] in_buffer;
input  [8-1:0] in_txm_data;
input  [1-1:0] in_txm_data_available;
input  [1-1:0] in_txm_busy;
output  [9-1:0] out_colbufs_addr1;
output  [1-1:0] out_colbufs_wenable1;
output  [12-1:0] out_colbufs_wdata1;
output  [0:0] out_busy;
output  [7:0] out_pickedh;
output  [1-1:0] out_txm_in_ready;
output  [24-1:0] out_txm_addr;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
wire  [8-1:0] _w_sampler_smplr_texel;
wire  [1-1:0] _w_sampler_smplr_ready;
wire  [1-1:0] _w_sampler_txm_in_ready;
wire  [24-1:0] _w_sampler_txm_addr;
wire  [15:0] _w_mem_depths_rdata0;
wire  [15:0] _w_mem_inv_y_rdata;
reg  [0:0] _t_sampler_io_do_bind;
reg  [0:0] _t_sampler_io_do_fetch;
reg  [10:0] _t_sampler_io_u;
reg  [10:0] _t_sampler_io_v;
reg  [7:0] _t_depths_addr0;
reg  [0:0] _t_depths_wenable1;
reg  [15:0] _t_depths_wdata1;
reg  [7:0] _t_depths_addr1;
reg  [0:0] _t_inv_y_wenable;
reg  [15:0] _t_inv_y_wdata;
reg  [10:0] _t_inv_y_addr;
reg  [9-1:0] _t_colbufs_addr1;
reg  [1-1:0] _t_colbufs_wenable1;
reg  [12-1:0] _t_colbufs_wdata1;
wire  [7:0] _w_col_start;
wire  [7:0] _w_col_end;
wire  [0:0] _w_wall;
wire  [0:0] _w_plane;
wire  [0:0] _w_terrain;
wire  [0:0] _w_param;
wire  [0:0] _w_ray_cs;
wire  [0:0] _w_planeA;
wire  [0:0] _w_uv_offs;
wire  [0:0] _w_set_vwz;
wire  [0:0] _w_pickh;
wire  [0:0] _w_current_done;
wire  [10:0] _w_terrain_dist;
wire  [0:0] _w_terrain_done;
wire  [23:0] _w_scrd_inc;
wire  [14:0] _w___block_1_dist;
wire  [0:0] _w___block_1_depth_ok;
wire  [3:0] _w___block_1_obscure_dist;
wire  [3:0] _w___block_1_obscure_clmp;
wire signed [4:0] _w___block_1_light;
wire  [0:0] _w___block_1_opaque;
wire  [0:0] _w___block_1_bkg;
wire  [7:0] _w___block_1_wc_u_8;
wire  [7:0] _w___block_1_wc_v_8;
wire signed [31:0] _w___block_1_result;
wire  [7:0] _w___block_27_pixcoord;
wire signed [23:0] _w___block_29_neg_dot_ray;
wire  [9:0] _w___block_33_tex_id;
wire  [0:0] _w___block_33_bkg_tex_id;
wire  [0:0] _w___block_35_still_drawing;
wire signed [15:0] _w___block_41_scrh;
wire  [7:0] _w___block_41_end_next;
wire  [0:0] _w___block_43_next_tcol_rdy;
wire  [1:0] _w___block_43_step_shift;
wire  [15:0] _w___block_43_terrain_step;
wire  [13:0] _w___block_43_tc_v_inc;
wire  [13:0] _w___block_43_wc_v_inc;

reg  [9:0] _d_sampler_io_tex_id = 0;
reg  [9:0] _q_sampler_io_tex_id = 0;
reg  [0:0] _d_drawing = 0;
reg  [0:0] _q_drawing = 0;
reg  [7:0] _d_current = 0;
reg  [7:0] _q_current = 0;
reg  [7:0] _d_end = 0;
reg  [7:0] _q_end = 0;
reg  [0:0] _d_pickh_done = 0;
reg  [0:0] _q_pickh_done = 0;
reg signed [23:0] _d_dot_u = 0;
reg signed [23:0] _q_dot_u = 0;
reg signed [23:0] _d_dot_v = 0;
reg signed [23:0] _q_dot_v = 0;
reg signed [23:0] _d_dot_ray = 0;
reg signed [23:0] _q_dot_ray = 0;
reg signed [23:0] _d_ded = 0;
reg signed [23:0] _q_ded = 0;
reg signed [9:0] _d_ny_inc = 0;
reg signed [9:0] _q_ny_inc = 0;
reg signed [9:0] _d_uy_inc = 0;
reg signed [9:0] _q_uy_inc = 0;
reg signed [9:0] _d_vy_inc = 0;
reg signed [9:0] _q_vy_inc = 0;
reg signed [31:0] _d_ray_t = 0;
reg signed [31:0] _q_ray_t = 0;
reg signed [23:0] _d_u_offset = 0;
reg signed [23:0] _q_u_offset = 0;
reg signed [23:0] _d_v_offset = 0;
reg signed [23:0] _q_v_offset = 0;
reg signed [15:0] _d_view_z = 0;
reg signed [15:0] _q_view_z = 0;
reg  [0:0] _d_tcol_rdy = 0;
reg  [0:0] _q_tcol_rdy = 0;
reg signed [23:0] _d_tcol_dist = 0;
reg signed [23:0] _q_tcol_dist = 0;
reg  [23:0] _d_prev_tcol_dist = 0;
reg  [23:0] _q_prev_tcol_dist = 0;
reg  [7:0] _d_scrh_diff = 0;
reg  [7:0] _q_scrh_diff = 0;
reg signed [12:0] _d_cosray = 0;
reg signed [12:0] _q_cosray = 0;
reg signed [12:0] _d_sinray = 0;
reg signed [12:0] _q_sinray = 0;
reg  [3:0] _d_state = 0;
reg  [3:0] _q_state = 0;
reg signed [23:0] _d_wc_v = 0;
reg signed [23:0] _q_wc_v = 0;
reg  [7:0] _d_wc_u = 0;
reg  [7:0] _q_wc_u = 0;
reg signed [23:0] _d_tc_v = 0;
reg signed [23:0] _q_tc_v = 0;
reg signed [23:0] _d_tr_u = 0;
reg signed [23:0] _q_tr_u = 0;
reg signed [23:0] _d_tr_v = 0;
reg signed [23:0] _q_tr_v = 0;
reg signed [31:0] _d_a = 0;
reg signed [31:0] _q_a = 0;
reg signed [31:0] _d_b = 0;
reg signed [31:0] _q_b = 0;
reg signed [31:0] _d_c = 0;
reg signed [31:0] _q_c = 0;
reg  [12:0] _d_smplr_delay = 0;
reg  [12:0] _q_smplr_delay = 0;
reg  [0:0] _d_start = 0;
reg  [0:0] _q_start = 0;
reg  [2:0] _d_skip = 0;
reg  [2:0] _q_skip = 0;
reg  [0:0] _d_busy = 1;
reg  [0:0] _q_busy = 1;
reg  [7:0] _d_pickedh = 0;
reg  [7:0] _q_pickedh = 0;
assign out_colbufs_addr1 = _t_colbufs_addr1;
assign out_colbufs_wenable1 = _t_colbufs_wenable1;
assign out_colbufs_wdata1 = _t_colbufs_wdata1;
assign out_busy = _q_busy;
assign out_pickedh = _q_pickedh;
assign out_txm_in_ready = _w_sampler_txm_in_ready;
assign out_txm_addr = _w_sampler_txm_addr;
M_texture_sampler__gpu_drawer_sampler sampler (
.in_smplr_do_bind(_t_sampler_io_do_bind),
.in_smplr_do_fetch(_t_sampler_io_do_fetch),
.in_smplr_tex_id(_d_sampler_io_tex_id),
.in_smplr_u(_t_sampler_io_u),
.in_smplr_v(_t_sampler_io_v),
.in_txm_data(in_txm_data),
.in_txm_data_available(in_txm_data_available),
.in_txm_busy(in_txm_busy),
.out_smplr_texel(_w_sampler_smplr_texel),
.out_smplr_ready(_w_sampler_smplr_ready),
.out_txm_in_ready(_w_sampler_txm_in_ready),
.out_txm_addr(_w_sampler_txm_addr),
.reset(reset),
.clock(clock));

M_span_drawer__gpu_drawer_mem_depths __mem__depths(
.clock0(clock),
.clock1(clock),
.in_addr0(_t_depths_addr0),
.in_wenable1(_t_depths_wenable1),
.in_wdata1(_t_depths_wdata1),
.in_addr1(_t_depths_addr1),
.out_rdata0(_w_mem_depths_rdata0)
);
M_span_drawer__gpu_drawer_mem_inv_y __mem__inv_y(
.clock(clock),
.in_wenable(_t_inv_y_wenable),
.in_wdata(_t_inv_y_wdata),
.in_addr(_t_inv_y_addr),
.out_rdata(_w_mem_inv_y_rdata)
);

assign _w_col_start = in_in_command[10+:8];
assign _w_col_end = in_in_command[18+:8]>8'd239 ? 8'd239:in_in_command[18+:8];
assign _w_wall = in_in_command[30+:2]==2'b00;
assign _w_plane = in_in_command[30+:2]==2'b01;
assign _w_terrain = in_in_command[30+:2]==2'b10;
assign _w_param = in_in_command[30+:2]==2'b11;
assign _w_ray_cs = _w_param&(in_in_command[62+:2]==2'b00);
assign _w_planeA = _w_param&(in_in_command[62+:2]==2'b10);
assign _w_uv_offs = _w_param&(in_in_command[62+:2]==2'b01);
assign _w_set_vwz = _w_param&(in_in_command[62+:2]==2'b11);
assign _w_pickh = _w_terrain&in_in_command[63+:1];
assign _w_current_done = (_q_current>=_q_end);
assign _w_terrain_dist = _q_tcol_rdy ? _q_tcol_dist[8+:11]:_q_tc_v[8+:11];
assign _w_terrain_done = (_q_tcol_dist[8+:11]>in_in_command[32+:11])|(_q_tcol_dist[19+:1]);
assign _w_scrd_inc = ((_q_tcol_dist[8+:11]-_q_prev_tcol_dist[8+:11])*_w_mem_inv_y_rdata)>>8;
assign _w___block_1_dist = (_w_terrain ? {3'b0,_q_tcol_dist[8+:12]}:15'b0)|(_w_plane ? _q_ray_t[2+:15]:15'b0)|(_w_wall ? {{2{in_in_command[47+:1]}},in_in_command[35+:13]}:15'b0);
assign _w___block_1_depth_ok = (_w_mem_depths_rdata0[15+:1]^in_buffer)|(_w___block_1_dist<_w_mem_depths_rdata0[0+:15]);
assign _w___block_1_obscure_dist = _w___block_1_dist[7+:4];
assign _w___block_1_obscure_clmp = _w___block_1_obscure_dist>10 ? 10:_w___block_1_obscure_dist;
assign _w___block_1_light = ($signed({1'b0,in_in_command[26+:4]})-$signed({1'b0,_w___block_1_obscure_clmp[0+:4]}));
assign _w___block_1_opaque = ~_q_tcol_rdy&~_q_skip[0+:1]&(_w_sampler_smplr_texel!=255);
assign _w___block_1_bkg = _q_sampler_io_tex_id==0;
assign _w___block_1_wc_u_8 = (_q_wc_u);
assign _w___block_1_wc_v_8 = (_q_wc_v>>11);
assign _w___block_1_result = (_q_a*_q_b)+_q_c;
assign _w___block_27_pixcoord = _q_current;
assign _w___block_29_neg_dot_ray = -_q_dot_ray;
assign _w___block_33_tex_id = in_in_command[0+:10];
assign _w___block_33_bkg_tex_id = _w___block_33_tex_id==0;
assign _w___block_35_still_drawing = _w_terrain ? ~_w_terrain_done:(~_w_current_done|_q_skip[0+:1]);
assign _w___block_41_scrh = (_w___block_1_result>>>8)+16'd120;
assign _w___block_41_end_next = _w___block_41_scrh[15+:1] ? 8'b0:(_w___block_41_scrh<_w_col_end ? _w___block_41_scrh[0+:8]:_w_col_end);
assign _w___block_43_next_tcol_rdy = _w_terrain&_w_current_done;
assign _w___block_43_step_shift = _q_tcol_dist[17+:2];
assign _w___block_43_terrain_step = 16'd2048<<_w___block_43_step_shift;
assign _w___block_43_tc_v_inc = _w_scrd_inc;
assign _w___block_43_wc_v_inc = $signed(in_in_command[32+:14]);

`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_sampler_io_tex_id = _q_sampler_io_tex_id;
_d_drawing = _q_drawing;
_d_current = _q_current;
_d_end = _q_end;
_d_pickh_done = _q_pickh_done;
_d_dot_u = _q_dot_u;
_d_dot_v = _q_dot_v;
_d_dot_ray = _q_dot_ray;
_d_ded = _q_ded;
_d_ny_inc = _q_ny_inc;
_d_uy_inc = _q_uy_inc;
_d_vy_inc = _q_vy_inc;
_d_ray_t = _q_ray_t;
_d_u_offset = _q_u_offset;
_d_v_offset = _q_v_offset;
_d_view_z = _q_view_z;
_d_tcol_rdy = _q_tcol_rdy;
_d_tcol_dist = _q_tcol_dist;
_d_prev_tcol_dist = _q_prev_tcol_dist;
_d_scrh_diff = _q_scrh_diff;
_d_cosray = _q_cosray;
_d_sinray = _q_sinray;
_d_state = _q_state;
_d_wc_v = _q_wc_v;
_d_wc_u = _q_wc_u;
_d_tc_v = _q_tc_v;
_d_tr_u = _q_tr_u;
_d_tr_v = _q_tr_v;
_d_a = _q_a;
_d_b = _q_b;
_d_c = _q_c;
_d_smplr_delay = _q_smplr_delay;
_d_start = _q_start;
_d_skip = _q_skip;
_d_busy = _q_busy;
_d_pickedh = _q_pickedh;
_t_inv_y_wenable = 0;
_t_inv_y_wdata = 0;
// _always_pre
// __block_1
  case ({_w_terrain,_q_state})
  0: begin
// __block_3_case
// __block_4
_d_a = $signed(_w_mem_inv_y_rdata);

_d_b = $signed(_q_ded);

_d_c = {24{1'b0}};

// __block_5
  end
  1: begin
// __block_6_case
// __block_7
_d_ray_t = _w___block_1_result>>>6;

_d_a = $signed(_d_ray_t);

_d_b = $signed(_q_dot_u);

// __block_8
  end
  2: begin
// __block_9_case
// __block_10
_d_tr_u = ((_w___block_1_result>>>10)+$signed(_q_u_offset));

_d_b = $signed(_q_dot_v);

// __block_11
  end
  3: begin
// __block_12_case
// __block_13
_d_tr_v = ((_w___block_1_result>>>10)+$signed(_q_v_offset));

// __block_14
  end
  16: begin
// __block_15_case
// __block_16
_d_a = _w_terrain_dist;

_d_b = $signed(_q_cosray);

_d_c = {24{1'b0}};

// __block_17
  end
  17: begin
// __block_18_case
// __block_19
_d_tr_u = ($signed(_w___block_1_result>>>2)+$signed(_q_u_offset));

_d_a = _w_terrain_dist;

_d_b = $signed(_q_sinray);

_d_c = {24{1'b0}};

// __block_20
  end
  18: begin
// __block_21_case
// __block_22
_d_tr_v = ($signed(_w___block_1_result>>>2)+$signed(_q_v_offset));

// __block_23
  end
  default: begin
// __block_24_case
// __block_25
_d_a = _w_mem_inv_y_rdata;

_d_b = ($signed({1'b0,_w_sampler_smplr_texel})-$signed(_q_view_z));

// __block_26
  end
endcase
// __block_2
_d_state = _q_state[3+:1] ? _q_state:(_q_state+1);

// __block_27
_t_colbufs_addr1 = {in_buffer,_w___block_27_pixcoord[0+:8]};

_t_colbufs_wdata1 = {(_w___block_1_light[4+:1] ? 4'b0:_w___block_1_light[0+:4])|(_w___block_1_bkg ? 4'd15:4'd0),_w_sampler_smplr_texel};

_t_colbufs_wenable1 = _q_smplr_delay[12+:1]&_w___block_1_depth_ok&_w___block_1_opaque;

_t_depths_addr0 = _w___block_27_pixcoord;

_t_depths_addr1 = _w___block_27_pixcoord;

_t_depths_wdata1 = {in_buffer,_w___block_1_dist};

_t_depths_wenable1 = _q_smplr_delay[12+:1]&_w___block_1_depth_ok&_w___block_1_opaque;

// __block_28
_t_sampler_io_do_bind = 0;

_t_sampler_io_do_fetch = 0;

_t_sampler_io_u = (_w_plane ? _d_tr_u[10+:8]:11'b0)|(_w_wall ? {3'b0,_w___block_1_wc_u_8}:11'b0)|(_w_terrain ? {1'b0,_d_tr_u[12+:10]}:11'b0);

_t_sampler_io_v = (_w_plane ? {1'b0,_d_tr_v[10+:8]}:11'b0)|(_w_wall ? {3'b0,_w___block_1_wc_v_8}:11'b0)|(_w_terrain ? {~_w_current_done,_d_tr_v[12+:10]}:11'b0);

// __block_29
_t_inv_y_addr = _w_terrain ? (_q_tcol_rdy ? _q_tcol_dist[8+:11]:_q_scrh_diff):(_q_dot_ray[23+:1] ? _w___block_29_neg_dot_ray[8+:11]:_q_dot_ray[8+:11]);

// __block_30
if (in_in_start) begin
// __block_31
// __block_33
_d_end = _w_terrain ? _w_col_start:_w_col_end;

_d_current = _w_col_start;

_d_cosray = _w_ray_cs ? $signed(in_in_command[32+:14]):_q_cosray;

_d_sinray = _w_ray_cs ? $signed(in_in_command[46+:14]):_q_sinray;

_d_u_offset = _w_uv_offs ? $signed(in_in_command[1+:24]):_q_u_offset;

_d_v_offset = _w_uv_offs ? $signed(in_in_command[32+:24]):_q_v_offset;

_d_view_z = _w_set_vwz ? $signed(in_in_command[32+:16]):_q_view_z;

_d_ny_inc = _w_planeA ? $signed(in_in_command[32+:10]):_q_ny_inc;

_d_uy_inc = _w_planeA ? $signed(in_in_command[42+:10]):_q_uy_inc;

_d_vy_inc = _w_planeA ? $signed(in_in_command[52+:10]):_q_vy_inc;

_d_dot_u = _w_planeA ? $signed({in_in_command[1+:14],8'b0}):_q_dot_u;

_d_dot_v = _w_planeA ? $signed({in_in_command[15+:14],8'b0}):_q_dot_v;

_d_ded = _w_plane ? $signed(in_in_command[32+:16]):_q_ded;

_d_dot_ray = _w_plane ? $signed({in_in_command[48+:16],8'b0}):_q_dot_ray;

_t_sampler_io_do_bind = (_w___block_33_tex_id!=_q_sampler_io_tex_id)&~_w_param&~_w___block_33_bkg_tex_id;

_d_sampler_io_tex_id = ~_w_param ? _w___block_33_tex_id:_q_sampler_io_tex_id;

_d_wc_u = $signed(in_in_command[56+:8]);

_d_wc_v = $signed({in_in_command[48+:8],11'b0});

_d_tc_v = $signed({in_in_command[48+:11],8'b0});

_d_tcol_dist = $signed({in_in_command[48+:11],8'b0});

_d_prev_tcol_dist = $signed({in_in_command[48+:11],8'b0});

_d_drawing = ~_w_param;

_d_start = ~_w_param;

_d_skip = 3'b011;

_d_tcol_rdy = 0;

_d_pickh_done = 0;

// __block_34
end else begin
// __block_32
// __block_35
_t_sampler_io_do_fetch = ~_w___block_1_bkg&_w___block_35_still_drawing&_q_smplr_delay[11+:1];

if (_q_smplr_delay[12+:1]) begin
// __block_36
// __block_38
_d_drawing = _w___block_35_still_drawing;

if (_q_tcol_rdy) begin
// __block_39
// __block_41
_d_scrh_diff = _w___block_41_end_next-_q_current;

_d_tcol_rdy = 0;

_d_tc_v = _q_prev_tcol_dist;

_d_end = _w___block_41_end_next;

_d_pickedh = _w_pickh&~_q_pickh_done ? _w_sampler_smplr_texel:_q_pickedh;

_d_pickh_done = 1;

// __block_42
end else begin
// __block_40
// __block_43
_d_tcol_rdy = _w___block_43_next_tcol_rdy;

_d_prev_tcol_dist = _w___block_43_next_tcol_rdy ? _q_tcol_dist:_q_prev_tcol_dist;

_d_tcol_dist = _w___block_43_next_tcol_rdy ? (_q_tcol_dist+_w___block_43_terrain_step):_q_tcol_dist;

_d_current = (_w_current_done|_q_skip[0+:1]) ? _q_current:(_q_current+1);

_d_tc_v = _q_skip[0+:1] ? _q_tc_v:(_q_tc_v+_w___block_43_tc_v_inc);

_d_wc_v = _q_wc_v+_w___block_43_wc_v_inc;

_d_dot_ray = _q_dot_ray+_q_ny_inc;

_d_dot_u = _q_dot_u+_q_uy_inc;

_d_dot_v = _q_dot_v+_q_vy_inc;

_d_skip = _q_skip[1+:1] ? (_q_skip>>1):{2'b0,_w_terrain&_w_current_done};

// __block_44
end
// __block_45
// __block_46
end else begin
// __block_37
end
// __block_47
if (_q_smplr_delay[12+:1]) begin
// __block_48
// __block_50
_d_smplr_delay = _w___block_1_bkg ? {1'b1,11'b0}:{8'b0,_w_plane|_w_wall,1'b0,1'b0,_w_terrain};

_d_state = 0;

// __block_51
end else begin
// __block_49
// __block_52
_d_smplr_delay = (~_d_drawing|~_w_sampler_smplr_ready|_q_start) ? (_w___block_1_bkg ? {1'b1,11'b0}:{8'b0,_w_plane|_w_wall,1'b0,1'b0,_w_terrain}):{_q_smplr_delay[0+:12],_q_smplr_delay[12+:1]};

if (_q_start) begin
// __block_53
// __block_55
_d_state = 0;

// __block_56
end else begin
// __block_54
end
// __block_57
_d_start = (_q_start&~_w_sampler_smplr_ready);

// __block_58
end
// __block_59
// __block_60
end
// __block_61
_d_busy = _d_drawing|~_w_sampler_smplr_ready;

// __block_62
// _always_post
end

always @(posedge clock) begin
_q_sampler_io_tex_id <= _d_sampler_io_tex_id;
_q_drawing <= _d_drawing;
_q_current <= _d_current;
_q_end <= _d_end;
_q_pickh_done <= _d_pickh_done;
_q_dot_u <= _d_dot_u;
_q_dot_v <= _d_dot_v;
_q_dot_ray <= _d_dot_ray;
_q_ded <= _d_ded;
_q_ny_inc <= _d_ny_inc;
_q_uy_inc <= _d_uy_inc;
_q_vy_inc <= _d_vy_inc;
_q_ray_t <= _d_ray_t;
_q_u_offset <= _d_u_offset;
_q_v_offset <= _d_v_offset;
_q_view_z <= _d_view_z;
_q_tcol_rdy <= _d_tcol_rdy;
_q_tcol_dist <= _d_tcol_dist;
_q_prev_tcol_dist <= _d_prev_tcol_dist;
_q_scrh_diff <= _d_scrh_diff;
_q_cosray <= _d_cosray;
_q_sinray <= _d_sinray;
_q_state <= _d_state;
_q_wc_v <= _d_wc_v;
_q_wc_u <= _d_wc_u;
_q_tc_v <= _d_tc_v;
_q_tr_u <= _d_tr_u;
_q_tr_v <= _d_tr_v;
_q_a <= _d_a;
_q_b <= _d_b;
_q_c <= _d_c;
_q_smplr_delay <= _d_smplr_delay;
_q_start <= _d_start;
_q_skip <= _d_skip;
_q_busy <= _d_busy;
_q_pickedh <= _d_pickedh;
end

endmodule


// SL 2019, MIT license
module M_column_sender__gpu_sender_mem_palette(
input                  [8-1:0] in_addr,
output reg  [18-1:0] out_rdata,
input                                     clock
);
(* no_rw_check *) reg  [18-1:0] buffer[256-1:0];
always @(posedge clock) begin
   out_rdata <= buffer[in_addr];
end
initial begin
 buffer[0] = 0;
 buffer[1] = 28994;
 buffer[2] = 20673;
 buffer[3] = 74898;
 buffer[4] = 262143;
 buffer[5] = 24966;
 buffer[6] = 16644;
 buffer[7] = 8322;
 buffer[8] = 4161;
 buffer[9] = 45895;
 buffer[10] = 33411;
 buffer[11] = 20929;
 buffer[12] = 12608;
 buffer[13] = 78730;
 buffer[14] = 70408;
 buffer[15] = 62086;
 buffer[16] = 260973;
 buffer[17] = 252586;
 buffer[18] = 248360;
 buffer[19] = 239973;
 buffer[20] = 235747;
 buffer[21] = 227425;
 buffer[22] = 223134;
 buffer[23] = 214812;
 buffer[24] = 206490;
 buffer[25] = 202264;
 buffer[26] = 193942;
 buffer[27] = 189781;
 buffer[28] = 181459;
 buffer[29] = 177233;
 buffer[30] = 168911;
 buffer[31] = 164750;
 buffer[32] = 156428;
 buffer[33] = 152267;
 buffer[34] = 144010;
 buffer[35] = 139784;
 buffer[36] = 131527;
 buffer[37] = 127366;
 buffer[38] = 119109;
 buffer[39] = 114948;
 buffer[40] = 106691;
 buffer[41] = 102530;
 buffer[42] = 94273;
 buffer[43] = 90177;
 buffer[44] = 81985;
 buffer[45] = 77824;
 buffer[46] = 69632;
 buffer[47] = 65536;
 buffer[48] = 261815;
 buffer[49] = 261684;
 buffer[50] = 261553;
 buffer[51] = 261422;
 buffer[52] = 261356;
 buffer[53] = 261225;
 buffer[54] = 261094;
 buffer[55] = 261028;
 buffer[56] = 260896;
 buffer[57] = 252574;
 buffer[58] = 244252;
 buffer[59] = 235930;
 buffer[60] = 227608;
 buffer[61] = 219286;
 buffer[62] = 210964;
 buffer[63] = 206803;
 buffer[64] = 194450;
 buffer[65] = 182033;
 buffer[66] = 173776;
 buffer[67] = 165519;
 buffer[68] = 157198;
 buffer[69] = 144845;
 buffer[70] = 136524;
 buffer[71] = 128267;
 buffer[72] = 120010;
 buffer[73] = 107593;
 buffer[74] = 95240;
 buffer[75] = 82887;
 buffer[76] = 74566;
 buffer[77] = 62149;
 buffer[78] = 49796;
 buffer[79] = 41475;
 buffer[80] = 245499;
 buffer[81] = 237177;
 buffer[82] = 228855;
 buffer[83] = 224694;
 buffer[84] = 216372;
 buffer[85] = 208050;
 buffer[86] = 203889;
 buffer[87] = 195567;
 buffer[88] = 187245;
 buffer[89] = 183084;
 buffer[90] = 174762;
 buffer[91] = 170601;
 buffer[92] = 162279;
 buffer[93] = 153957;
 buffer[94] = 149796;
 buffer[95] = 141474;
 buffer[96] = 133152;
 buffer[97] = 128991;
 buffer[98] = 120669;
 buffer[99] = 112347;
 buffer[100] = 108186;
 buffer[101] = 99864;
 buffer[102] = 91542;
 buffer[103] = 87381;
 buffer[104] = 79059;
 buffer[105] = 70737;
 buffer[106] = 66576;
 buffer[107] = 58254;
 buffer[108] = 54093;
 buffer[109] = 45771;
 buffer[110] = 37449;
 buffer[111] = 33288;
 buffer[112] = 122843;
 buffer[113] = 114393;
 buffer[114] = 105943;
 buffer[115] = 97493;
 buffer[116] = 93139;
 buffer[117] = 84689;
 buffer[118] = 76239;
 buffer[119] = 67853;
 buffer[120] = 63499;
 buffer[121] = 55050;
 buffer[122] = 46600;
 buffer[123] = 38150;
 buffer[124] = 29701;
 buffer[125] = 21251;
 buffer[126] = 16898;
 buffer[127] = 8513;
 buffer[128] = 195171;
 buffer[129] = 186849;
 buffer[130] = 178527;
 buffer[131] = 170205;
 buffer[132] = 161883;
 buffer[133] = 157658;
 buffer[134] = 149400;
 buffer[135] = 141078;
 buffer[136] = 132757;
 buffer[137] = 124435;
 buffer[138] = 120274;
 buffer[139] = 111952;
 buffer[140] = 103695;
 buffer[141] = 95373;
 buffer[142] = 87052;
 buffer[143] = 82891;
 buffer[144] = 161816;
 buffer[145] = 145236;
 buffer[146] = 132754;
 buffer[147] = 120271;
 buffer[148] = 103692;
 buffer[149] = 91210;
 buffer[150] = 78728;
 buffer[151] = 66310;
 buffer[152] = 124888;
 buffer[153] = 112405;
 buffer[154] = 104083;
 buffer[155] = 91665;
 buffer[156] = 83278;
 buffer[157] = 70860;
 buffer[158] = 62538;
 buffer[159] = 54217;
 buffer[160] = 262108;
 buffer[161] = 241045;
 buffer[162] = 220048;
 buffer[163] = 199051;
 buffer[164] = 178055;
 buffer[165] = 157060;
 buffer[166] = 136193;
 buffer[167] = 115328;
 buffer[168] = 262143;
 buffer[169] = 261558;
 buffer[170] = 261038;
 buffer[171] = 260518;
 buffer[172] = 259998;
 buffer[173] = 259543;
 buffer[174] = 259023;
 buffer[175] = 258503;
 buffer[176] = 258048;
 buffer[177] = 241664;
 buffer[178] = 229376;
 buffer[179] = 217088;
 buffer[180] = 204800;
 buffer[181] = 192512;
 buffer[182] = 180224;
 buffer[183] = 167936;
 buffer[184] = 155648;
 buffer[185] = 139264;
 buffer[186] = 126976;
 buffer[187] = 114688;
 buffer[188] = 102400;
 buffer[189] = 90112;
 buffer[190] = 77824;
 buffer[191] = 65536;
 buffer[192] = 237183;
 buffer[193] = 203903;
 buffer[194] = 174783;
 buffer[195] = 145663;
 buffer[196] = 116543;
 buffer[197] = 83263;
 buffer[198] = 54143;
 buffer[199] = 25023;
 buffer[200] = 63;
 buffer[201] = 56;
 buffer[202] = 50;
 buffer[203] = 44;
 buffer[204] = 38;
 buffer[205] = 32;
 buffer[206] = 26;
 buffer[207] = 20;
 buffer[208] = 262143;
 buffer[209] = 261814;
 buffer[210] = 261486;
 buffer[211] = 261222;
 buffer[212] = 260894;
 buffer[213] = 260630;
 buffer[214] = 260302;
 buffer[215] = 260038;
 buffer[216] = 247557;
 buffer[217] = 239299;
 buffer[218] = 226883;
 buffer[219] = 218562;
 buffer[220] = 206145;
 buffer[221] = 197824;
 buffer[222] = 185408;
 buffer[223] = 177152;
 buffer[224] = 262143;
 buffer[225] = 262133;
 buffer[226] = 262124;
 buffer[227] = 262115;
 buffer[228] = 262106;
 buffer[229] = 262097;
 buffer[230] = 262088;
 buffer[231] = 262080;
 buffer[232] = 168896;
 buffer[233] = 160576;
 buffer[234] = 148160;
 buffer[235] = 135680;
 buffer[236] = 78729;
 buffer[237] = 66246;
 buffer[238] = 53764;
 buffer[239] = 45442;
 buffer[240] = 20;
 buffer[241] = 17;
 buffer[242] = 14;
 buffer[243] = 11;
 buffer[244] = 8;
 buffer[245] = 5;
 buffer[246] = 2;
 buffer[247] = 0;
 buffer[248] = 260560;
 buffer[249] = 261714;
 buffer[250] = 260031;
 buffer[251] = 258111;
 buffer[252] = 208947;
 buffer[253] = 159782;
 buffer[254] = 110618;
 buffer[255] = 169626;
end

endmodule

module M_column_sender__gpu_sender (
in_in_start,
in_buffer,
in_colbufs_rdata0,
in_screen_ready,
out_colbufs_addr0,
out_screen_valid,
out_screen_data,
out_busy,
reset,
out_clock,
clock
);
input  [0:0] in_in_start;
input  [0:0] in_buffer;
input  [12-1:0] in_colbufs_rdata0;
input  [0:0] in_screen_ready;
output  [9-1:0] out_colbufs_addr0;
output  [0:0] out_screen_valid;
output  [15:0] out_screen_data;
output  [0:0] out_busy;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
wire  [17:0] _w_mem_palette_rdata;
reg  [7:0] _t_palette_addr;
reg  [9-1:0] _t_colbufs_addr0;
wire  [3:0] _w___block_1_light;
wire  [9:0] _w___block_1_ro;
wire  [9:0] _w___block_1_go;
wire  [9:0] _w___block_1_bo;
wire  [5:0] _w___block_1_r;
wire  [5:0] _w___block_1_g;
wire  [5:0] _w___block_1_b;

reg  [7:0] _d_count = 0;
reg  [7:0] _q_count = 0;
reg  [0:0] _d_done = 0;
reg  [0:0] _q_done = 0;
reg  [0:0] _d_screen_valid = 0;
reg  [0:0] _q_screen_valid = 0;
reg  [15:0] _d_screen_data = 0;
reg  [15:0] _q_screen_data = 0;
reg  [0:0] _d_busy = 1;
reg  [0:0] _q_busy = 1;
assign out_colbufs_addr0 = _t_colbufs_addr0;
assign out_screen_valid = _q_screen_valid;
assign out_screen_data = _q_screen_data;
assign out_busy = _q_busy;

M_column_sender__gpu_sender_mem_palette __mem__palette(
.clock(clock),
.in_addr(_t_palette_addr),
.out_rdata(_w_mem_palette_rdata)
);

assign _w___block_1_light = in_colbufs_rdata0[8+:4];
assign _w___block_1_ro = _w_mem_palette_rdata[12+:6]*_w___block_1_light;
assign _w___block_1_go = _w_mem_palette_rdata[6+:6]*_w___block_1_light;
assign _w___block_1_bo = _w_mem_palette_rdata[0+:6]*_w___block_1_light;
assign _w___block_1_r = _w___block_1_ro>>4;
assign _w___block_1_g = _w___block_1_go>>4;
assign _w___block_1_b = _w___block_1_bo>>4;

`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_count = _q_count;
_d_done = _q_done;
_d_screen_valid = _q_screen_valid;
_d_screen_data = _q_screen_data;
_d_busy = _q_busy;
// _always_pre
// __block_1
_d_done = in_in_start ? 0:(((_q_count==8'd240-1)&in_screen_ready)|_q_done);

_d_busy = ~_d_done;

_d_screen_valid = ~_d_done;

_d_screen_data = {_w___block_1_r[1+:5],_w___block_1_g[0+:6],_w___block_1_b[1+:5]};

_d_count = reset ? 8'd240:in_in_start ? 0:((~_d_done&in_screen_ready) ? _q_count+1:_q_count);

_t_palette_addr = reset ? 0:in_colbufs_rdata0[0+:8];

_t_colbufs_addr0 = {in_buffer,_d_count[0+:8]};

// __block_2
// _always_post
end

always @(posedge clock) begin
_q_count <= _d_count;
_q_done <= _d_done;
_q_screen_valid <= _d_screen_valid;
_q_screen_data <= _d_screen_data;
_q_busy <= _d_busy;
end

endmodule


// SL 2019, MIT license
module M_DMC_1_gpu__gpu_mem_colbufs(
input      [9-1:0]                in_addr0,
output reg  [12-1:0]     out_rdata0,
output reg  [12-1:0]     out_rdata1,
input      [1-1:0]             in_wenable1,
input      [12-1:0]                 in_wdata1,
input      [9-1:0]                in_addr1,
input      clock0,
input      clock1
);
(* no_rw_check *) reg  [12-1:0] buffer[512-1:0];
always @(posedge clock0) begin
  out_rdata0 <= buffer[in_addr0];
end
always @(posedge clock1) begin
  if (in_wenable1) begin
    buffer[in_addr1] <= in_wdata1;
  end
end

endmodule

module M_DMC_1_gpu__gpu (
in_valid,
in_command,
in_screen_ready,
in_txm_data,
in_txm_data_available,
in_txm_busy,
out_ready,
out_screen_valid,
out_screen_data,
out_pickedh,
out_txm_in_ready,
out_txm_addr,
reset,
out_clock,
clock
);
input  [0:0] in_valid;
input  [63:0] in_command;
input  [0:0] in_screen_ready;
input  [8-1:0] in_txm_data;
input  [1-1:0] in_txm_data_available;
input  [1-1:0] in_txm_busy;
output  [0:0] out_ready;
output  [0:0] out_screen_valid;
output  [15:0] out_screen_data;
output  [7:0] out_pickedh;
output  [1-1:0] out_txm_in_ready;
output  [24-1:0] out_txm_addr;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
wire  [9-1:0] _w_drawer_colbufs_addr1;
wire  [1-1:0] _w_drawer_colbufs_wenable1;
wire  [12-1:0] _w_drawer_colbufs_wdata1;
wire  [0:0] _w_drawer_busy;
wire  [7:0] _w_drawer_pickedh;
wire  [1-1:0] _w_drawer_txm_in_ready;
wire  [24-1:0] _w_drawer_txm_addr;
wire  [9-1:0] _w_sender_colbufs_addr0;
wire  [0:0] _w_sender_screen_valid;
wire  [15:0] _w_sender_screen_data;
wire  [0:0] _w_sender_busy;
wire  [11:0] _w_mem_colbufs_rdata0;
wire  [7:0] _w___block_6_start;
wire  [7:0] _w___block_6_end;
wire  [0:0] _w___block_6_param;
wire  [0:0] _w___block_6_empty;
wire  [0:0] _w___block_6_eoc;
wire  [0:0] _w___block_6_do_draw;
wire  [0:0] _w___block_6_do_send;

reg  [0:0] _d_draw_buffer = 0;
reg  [0:0] _q_draw_buffer = 0;
reg  [63:0] _d_next_command = 0;
reg  [63:0] _q_next_command = 0;
reg  [0:0] _d_next_pending = 0;
reg  [0:0] _q_next_pending = 0;
reg  [0:0] _d__drawer_in_start = 0;
reg  [0:0] _q__drawer_in_start = 0;
reg  [63:0] _d__drawer_in_command = 0;
reg  [63:0] _q__drawer_in_command = 0;
reg  [0:0] _d__drawer_buffer = 0;
reg  [0:0] _q__drawer_buffer = 0;
reg  [0:0] _d__sender_in_start = 0;
reg  [0:0] _q__sender_in_start = 0;
reg  [0:0] _d__sender_buffer = 0;
reg  [0:0] _q__sender_buffer = 0;
reg  [0:0] _d_ready = 0;
reg  [0:0] _q_ready = 0;
assign out_ready = _q_ready;
assign out_screen_valid = _w_sender_screen_valid;
assign out_screen_data = _w_sender_screen_data;
assign out_pickedh = _w_drawer_pickedh;
assign out_txm_in_ready = _w_drawer_txm_in_ready;
assign out_txm_addr = _w_drawer_txm_addr;
M_span_drawer__gpu_drawer drawer (
.in_in_start(_q__drawer_in_start),
.in_in_command(_q__drawer_in_command),
.in_buffer(_q__drawer_buffer),
.in_txm_data(in_txm_data),
.in_txm_data_available(in_txm_data_available),
.in_txm_busy(in_txm_busy),
.out_colbufs_addr1(_w_drawer_colbufs_addr1),
.out_colbufs_wenable1(_w_drawer_colbufs_wenable1),
.out_colbufs_wdata1(_w_drawer_colbufs_wdata1),
.out_busy(_w_drawer_busy),
.out_pickedh(_w_drawer_pickedh),
.out_txm_in_ready(_w_drawer_txm_in_ready),
.out_txm_addr(_w_drawer_txm_addr),
.reset(reset),
.clock(clock));
M_column_sender__gpu_sender sender (
.in_in_start(_q__sender_in_start),
.in_buffer(_q__sender_buffer),
.in_colbufs_rdata0(_w_mem_colbufs_rdata0),
.in_screen_ready(in_screen_ready),
.out_colbufs_addr0(_w_sender_colbufs_addr0),
.out_screen_valid(_w_sender_screen_valid),
.out_screen_data(_w_sender_screen_data),
.out_busy(_w_sender_busy),
.reset(reset),
.clock(clock));

M_DMC_1_gpu__gpu_mem_colbufs __mem__colbufs(
.clock0(clock),
.clock1(clock),
.in_addr0(_w_sender_colbufs_addr0),
.in_wenable1(_w_drawer_colbufs_wenable1),
.in_wdata1(_w_drawer_colbufs_wdata1),
.in_addr1(_w_drawer_colbufs_addr1),
.out_rdata0(_w_mem_colbufs_rdata0)
);

assign _w___block_6_start = _q_next_command[10+:8];
assign _w___block_6_end = _q_next_command[18+:8];
assign _w___block_6_param = &(_q_next_command[30+:2]);
assign _w___block_6_empty = ~_w___block_6_param&(_w___block_6_start>_w___block_6_end);
assign _w___block_6_eoc = _w___block_6_param&_q_next_command[0+:1];
assign _w___block_6_do_draw = _q_next_pending&~_w___block_6_eoc&~_w_drawer_busy;
assign _w___block_6_do_send = _q_next_pending&_w___block_6_eoc&~_w_drawer_busy&~_w_sender_busy;

`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d_draw_buffer = _q_draw_buffer;
_d_next_command = _q_next_command;
_d_next_pending = _q_next_pending;
_d__drawer_in_start = _q__drawer_in_start;
_d__drawer_in_command = _q__drawer_in_command;
_d__drawer_buffer = _q__drawer_buffer;
_d__sender_in_start = _q__sender_in_start;
_d__sender_buffer = _q__sender_buffer;
_d_ready = _q_ready;
// _always_pre
// __block_1
_d__sender_in_start = 0;

_d__drawer_in_start = 0;

if (in_valid&~_q_next_pending) begin
// __block_2
// __block_4
_d_next_command = in_command;

_d_next_pending = 1;

// __block_5
end else begin
// __block_3
// __block_6
_d__drawer_in_command = (_w___block_6_do_draw&~_w___block_6_empty) ? _q_next_command:_q__drawer_in_command;

_d__drawer_in_start = _w___block_6_do_draw&~_w___block_6_empty;

_d_draw_buffer = _w___block_6_do_send^_q_draw_buffer;

_d__sender_in_start = _w___block_6_do_send;

_d_next_pending = _q_next_pending&~(_w___block_6_do_draw|_w___block_6_do_send);

// __block_7
end
// __block_8
_d_ready = ~_d_next_pending;

_d__drawer_buffer = _d_draw_buffer;

_d__sender_buffer = ~_d_draw_buffer;

// __block_9
// _always_post
end

always @(posedge clock) begin
_q_draw_buffer <= _d_draw_buffer;
_q_next_command <= _d_next_command;
_q_next_pending <= _d_next_pending;
_q__drawer_in_start <= _d__drawer_in_start;
_q__drawer_in_command <= _d__drawer_in_command;
_q__drawer_buffer <= _d__drawer_buffer;
_q__sender_in_start <= _d__sender_in_start;
_q__sender_buffer <= _d__sender_buffer;
_q_ready <= _d_ready;
end

endmodule


module M_DMC_1_gpu_standalone (
in_valid,
in_command,
in_screen_ready,
in_clock2x,
out_ready,
out_screen_valid,
out_screen_data,
out_ram_clk,
out_ram_csn,
inout_ram_io0,
inout_ram_io1,
inout_ram_io2,
inout_ram_io3,
in_run,
out_done,
reset,
out_clock,
clock
);
input  [0:0] in_valid;
input  [63:0] in_command;
input  [0:0] in_screen_ready;
input  [0:0] in_clock2x;
output  [0:0] out_ready;
output  [0:0] out_screen_valid;
output  [15:0] out_screen_data;
output  [0:0] out_ram_clk;
output  [0:0] out_ram_csn;
inout  [0:0] inout_ram_io0;
inout  [0:0] inout_ram_io1;
inout  [0:0] inout_ram_io2;
inout  [0:0] inout_ram_io3;
input in_run;
output out_done;
input reset;
output out_clock;
input clock;
assign out_clock = clock;
wire  [7:0] _w_txm_rdata;
wire  [0:0] _w_txm_busy;
wire  [0:0] _w_txm_rdata_available;
wire  [0:0] _w_txm_ram_csn;
wire  [0:0] _w_txm_ram_clk;
wire  [0:0] _w_adapterDataAvailable_unnamed_0_data_avail_high;
wire  [0:0] _w_gpu_ready;
wire  [0:0] _w_gpu_screen_valid;
wire  [15:0] _w_gpu_screen_data;
wire  [7:0] _w_gpu_pickedh;
wire  [1-1:0] _w_gpu_txm_in_ready;
wire  [24-1:0] _w_gpu_txm_addr;
wire  [7:0] _c__txm_wdata;
assign _c__txm_wdata = 0;
reg  [7:0] _t_txm_io_data;
reg  [0:0] _t_txm_io_busy;

reg  [0:0] _d__txm_in_ready = 0;
reg  [0:0] _q__txm_in_ready = 0;
reg  [23:0] _d__txm_addr = 0;
reg  [23:0] _q__txm_addr = 0;
reg  [0:0] _d__txm_wenable = 0;
reg  [0:0] _q__txm_wenable = 0;
assign out_ready = _w_gpu_ready;
assign out_screen_valid = _w_gpu_screen_valid;
assign out_screen_data = _w_gpu_screen_data;
assign out_ram_clk = _w_txm_ram_clk;
assign out_ram_csn = _w_txm_ram_csn;
assign out_done = 0;
M_qpsram_ram__txm txm (
.in_in_ready(_q__txm_in_ready),
.in_addr(_q__txm_addr),
.in_wdata(_c__txm_wdata),
.in_wenable(_q__txm_wenable),
.out_rdata(_w_txm_rdata),
.out_busy(_w_txm_busy),
.out_rdata_available(_w_txm_rdata_available),
.out_ram_csn(_w_txm_ram_csn),
.out_ram_clk(_w_txm_ram_clk),
.inout_ram_io0(inout_ram_io0),
.inout_ram_io1(inout_ram_io1),
.inout_ram_io2(inout_ram_io2),
.inout_ram_io3(inout_ram_io3),
.reset(reset),
.clock(in_clock2x));
M_adapterDataAvailable__adapterDataAvailable_unnamed_0 adapterDataAvailable_unnamed_0 (
.in_valid(_w_gpu_txm_in_ready),
.in_data_avail_pulse(_w_txm_rdata_available),
.out_data_avail_high(_w_adapterDataAvailable_unnamed_0_data_avail_high),
.clock(in_clock2x));
M_DMC_1_gpu__gpu gpu (
.in_valid(in_valid),
.in_command(in_command),
.in_screen_ready(in_screen_ready),
.in_txm_data(_t_txm_io_data),
.in_txm_data_available(_w_adapterDataAvailable_unnamed_0_data_avail_high),
.in_txm_busy(_t_txm_io_busy),
.out_ready(_w_gpu_ready),
.out_screen_valid(_w_gpu_screen_valid),
.out_screen_data(_w_gpu_screen_data),
.out_pickedh(_w_gpu_pickedh),
.out_txm_in_ready(_w_gpu_txm_in_ready),
.out_txm_addr(_w_gpu_txm_addr),
.reset(reset),
.clock(clock));



`ifdef FORMAL
initial begin
assume(reset);
end
`endif
always @* begin
_d__txm_in_ready = _q__txm_in_ready;
_d__txm_addr = _q__txm_addr;
_d__txm_wenable = _q__txm_wenable;
// _always_pre
// __block_1
_d__txm_in_ready = _w_gpu_txm_in_ready;

_d__txm_addr = _w_gpu_txm_addr;

_t_txm_io_data = _w_txm_rdata;

_t_txm_io_busy = _w_txm_busy;

_d__txm_wenable = 0;

// __block_2
// _always_post
end

always @(posedge clock) begin
_q__txm_in_ready <= _d__txm_in_ready;
_q__txm_addr <= _d__txm_addr;
_q__txm_wenable <= _d__txm_wenable;
end

endmodule

