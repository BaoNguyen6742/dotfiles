local wezterm = require("wezterm")

local home = os.getenv("HOME") or wezterm.home_dir
local module = {}

function module.apply_to_config(config)
	-- Height and Width
	config.initial_cols = 120
	config.initial_rows = 30

	-- Fonts
	config.font_size = 15

	-- Color scheme
	config.color_scheme = "MaterialDark"

	config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" })

	config.background = {
		{
			source = { File = home .. "/Documents/Pic/bg_2B.png" },
			opacity = 0.95,
			hsb = {
				hue = 5.0,
				saturation = 1.2,
				brightness = 0.3,
			},
		},
	}
	config.foreground_text_hsb = {
		hue = 1.0,
		saturation = 1.0,
		brightness = 1.0,
	}
	config.colors = {
		scrollbar_thumb = "gray",
	}
end

return module
