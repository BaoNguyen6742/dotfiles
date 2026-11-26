local monitors = require("hypr_lua.IO.monitors")

-- Keep other outputs usable without a machine-specific profile.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local positions = {}
local x, origin = 0, 0
local primary
for i, monitor in ipairs(monitors) do
	positions[i] = x
	if monitor.primary then
		assert(not primary, "Only one monitor can be primary")
		primary, origin = monitor, x
	end

	local width, height = monitor.mode:match("^(%d+)x(%d+)")
	assert(width, monitor.output .. " needs an explicit WIDTHxHEIGHT mode")
	assert(type(monitor.scale) == "number" and monitor.scale > 0, monitor.output .. " needs a numeric scale")
	local rotated = (monitor.transform or 0) % 2 == 1
	x = x + math.floor(tonumber(rotated and height or width) / monitor.scale + 0.5)
end

for i, monitor in ipairs(monitors) do
	local spec = {}
	for key, value in pairs(monitor) do
		if key ~= "workspace" and key ~= "primary" then
			spec[key] = value
		end
	end
	spec.position = ("%dx0"):format(positions[i] - origin)
	hl.monitor(spec)

	if monitor.workspace then
		hl.workspace_rule({ workspace = tostring(monitor.workspace), monitor = monitor.output, default = true })
	end
end

if primary then
	hl.on("hyprland.start", function()
		local monitor = hl.get_monitor(primary.output)
		if monitor then
			hl.dispatch(hl.dsp.focus({ monitor = monitor.name }))
		end
	end)
end

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
		follow_mouse = 1,
	},

	cursor = {
		no_hardware_cursors = 1,
	},
	-- misc = {
	-- 	vrr = 2,
	-- },
})
