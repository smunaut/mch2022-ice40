# Project config
PROJ := selftest

PROJ_DEPS := no2ice40 no2misc no2qpimem lcd spi_slave
PROJ_RTL_SRCS := $(addprefix rtl/, \
	lcd_wb.v \
	memtest.v \
	misc_wb.v \
	picorv32_ice40_regs.v \
	picorv32.v \
	soc_bram.v \
	soc_picorv32_base.v \
	soc_picorv32_bridge.v \
	soc_spram.v \
	spi_loopback.v \
	spi_msg_wb.v \
	sysmgr.v \
)
PROJ_PREREQ = \
	$(BUILD_TMP)/boot.hex \
	$(NULL)
PROJ_TESTBENCHES = \
	lcd_tb \
	$(NULL)
PROJ_TOP_SRC := rtl/top.v
PROJ_TOP_MOD := top

PROJ_BIN_FINAL = $(PROJ)-sw.bin

# Toolchain config
YOSYS_SYNTH_ARGS := -abc9 -device u

NEXTPNR_SEED ?= 15
NEXTPNR_ARGS = --no-promote-globals --pre-pack data/opt.py --pre-place $(CORE_no2ice40_DIR)/sw/serdes-nextpnr-place.py --seed $(NEXTPNR_SEED)

# Include default rules
include ../_common/build.mk

# Custom rules
$(BUILD_TMP)/boot.hex:
	icebram -g -s 0 32 2048 > $@

fw/fw_app.hex:
	make -C fw fw_app.hex

$(BUILD_TMP)/$(PROJ)-sw.asc: $(BUILD_TMP)/$(PROJ).asc $(BUILD_TMP)/boot.hex fw/fw_app.hex 
	cat $(BUILD_TMP)/$(PROJ).asc | icebram $(BUILD_TMP)/boot.hex fw/fw_app.hex > $@
