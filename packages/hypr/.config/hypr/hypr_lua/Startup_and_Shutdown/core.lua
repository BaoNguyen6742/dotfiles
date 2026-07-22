hl.on("hyprland.start", function()
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hypridle")
	hl.exec_cmd('ags run "$HOME/.config/ags/app.tsx" --log-file /tmp/ags.log')
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("dunst")
	hl.exec_cmd("wl-paste --type text  --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")

	hl.exec_cmd(
		'hyprctl --batch "dispatch moveworkspacetomonitor 3 desc:AOC 24B15H3 AP15536R03560 ; dispatch moveworkspacetomonitor 2 desc:AOC 24B15H3 AP15536R03516 ; dispatch moveworkspacetomonitor 1 desc:Shenzhen KTC Technology Group H27T22S 0x00000001 ; dispatch focusmonitor desc:AOC 24B15H3 AP15536R03560 ; dispatch workspace 3; dispatch focusmonitor desc:AOC 24B15H3 AP15536R03516 ; dispatch workspace 2 ; dispatch focusmonitor desc:Shenzhen KTC Technology Group H27T22S 0x00000001 ; dispatch workspace 1"'
	)
end)

hl.on("hyprland.shutdown", function()
	hl.exec_cmd("cliphist wipe")
end)
