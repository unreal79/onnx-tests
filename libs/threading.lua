-- Threading functionality

local Threading = {}

local Workers = {} -- table to hold worker state for each worker_id

-- local module_path = select(1, ...):match("(.-)[^%.]+$")
-- local WORKER_FILE = (module_path and module_path:gsub("%.", "/") or "libs/threading/") .. "threading_worker.lua"


--- Removes all pending values from a thread channel
--- @param channel love.Channel|nil # channel to clear
local function clear_channel(channel)
    if not channel then
        return
    end

    while channel:pop() ~= nil do
    end
end


--- Returns cached state for a worker and creates it on first access
--- @param worker_id number # worker identifier
--- @return table|nil, string|nil # worker state table or nil if invalid worker_id, error message if invalid
local function get_worker_state(worker_id)
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
        has_started = false,
        started_at = 0,
        last_status_at = 0,
        has_crashed = false,
    }
    Workers[worker_id] = state

    return state, nil
end


--- Clears the thread state for a worker without marking it as crashed
--- @param state table # worker state table
--- @return nil
local function clear_thread_state(state)
    if not state then
        return
    end

    state.thread = nil
    state.is_paused = false
    state.has_started = false
    state.started_at = 0
    state.last_status_at = 0
    -- keep has_crashed true if the thread died unexpectedly; it will be reset on a fresh run
end


--- Marks the worker as crashed and updates its state accordingly
--- @param state table # worker state table
local function mark_crashed(state)
    if not state then
        return
    end

    clear_thread_state(state)
    state.has_crashed = true
    print("Worker " .. tostring(state.worker_id) .. " has crashed")
end


--- Checks whether the worker thread is currently running
--- @param state table # worker state table
--- @return boolean # true if the worker thread is running, false otherwise
local function is_running(state)
    if not state then
        return false
    end

    if state.has_crashed then
        return false
    end

    if state.thread and not state.thread:isRunning() then
        mark_crashed(state)
        return false
    end

    if state.thread and not state.has_started and love.timer.getTime() - state.started_at > 2 then
        mark_crashed(state)
        return false
    end

    if state.thread and state.has_started then
        local now = love.timer.getTime()
        local last_status = state.last_status_at or state.started_at or now
        if now - last_status > 3 then
            mark_crashed(state)
            return false
        end
    end

    return state.thread ~= nil
end


--- Sends a control message to a running worker thread
--- @param worker_id number # worker identifier
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


--- Starts one of the background worker functions in its own thread
--- @param worker_file string # path to the worker Lua file
--- @param worker_id number # worker identifier
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
    state.has_started = false
    state.has_crashed = false
    state.started_at = love.timer.getTime()
    state.last_status_at = state.started_at

    state.thread:start(worker_id)

    return true, nil
end


--- Stops a running background worker thread
--- @param worker_id number # worker identifier
--- @return boolean, string|nil # true if the thread was stopped successfully, false and an error message otherwise
function Threading.stop(worker_id)
    return send_signal(worker_id, "stop")
end


--- Pauses a running background worker thread
--- @param worker_id number # worker identifier
--- @return boolean, string|nil # true if the thread was paused successfully, false and an error message otherwise
function Threading.pause(worker_id)
    return send_signal(worker_id, "pause")
end


--- Resumes a paused background worker thread
--- @param worker_id number # worker identifier
--- @return boolean, string|nil # true if the thread was resumed successfully, false and an error message otherwise
function Threading.resume(worker_id)
    return send_signal(worker_id, "resume")
end


--- Sends an arbitrary text command to a running worker thread
--- @param worker_id number # worker identifier
--- @param command string # command payload for the worker
--- @return boolean, string|nil # true if the command was sent successfully, false and an error message otherwise
function Threading.command(worker_id, command)
    if command == nil or command == "" then
        return false, "Command is required"
    end

    return send_signal(worker_id, "command:" .. tostring(command))
end


--- Pulls status messages from all worker threads and updates cached state
function Threading.update()
    for worker_id, state in pairs(Workers) do
        local message = state.status_channel:pop()
        while message ~= nil do
            local now = love.timer.getTime()
            local should_keep_previous_message = message == "stopped" and state.last_message and
                state.last_message:match("^remove_background_")
            if not should_keep_previous_message then
                state.last_message = message
            end
            state.last_status_at = now

            if message == "paused" then
                state.is_paused = true
            elseif message == "resumed" then
                state.is_paused = false
                state.has_crashed = false
            elseif message == "stopped" then
                state.is_paused = false
                state.has_crashed = false
                clear_thread_state(state)
            elseif message == "started:" .. tostring(worker_id) then
                state.is_paused = false
                state.has_started = true
                state.has_crashed = false
                state.started_at = now
                state.last_status_at = now
            elseif message:match("^startup_error:") or message:match("^crashed:") then
                mark_crashed(state)
            end

            -- if DEBUG then
            -- 	print("[Thread " .. tostring(worker_id) .. "] " .. tostring(message))
            -- end

            message = state.status_channel:pop()
        end

        if state.thread then
            if not state.thread:isRunning() then
                mark_crashed(state)
            elseif not state.has_started and love.timer.getTime() - state.started_at > 2 then
                mark_crashed(state)
            elseif state.has_started and state.last_status_at > 0 and
                    love.timer.getTime() - state.last_status_at > 3 then
                mark_crashed(state)
            end
        end
    end
end


--- Returns whether a worker thread is currently running
--- @param worker_id number # worker identifier
--- @return boolean # true if the worker thread is running, false otherwise
function Threading.is_running(worker_id)
    local state = Workers[worker_id]
    return is_running(state)
end


--- Returns whether a worker thread has crashed or stopped without a normal shutdown
--- @param worker_id number # worker identifier
--- @return boolean # true if the worker thread has crashed or stopped unexpectedly, false otherwise
function Threading.has_crashed(worker_id)
    local state = Workers[worker_id]
    return state and state.has_crashed or false
end


--- Returns whether a worker thread is currently paused
--- @param worker_id number # worker identifier
--- @return boolean # true if the worker thread is paused, false otherwise
function Threading.is_paused(worker_id)
    local state = Workers[worker_id]
    return state and state.is_paused or false
end


--- Returns the last status message received from a worker thread
--- @param worker_id number # worker identifier
--- @return string|nil # the last status message received from the worker thread, or nil if none
function Threading.get_last_message(worker_id)
    local state = Workers[worker_id]
    return state and state.last_message or nil
end


--- Returns and clears the last status message received from a worker thread.
--- @param worker_id number # worker identifier
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


--- Sends a stop signal to all running worker threads
function Threading.shutdown()
    for worker_id, state in pairs(Workers) do
        if is_running(state) then
            state.control_channel:push("stop")
        end
    end
end


return Threading
