-- Threading functionality

local Threading = {}

local Workers = {} -- table to hold worker state for each worker_id

-- local module_path = select(1, ...):match("(.-)[^%.]+$")
-- local WORKER_FILE = (module_path and module_path:gsub("%.", "/") or "libs/threading/") .. "threading_worker.lua"


-- Removes all pending values from a thread channel
--- @param channel love.Channel|nil # channel to clear
local function clear_channel(channel)
	if not channel then
		return
	end

	while channel:pop() ~= nil do
	end
end


-- Returns cached state for a worker and creates it on first access
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return table|nil, string|nil # worker state table or nil if invalid worker_id, error message if invalid
local function get_worker_state(worker_id)
	if worker_id ~= 1 and worker_id ~= 2 then
		return nil, "Invalid worker id: " .. tostring(worker_id)
	end

	local state = Workers[worker_id]
	if state then
		return state, nil
	end

	state = {
		worker_id = worker_id,
		control_channel = love.thread.getChannel("threading_control_" .. worker_id),
		status_channel = love.thread.getChannel("threading_status_" .. worker_id),
		thread = nil,
		is_paused = false,
		last_message = nil,
	}
	Workers[worker_id] = state

	return state, nil
end


-- Checks whether the worker thread is currently running
--- @param state table|nil # worker state table
--- @return boolean # true if the worker thread is running, false otherwise
local function is_running(state)
	return state and state.thread and state.thread:isRunning() or false
end


-- Sends a control message to a running worker thread
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @param signal string # control signal to send to the worker
--- @return boolean, string|nil # true if the signal was sent successfully, false and an error message otherwise
local function send_signal(worker_id, signal)
	local state, err = get_worker_state(worker_id)
	if not state then
		return false, err
	end

	if not is_running(state) then
		return false, "Thread " .. tostring(worker_id) .. " is not running"
	end

	state.control_channel:push(signal)
	return true, nil
end


-- Starts one of the background worker functions in its own thread
--- @param worker_file string # path to the worker Lua file
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return boolean, string|nil # true if the thread was started successfully, false and an error message otherwise
function Threading.run(worker_file, worker_id)
	if not love.thread or love.system.getOS() == "Web" then
		return false, "Threads are not available on this platform"
	end

	local state, err = get_worker_state(worker_id)
	if not state then
		return false, err
	end

	if is_running(state) then
		return true, nil
	end

	clear_channel(state.control_channel)
	clear_channel(state.status_channel)

	state.thread = love.thread.newThread(worker_file)
	state.is_paused = false
	state.last_message = nil
	state.thread:start(worker_id)

	return true, nil
end


-- Stops a running background worker thread
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return boolean, string|nil # true if the thread was stopped successfully, false and an error message otherwise
function Threading.stop(worker_id)
	return send_signal(worker_id, "stop")
end


-- Pauses a running background worker thread
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return boolean, string|nil # true if the thread was paused successfully, false and an error message otherwise
function Threading.pause(worker_id)
	return send_signal(worker_id, "pause")
end


-- Resumes a paused background worker thread
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return boolean, string|nil # true if the thread was resumed successfully, false and an error message otherwise
function Threading.resume(worker_id)
	return send_signal(worker_id, "resume")
end


-- Sends an arbitrary text command to a running worker thread
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @param command string # command payload for the worker
--- @return boolean, string|nil # true if the command was sent successfully, false and an error message otherwise
function Threading.command(worker_id, command)
	if command == nil then
		return false, "Command is required"
	end

	return send_signal(worker_id, "command:" .. tostring(command))
end


-- Pulls status messages from all worker threads and updates cached state
function Threading.update()
	for worker_id, state in pairs(Workers) do
		local message = state.status_channel:pop()
		while message ~= nil do
			local should_keep_previous_message = message == "stopped" and state.last_message and
				state.last_message:match("^remove_background_")
			if not should_keep_previous_message then
				state.last_message = message
			end

			if message == "paused" then
				state.is_paused = true
			elseif message == "resumed" or message == "stopped" or
					message == "started:" .. tostring(worker_id) then
				state.is_paused = false
			end

			-- if DEBUG then
			-- 	print("[Thread " .. tostring(worker_id) .. "] " .. tostring(message))
			-- end

			message = state.status_channel:pop()
		end

		if state.thread and not state.thread:isRunning() then
			state.thread = nil
		end
	end
end


-- Returns whether a worker thread is currently running
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return boolean # true if the worker thread is running, false otherwise
function Threading.is_running(worker_id)
	local state = Workers[worker_id]
	return is_running(state)
end

-- Returns whether a worker thread is currently paused
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return boolean # true if the worker thread is paused, false otherwise
function Threading.is_paused(worker_id)
	local state = Workers[worker_id]
	return state and state.is_paused or false
end


-- Returns the last status message received from a worker thread
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return string|nil # the last status message received from the worker thread, or nil if none
function Threading.get_last_message(worker_id)
	local state = Workers[worker_id]
	return state and state.last_message or nil
end


-- Returns and clears the last status message received from a worker thread.
--- @param worker_id number # worker identifier, expected values are 1 or 2
--- @return string|nil # last status message received before it was cleared
function Threading.consume_last_message(worker_id)
	local state = Workers[worker_id]
	if not state then
		return nil
	end

	local message = state.last_message
	state.last_message = nil
	return message
end


-- Sends a stop signal to all running worker threads
function Threading.shutdown()
	for worker_id, state in pairs(Workers) do
		if is_running(state) then
			state.control_channel:push("stop")
		end
	end
end


return Threading
