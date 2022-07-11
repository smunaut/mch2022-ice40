	# We set clk_4x slightly lower because
	# (1) If we specify 125 MHz it errors out because of precision issues
	# (2) The max freq is 125 M due to fixed placement (no way to do better)
	# (3) We want to avoid error on this path and 124 ~ 126 is close enough

ctx.addClock("clk_1x",  32) # 31.5  MHz
ctx.addClock("clk_4x", 124) # 126   MHz

