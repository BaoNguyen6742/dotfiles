local wezterm = require("wezterm")
local act = wezterm.action

local module = {}

function module.apply_to_config(config)
	-- Scroll bar
	config.enable_scroll_bar = true
	config.default_prog = { "fish" }
	config.window_close_confirmation = "NeverPrompt"
	config.exit_behavior = "Hold"
	config.skip_close_confirmation_for_processes_named = {
		"bash",
		"sh",
		"zsh",
		"fish",
		"tmux",
		"nu",
		"cmd.exe",
		"pwsh.exe",
		"powershell.exe",
		"wsl.exe",
		"wslhost.exe",
	}
	config.alternate_buffer_wheel_scroll_speed = 1
	config.mouse_bindings = {
		-- Scroll down by 10 lines when scrolling up
		{
			event = {
				Down = { streak = 1, button = { WheelUp = 1 } },
			},
			mods = "NONE",
			action = act.ScrollByLine(-3),
		},
		-- Scroll up by 10 lines when scrolling down
		{
			event = {
				Down = { streak = 1, button = { WheelDown = 1 } },
			},
			mods = "NONE",
			action = act.ScrollByLine(3),
		},
	}
end

return module
