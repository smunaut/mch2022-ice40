# Project config
PROJ := psram_load

PROJ_DEPS := spi_slave no2ice40 no2misc no2qpimem
PROJ_RTL_SRCS := $(addprefix rtl/, \
	sysmgr.v \
)
PROJ_TOP_SRC := rtl/top.v
PROJ_TOP_MOD := top

# Toolchain config
NEXTPNR_ARGS = --no-promote-globals --pre-place $(CORE_no2ice40_DIR)/sw/serdes-nextpnr-place.py

# Include default rules
include ../_common/build.mk
