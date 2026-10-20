local worker_id = ...

require("love.timer")
require("love.event")
require("love.data")
require("love.window")
require("love.image")
require("love.font")
require("love.system")
require("utils")
require("onnx")

local ONNXRUNTIME_PATH = "onnxruntime/onnxruntime"
USE_DIRECTML = false

local control_channel = love.thread.getChannel("threading_control_" .. worker_id)
local status_channel = love.thread.getChannel("threading_status_" .. worker_id)

local is_running = true
local is_paused = false
local last_command = ""


-- Pushes a status message from the worker thread to the main thread
--- @param message string # status message to send
local function send_status(message)
    -- print_log("Worker " .. tostring(worker_id) .. " status: " .. tostring(message))
    status_channel:push(message)
end

--- Helper function to initialize ONNX Runtime
--- @param model_path string # path to the ONNX model file
local function onnx_init_and_create_session(model_path, image_path)
    local Onnx = require("onnx")
    local ok, err = pcall(function() return Onnx.init(ONNXRUNTIME_PATH) end)
    local onnx_api, init_state = ok and err or nil, ok and not err and {} or {load_error = err}
    if not onnx_api then
        print_log("Failed to initialize ONNX Runtime")
        send_status("crashed: " .. tostring(init_state and init_state.load_error or "unknown error"))
        error((init_state and init_state.load_error) or "Failed to initialize ONNX Runtime")
    end

    print_log("Using model: `" .. model_path .. "`")
    ok, err = pcall(function() return Onnx.create_session(model_path) end)
    local session = ok and err or nil
    if not session or not session.session then
        print_log("Failed to create ONNX session")
        send_status("crashed: " .. tostring(session and session.message or "unknown error"))
        error((session and tostring(session.message)) or "Failed to create ONNX session")
    end
    print_log(session.message)

    local image_data = love.image.newImageData(image_path)

    return Onnx, session, image_data
end


