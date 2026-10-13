local worker_id = ...

require("love.timer")
require("love.event")
require("love.data")
require("love.graphics")
require("love.window")
require("love.image")
require("love.font")
require("love.system")
-- require("love.")


local control_channel = love.thread.getChannel("threading_control_" .. worker_id)
local status_channel = love.thread.getChannel("threading_status_" .. worker_id)

local is_running = true
local is_paused = false
local last_command = ""


-- Pushes a status message from the worker thread to the main thread
--- @param message string # status message to send
local function send_status(message)
    -- print("Worker " .. tostring(worker_id) .. " status: " .. tostring(message))
    status_channel:push(message)
end


-- WARNING: CRASHES thread without error
-- local font_neucha40 = love.graphics.newFont("assets/fonts/Neucha-Regular.ttf", 40)
-- local img_a, err = pcall(love.graphics.newImage, "assets/pics/bonfire.png")
-- print("img_a: " .. tostring(img_a) .. " " .. tostring(err))

-- Worker thread function 1:
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
        local threshold = tonumber(commands[4])

        send_status("remove_background_start") -- hardcoded

        local filedata = nil
        -- local ok, filedata = pcall(function()
            local Onnx = require("onnx")
            local onnx_api, init_state = Onnx.init("onnxruntime/onnxruntime")
            if not onnx_api then
                error((init_state and init_state.load_error) or "Failed to initialize ONNX Runtime")
            end

            local session = Onnx.create_session(model_path)
            if not session or not session.session then
                error((session and session.message) or "Failed to create ONNX session")
            end

            local image_data = love.image.newImageData(image_path)
            local output_image_data = Onnx.remove_background(session, image_data, threshold, true)
            -- local output_path = image_path:gsub("%.([^.]+)$", "_no_background.%1")
            local encoded_FileData, encode_error = pcall(function()
                -- print("Encoding and saving output image to: `" .. tostring(output_path) .. "`")
                -- return output_image_data:encode("png", nil) --output_path)
                filedata = output_image_data:encode("png", nil)
            end)
            if not encoded_FileData then
                error(encode_error or "Failed to encode processed image")
            end
        --     return encoded_FileData --output_path
        -- end)--, debug.traceback)

        if filedata then
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

-- list of worker functions mapped by worker_id
local Functions = {
    [1] = worker1_onnx_remove_background,
}

if worker_id ~= 1 then
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
