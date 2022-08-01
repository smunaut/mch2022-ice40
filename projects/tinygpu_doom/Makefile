# Project config
PROJ := tinygpu_doom

PROJ_DEPS := spi_slave no2ice40 no2misc lcd
PROJ_RTL_SRCS := $(addprefix rtl/, \
	dmc-1-gpu.v \
	gpu.v \
	lcd_top.v \
	sysmgr.v \
)
PROJ_TESTBENCHES = \
	gpu_tb \
	$(NULL)
PROJ_TOP_SRC := rtl/top.v
PROJ_TOP_MOD := top

# Toolchain config
YOSYS_SYNTH_ARGS = -dsp -device u -abc9
NEXTPNR_SEED ?= 1
NEXTPNR_ARGS = --no-promote-globals --seed $(NEXTPNR_SEED)

# Include default rules
include ../_common/build.mk
