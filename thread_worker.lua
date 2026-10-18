local worker_id = ...

require("love.timer")
require("love.event")
require("love.data")
require("love.graphics")
require("love.window")
require("love.image")
require("love.font")
require("love.system")


local control_channel = love.thread.getChannel("threading_control_" .. worker_id)
local status_channel = love.thread.getChannel("threading_status_" .. worker_id)

local is_running = true
local is_paused = false
local last_command = ""


-- local img_a = love.graphics.newImage("assets/parrot.png") -- WARNING: crashes worker

-- Pushes a status message from the worker thread to the main thread
--- @param message string # status message to send
local function send_status(message)
    -- print("Worker " .. tostring(worker_id) .. " status: " .. tostring(message))
    status_channel:push(message)
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

        send_status("remove_background_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx = require("onnx")
            local onnx_api, init_state = Onnx.init("onnxruntime/onnxruntime")
            if not onnx_api then
                error((init_state and init_state.load_error) or "Failed to initialize ONNX Runtime")
            end

            local session = Onnx.create_session(model_path)
            if not session or not session.session then
                error((session and tostring(session.message)) or "Failed to create ONNX session")
            end
            print(session.message)

            local image_data = love.image.newImageData(image_path)
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

        send_status("upscale_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx = require("onnx")
            local onnx_api, init_state = Onnx.init("onnxruntime/onnxruntime")
            if not onnx_api then
                error((init_state and init_state.load_error) or "Failed to initialize ONNX Runtime")
            end

            local session = Onnx.create_session(model_path)
            if not session or not session.session then
                error((session and tostring(session.message)) or "Failed to create ONNX session")
            end
            print(session.message)

            local image_data = love.image.newImageData(image_path)
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

        send_status("inpaint_start") -- hardcoded

        local ok, filedata = xpcall(function()
            local Onnx = require("onnx")
            local onnx_api, init_state = Onnx.init("onnxruntime/onnxruntime")
            if not onnx_api then
                error((init_state and init_state.load_error) or "Failed to initialize ONNX Runtime")
            end

            local session = Onnx.create_session(model_path)
            if not session or not session.session then
                error((session and tostring(session.message)) or "Failed to create ONNX session")
            end
            print(session.message)

            local image_data = love.image.newImageData(image_path)
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


-- list of worker functions mapped by worker_id
local Functions = {
    [1] = worker1_onnx_remove_background,
    [2] = worker2_onnx_upscale,
    [3] = worker3_onnx_inpaint,
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
        active_function(step, last_command)
    end
end

send_status("stopped")
