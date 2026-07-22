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

bind("mouse:272", hl.dsp.window.drag())
bind("mouse:273", hl.dsp.window.resize())

bind("SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

hl.bind("mouse:276", hl.dsp.exec_cmd("~/.config/hypr/hypr_conf/Scripts/spam_F.sh"))
