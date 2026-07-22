hl.window_rule({
	name = "suppress-maximize-events",
	match = {
		class = ".*",
	},

	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "fullscreen-Genshin",

	match = {
		class = "^(genshinimpact.exe)$",
	},

	fullscreen = true,
	render_unfocused = true,
})

hl.window_rule({
	name = "float-genshin-launcher",

	match = {
		initial_class = "^steam_app_genshin$",
		initial_title = "^HoYoPlay$",
	},

	float = true,
	center = true,
})
