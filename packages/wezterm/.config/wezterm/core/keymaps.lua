local wezterm = require("wezterm")
local act = wezterm.action
local module = {}

function module.apply_to_config(config)
	config.keys = {
		{
			key = "w",
			mods = "CTRL|SHIFT",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		{
			key = "LeftArrow",
			mods = "ALT",
			action = wezterm.action.SplitPane({
				direction = "Left",
				size = { Percent = 50 },
			}),
		},
		{
			key = "RightArrow",
			mods = "ALT",
			action = wezterm.action.SplitPane({
				direction = "Right",
				size = { Percent = 50 },
			}),
		},
		{
			key = "UpArrow",
			mods = "ALT",
			action = wezterm.action.SplitPane({
				direction = "Up",
				size = { Percent = 50 },
			}),
		},
		{
			key = "DownArrow",
			mods = "ALT",
			action = wezterm.action.SplitPane({
				direction = "Down",
				size = { Percent = 50 },
			}),
		},
		{
			key = "w",
			mods = "ALT",
			action = wezterm.action.CloseCurrentPane({ confirm = true }),
		},
		{
			key = "LeftArrow",
			mods = "ALT|SHIFT",
			action = act.ActivatePaneDirection("Left"),
		},
		{
			key = "RightArrow",
			mods = "ALT|SHIFT",
			action = act.ActivatePaneDirection("Right"),
		},
		{
			key = "UpArrow",
			mods = "ALT|SHIFT",
			action = act.ActivatePaneDirection("Up"),
		},
		{
			key = "DownArrow",
			mods = "ALT|SHIFT",
			action = act.ActivatePaneDirection("Down"),
		},
		{
			key = "Backspace",
			mods = "CTRL",
			action = act.SendKey({ key = "w", mods = "CTRL" }),
		},
	}
end

return module
