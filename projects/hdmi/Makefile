# Project config
PROJ := hdmi

PROJ_DEPS := lcd spi_slave no2ice40 no2misc no2qpimem
PROJ_RTL_SRCS := $(addprefix rtl/, \
	lcd_top.v \
	hdmi_buf.v \
	hdmi_phy.v \
	hdmi_top.v \
	hdmi_tgen.v \
	hdmi_tmds_simple.v \
	memif_arb.v \
	spi_memwr.v \
	sysmgr.v \
)
PROJ_TOP_SRC := rtl/top.v
PROJ_TOP_MOD := top

# Toolchain config
YOSYS_SYNTH_ARGS=-abc9 -device u

NEXTPNR_SEED ?= 15
NEXTPNR_ARGS = --no-promote-globals --pre-pack data/clocks.py --pre-place $(CORE_no2ice40_DIR)/sw/serdes-nextpnr-place.py --seed $(NEXTPNR_SEED) --timing-allow-fail

# Include default rules
include ../_common/build.mk
