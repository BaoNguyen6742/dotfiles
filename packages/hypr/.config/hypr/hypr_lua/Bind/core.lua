local workspace = require("hypr_lua.Bind.workspace")

local terminal = "wezterm"
local file_manager = "thunar"
local menu = "rofi -show drun"

local main_mod = "SUPER"

local function bind(key, cmd)
	hl.bind(main_mod .. " + " .. key, cmd)
end

bind("Q", hl.dsp.exec_cmd(terminal))
bind("C", hl.dsp.window.close())
bind("E", hl.dsp.exec_cmd(file_manager))
bind("R", hl.dsp.exec_cmd(menu))
bind("V", hl.dsp.window.float({ action = "toggle" }))
bind("F", hl.dsp.window.fullscreen())
for i = 1, 10, 1 do
	local key = i % 10
	bind(key, hl.dsp.focus({ workspace = i }))
	bind(
		"SHIFT + " .. key,
		hl.dsp.window.move({
			workspace = i,
		})
	)
end

bind(
	"SHIFT + left",
	hl.dsp.focus({
		workspace = "e-1",
	})
)
bind(
	"SHIFT + right",
	hl.dsp.focus({
		workspace = "e+1",
	})
)

bind("CTRL + left", workspace.move_left)
bind("CTRL + right", workspace.move_right)
bind("ALT + left", workspace.swap_left)
bind("ALT + right", workspace.swap_right)

bind("mouse:272", hl.dsp.window.drag())
bind("mouse:273", hl.dsp.window.resize())

bind("SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

-- Print copies the selection; Super+Print opens it in Swappy.
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy"))
bind("SHIFT + Print", hl.dsp.exec_cmd("grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | satty -f -"))
bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty -f -'))

hl.bind("mouse:276", hl.dsp.exec_cmd("~/.config/hypr/hypr_conf/Scripts/spam_F.sh"))
