hl.config({
	general = {
		-- size of border around windows
		-- int
		border_size = 1,
		-- gap between windows, also support (top, right, bottom, left)
		-- int
		gaps_in = 5,
		-- gap between windows and monitor egdes, also support (top, right, bottom, left)
		-- int
		gaps_out = { 10, 10, 25, 10 },
		-- gaps between windows and monitor edges for floating windows, also supports (top, right, bottom, left) -1 means default
		-- int
		float_gaps = 30,
		-- dwindle/master
		-- dwindle will be like a binary split, split each vertical or horizontal to 2 smaller exec-once
		-- master is like hvaing 1 big half screen and everything else is equally split on the other half screen
		-- str
		layout = "dwindle",
		-- enable click and drag on windows border to resize
		-- bool
		resize_on_border = true,
		-- extend the region around the border that you could click on to drag and reisze
		-- int
		extend_border_grab_area = 10, -- show a cursor icon when hovering over borders
		-- bool
		hover_icon_on_border = true,
		snap = {
			-- enable snapping for floating windows
			-- bool
			enabled = true,
			-- respect gaps between windows(set in general:gaps_in)
			-- bool
			respect_gaps = true,
		},
	},
	decoration = {
		-- rounding corner radius in px
		-- int
		rounding = 5,
		-- curve level for rounding,bigger is smoother 2.0 is circle, 4.0 is squircle
		-- float [0.0 - 10.0]
		rounding_power = 2.0,
		-- active windows opacity
		-- float [0 - 1]
		active_opacity = 1.0,
		-- inactive windows opacity
		-- float [0 - 1]
		inactive_opacity = 0.9,
		-- dimming of inactive windows
		-- bool
		dim_inactive = true,
		-- how much inactive windows should be dimmed [0.0 - 1.0]
		-- float [0 - 1]
		dim_strength = 0.1,
		-- whether the window border should be a part of the window
		-- bool
		border_part_of_window = true,
	},
	animations = {
		enabled = true,
	},
	dwindle = {
		-- Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
		preserve_split = true, -- You probably want this
	},
	xwayland = {
		force_zero_scaling = true,
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Default springs
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
