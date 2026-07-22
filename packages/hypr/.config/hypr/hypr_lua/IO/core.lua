hl.monitor({
	output = "desc:Shenzhen KTC Technology Group H27T22S 0x00000001",
	mode = "2560x1440@180.00",
	position = "0x0",
	scale = "1.67",
	vrr = 1,
})
hl.monitor({
	output = "desc:AOC 24B15H3 AP15536R03516",
	mode = "1920x1080@120",
	position = "-1920x0",
	scale = "1.0",
})
hl.monitor({
	output = "desc:AOC 24B15H3 AP15536R03560",
	mode = "1920x1080@120",
	position = "-3840x0",
	scale = "1.0",
})

hl.config({
	input = {
		kb_model = "",
		kb_layout = "us",
		kb_variant = "",
		kb_options = "",
		kb_rules = "",
		kb_file = "",
		numlock_by_default = true,
		resolve_binds_by_sym = true,

		-- mouse
		sensitivity = -0.1,
		accel_profile = "flat",
		force_no_accel = true,
		follow_mouse = 2,
	},

	cursor = {
		no_hardware_cursors = 1,
	},
	-- misc = {
	-- 	vrr = 2,
	-- },
})
