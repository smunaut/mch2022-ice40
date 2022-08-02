CORE := lcd

RTL_SRCS_lcd := $(addprefix rtl/, \
	lcd_phy_mux.v \
	lcd_phy_raw.v \
	lcd_phy_full.v \
)

TESTBENCHES_lcd := \
	$(NULL)

include $(NO2BUILD_DIR)/core-magic.mk
