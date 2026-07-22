-- local wezterm = require('wezterm')

local module = {}
-- local launch_menu = {}

function module.apply_to_config(config)
	config.launch_menu = {
		{ label = "Fish", args = { "fish" } },
	}
end

return module