-- Worker thread function 1: Remove background
--- @param step number # current iteration number
--- @param command string # last received command
local function worker1_onnx_remove_background(step, command)
    if command and command:match("^remove_background") then
        local commands = {}
        for part in string.gmatch(command, "([^|]+)") do
            commands[#commands + 1] = part
        end

        local task_name = commands[1]
        if task_name ~= "remove_background" then -- hardcoded
            send_status("unsupported command: " .. tostring(command))
            last_command = ""
            return
        end

        local model_path = commands[2]
        local image_path = commands[3]
        local alpha_threshold = tonumber(commands[4])
        USE_DIRECTML = commands[5] == "true"
        if USE_DIRECTML then
            ONNXRUNTIME_PATH = "onnxruntime/DirectML/onnxruntime"
        end


        send_status("remove_background_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx, session, image_data = onnx_init_and_create_session(model_path, image_path)
            local output_image_data = Onnx.remove_background(session, image_data, alpha_threshold, true)
            return output_image_data:encode("tga", nil)
        end, debug.traceback)

        if ok then
            local base64_encoded_FileData = love.data.encode("string", "base64", filedata)
            send_status("remove_background_done:" .. base64_encoded_FileData) -- hardcoded message
        else
            send_status("remove_background_error:" .. tostring(filedata)) -- hardcoded message
        end

        last_command = ""
        is_running = false
        return
    end

    love.timer.sleep(0.1)
end


-- Worker thread function 2: Upscale
--- @param step number # current iteration number
--- @param command string # last received command
local function worker2_onnx_upscale(step, command)
    if command and command:match("^upscale") then
        local commands = {}
        for part in string.gmatch(command, "([^|]+)") do
            commands[#commands + 1] = part
        end

        local task_name = commands[1]
        if task_name ~= "upscale" then -- hardcoded
            send_status("unsupported command: " .. tostring(command))
            last_command = ""
            return
        end

        local model_path = commands[2]
        local image_path = commands[3]
        local tile_size = tonumber(commands[4])
        local tile_overlap = tonumber(commands[5])
        USE_DIRECTML = commands[6] == "true"
        if USE_DIRECTML then
            ONNXRUNTIME_PATH = "onnxruntime/DirectML/onnxruntime"
        end

        send_status("upscale_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx, session, image_data = onnx_init_and_create_session(model_path, image_path)
            local output_image_data = Onnx.upscale(session, image_data, true, tile_size, tile_overlap)
            return output_image_data:encode("tga", nil)
        end, debug.traceback)

        if ok then
            local base64_encoded_FileData = love.data.encode("string", "base64", filedata)
            send_status("upscale_done:" .. base64_encoded_FileData) -- hardcoded message
        else
            send_status("upscale_error:" .. tostring(filedata)) -- hardcoded message
        end

        last_command = ""
        is_running = false
        return
    end

    love.timer.sleep(0.1)
end


-- Worker thread function 3: Inpaint transparent holes using the image alpha channel as mask
--- @param step number # current iteration number
--- @param command string # last received command
local function worker3_onnx_inpaint(step, command)
    if command and command:match("^inpaint") then
        local commands = {}
        for part in string.gmatch(command, "([^|]+)") do
            commands[#commands + 1] = part
        end

        local task_name = commands[1]
        if task_name ~= "inpaint" then -- hardcoded
            send_status("unsupported command: " .. tostring(command))
            last_command = ""
            return
        end

        local model_path = commands[2]
        local image_path = commands[3]
        local alpha_threshold = tonumber(commands[4])
        USE_DIRECTML = commands[5] == "true"
        if USE_DIRECTML then
            ONNXRUNTIME_PATH = "onnxruntime/DirectML/onnxruntime"
        end

        send_status("inpaint_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx, session, image_data = onnx_init_and_create_session(model_path, image_path)
            local output_image_data = Onnx.inpaint(session, image_data, alpha_threshold, true)
            return output_image_data:encode("tga", nil)
        end, debug.traceback)

        if ok then
            local base64_encoded_FileData = love.data.encode("string", "base64", filedata)
            send_status("inpaint_done:" .. base64_encoded_FileData) -- hardcoded message
        else
            send_status("inpaint_error:" .. tostring(filedata)) -- hardcoded message
        end

        last_command = ""
        is_running = false
        return
    end

    love.timer.sleep(0.1)
end


-- Worker thread function 4: Colorize grayscale images
--- @param step number # current iteration number
--- @param command string # last received command
local function worker4_onnx_colorize(step, command)
    if command and command:match("^colorize") then
        local commands = {}
        for part in string.gmatch(command, "([^|]+)") do
            commands[#commands + 1] = part
        end

        local task_name = commands[1]
        if task_name ~= "colorize" then -- hardcoded
            send_status("unsupported command: " .. tostring(command))
            last_command = ""
            return
        end

        local model_path = commands[2]
        local image_path = commands[3]
        local model_type = commands[4] or "colorize"
        USE_DIRECTML = commands[5] == "true"
        if USE_DIRECTML then
            ONNXRUNTIME_PATH = "onnxruntime/DirectML/onnxruntime"
        end

        send_status("colorize_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx, session, image_data = onnx_init_and_create_session(model_path, image_path)
            local output_image_data = Onnx.colorize(session, image_data, true, model_type)
            return output_image_data:encode("tga", nil)
        end, debug.traceback)

        if ok then
            local base64_encoded_FileData = love.data.encode("string", "base64", filedata)
            send_status("colorize_done:" .. base64_encoded_FileData) -- hardcoded message
        else
            send_status("colorize_error:" .. tostring(filedata)) -- hardcoded message
        end

        last_command = ""
        is_running = false
        return
    end

    love.timer.sleep(0.1)
end


-- list of worker functions mapped by worker_id
local Functions = {
    [1] = worker1_onnx_remove_background,
    [2] = worker2_onnx_upscale,
    [3] = worker3_onnx_inpaint,
    [4] = worker4_onnx_colorize,
}

if Functions[worker_id] == nil then
    send_status("invalid worker id")
    error("Invalid worker id: " .. tostring(worker_id))
    return
end

local active_function = Functions[worker_id]

send_status("started: " .. tostring(worker_id))

local step = 0
while is_running do
    local message = control_channel:pop()
    while message ~= nil do
        if message == "stop" then
            is_running = false
            break
        elseif message == "pause" then
            is_paused = true
            send_status("paused")
        elseif message == "resume" then
            is_paused = false
            send_status("resumed")
        else
            local command = tostring(message):match("^command:(.*)$")
            if command then
                last_command = command
                send_status("command:" .. command)
            end
        end

        message = control_channel:pop()
    end

    if not is_running then
        break
    end

    if is_paused then
        love.timer.sleep(0.1)
    else
        step = step + 1
        local ok, err = xpcall(
            function()
                return active_function(step, last_command)
            end,
            debug.traceback
        )
        if not ok then
            print("Worker raised error: " .. tostring(err))
            print_log("Worker raised error: " .. tostring(err))
            send_status("crashed:" .. tostring(err))
            return
        end
    end
end

send_status("stopped")
