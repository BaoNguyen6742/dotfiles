local function move_workspace(direction)
	local monitor = hl.get_monitor(direction)
	if monitor then
		hl.dispatch(hl.dsp.workspace.move({ monitor = monitor.name }))
	end
end

local function change_workspace_id(workspace_id, new_id)
	return hl.dispatch(hl.dsp.workspace.change_id({ workspace = workspace_id, id = new_id })).ok
end

local function swap_workspace_ids(current_id, target_id)
	local temporary_id = 100
	while hl.get_workspace(temporary_id) do
		temporary_id = temporary_id + 1
	end

	if not change_workspace_id(current_id, temporary_id) then
		return false
	end
	if not change_workspace_id(target_id, current_id) then
		change_workspace_id(temporary_id, current_id)
		return false
	end
	if not change_workspace_id(temporary_id, target_id) then
		change_workspace_id(current_id, target_id)
		change_workspace_id(temporary_id, current_id)
		return false
	end
	return true
end

local function find_adjacent_workspace(current_id, step)
	local target_workspace
	local closest_distance = math.huge
	for _, workspace in ipairs(hl.get_workspaces()) do
		if workspace.id and workspace.id > 0 then
			local distance = (workspace.id - current_id) * step
			if distance > 0 and distance < closest_distance then
				target_workspace = workspace
				closest_distance = distance
			end
		end
	end
	return target_workspace
end

local function swap_workspace_contents(step)
	local current_monitor = hl.get_active_monitor()
	local current_workspace = current_monitor and current_monitor.active_workspace
	local current_id = current_workspace and current_workspace.id
	if not current_id or current_id <= 0 then
		return
	end

	local target_workspace = find_adjacent_workspace(current_id, step)
	local target_monitor = target_workspace and target_workspace.monitor
	if not target_monitor then
		return
	end
	local target_id = target_workspace.id

	if current_monitor.name == target_monitor.name then
		swap_workspace_ids(current_id, target_id)
		return
	end

	local active_on_target = target_monitor.active_workspace
	if not active_on_target or active_on_target.id ~= target_id then
		local result = hl.dispatch(hl.dsp.focus({ workspace = target_id }))
		active_on_target = target_monitor.active_workspace
		if not result.ok or not active_on_target or active_on_target.id ~= target_id then
			return
		end
	end

	if not swap_workspace_ids(current_id, target_id) then
		return
	end
	local result = hl.dispatch(hl.dsp.workspace.swap_monitors({
		monitor1 = current_monitor.name,
		monitor2 = target_monitor.name,
	}))
	if not result.ok then
		swap_workspace_ids(target_id, current_id)
		return
	end
	hl.dispatch(hl.dsp.focus({ monitor = target_monitor.name }))
end

return {
	move_left = function()
		move_workspace("l")
	end,
	move_right = function()
		move_workspace("r")
	end,
	swap_left = function()
		swap_workspace_contents(-1)
	end,
	swap_right = function()
		swap_workspace_contents(1)
	end,
}
