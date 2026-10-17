-- main.lua
if arg[2] == "debug" then
    require("lldebugger").start() -- WARNING: hangs Love2D ?
end

lg = love.graphics
la = love.audio

io.popen("chcp 65001")

require("libs.errorhandler")
utf8 = require("utf8")
Onnx = require("onnx")
Threading = require("libs.threading")
CameraMgr = require("libs.CameraMgr.lib.CameraMgr")
require("utils")

font_mplusrounded14 = lg.newFont("assets/fonts/MPLUSRounded1c-Regular.ttf", 14)

local THREAD_WORKER_PATH = "thread_worker.lua"
local IMAGE_PATH = "assets/parrot.png"
local img_parrot = lg.newImage(IMAGE_PATH)
local img_upscaled = nil
local img_no_background = nil
local MODEL_UPSCALER_PATH = "models/4x-ClearRealityV1.onnx" -- 7 sec
-- local MODEL_UPSCALER_PATH = "models/1x-Kim2091-DeJpeg-v0.onnx" -- 36 sec
-- local MODEL_BG_REMOVER_PATH = "models/u2net.onnx" -- 4 sec
local MODEL_BG_REMOVER_PATH = "models/birefnet-lite-512.onnx" --
local BACKGROUND_REMOVAL_THRESHOLD = 0.25
local CAMERA_ZOOM_STEP = 1.15
local CAMERA_MIN_SCALE = 0.2
local CAMERA_MAX_SCALE = 16

local processing_start_time = nil
local last_elapsed_seconds = nil
local camera = CameraMgr.newManager()
local active_drag_buttons = 0
local drag_buttons = {}


local function set_camera_zoom(new_scale, anchor_x, anchor_y)
    local camera_x, camera_y = camera.getCoords()
    local world_x_before, world_y_before = camera.toWorldCoords(anchor_x, anchor_y)

    camera.setScale(new_scale)

    local world_x_after, world_y_after = camera.toWorldCoords(anchor_x, anchor_y)
    camera.setCoords(
        camera_x + (world_x_before - world_x_after),
        camera_y + (world_y_before - world_y_after)
    )
end


local function start_background_removal()
    if Threading.is_running(1) then
        print_to_screen("Background removal is already running")
        return
    end

    local ok, err = Threading.run(THREAD_WORKER_PATH, 1)
    if not ok then
        print_to_screen("Failed to start the worker thread: " .. tostring(err))
        return
    end

    local command = string.format("remove_background|%s|%s|%s", MODEL_BG_REMOVER_PATH, IMAGE_PATH,
            tostring(BACKGROUND_REMOVAL_THRESHOLD))
    ok, err = Threading.command(1, command)
    if not ok then
        print_to_screen("Failed to queue background removal: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_to_screen("Started background removal in a worker thread...")
end

local function start_upscale()
    if Threading.is_running(2) then
        print_to_screen("Upscale is already running")
        return
    end

    local ok, err = Threading.run(THREAD_WORKER_PATH, 2)
    if not ok then
        print_to_screen("Failed to start the worker thread: " .. tostring(err))
        return
    end

    local command = string.format("upscale|%s|%s", MODEL_UPSCALER_PATH, IMAGE_PATH)
    ok, err = Threading.command(2, command)
    if not ok then
        print_to_screen("Failed to queue upscale: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_to_screen("Started upscale in a worker thread...")
end


local function final_message(thread_id)
    print_to_screen(string.format("ONNX processing time: %.3f seconds",
        love.timer.getTime() - processing_start_time))
    print_to_screen(string.format("Memory usage - RAM: %d " ..
        "MB, Virtual: %d MB, Peak: %d MB", get_memory_usage()))
    processing_start_time = nil
    last_elapsed_seconds = nil
    Threading.stop(thread_id)
end


function love.load()
    math.randomseed( os.time() )
    camera.setCoords(lg.getWidth() / 2, lg.getHeight() / 2)

    print_to_screen("Love2D loaded")
    local working_set, commit_size, peak_working_set = get_memory_usage()
    if working_set and commit_size and peak_working_set then
        print_to_screen(string.format("Memory usage - Working Set: %.2f MB, Commit " ..
            "Size: %.2f MB, Peak Working Set: %.2f MB", working_set, commit_size, peak_working_set))
    else
        print_to_screen("Failed to get memory usage")
    end

    -- start_background_removal()
    start_upscale()
end


function love.update(dt)
    Threading.update()
    camera.update(dt)

    if processing_start_time then
        for i = 1, 2 do
            if Threading.has_crashed(i) then
                print_to_screen("Worker thread " .. tostring(i) .. " has crashed")
                processing_start_time = nil
                last_elapsed_seconds = nil
                Threading.stop(i)
                return
            end
        end

        local elapsed_seconds = math.floor(love.timer.getTime() - processing_start_time)
        if last_elapsed_seconds ~= elapsed_seconds and elapsed_seconds > 0 then -- once per second
            last_elapsed_seconds = elapsed_seconds
            local working_set, commit_size, peak_working_set = get_memory_usage()
            print_to_screen(string.format("  [Timer]: %d seconds. Memory usage - RAM: %d " ..
                "MB, Peak: %d MB", elapsed_seconds, working_set, peak_working_set))

            -- Check messages from worker 1 - background removal
            local last_message_1 = Threading.consume_last_message(1)
            if last_message_1 and last_message_1:match("^remove_background_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message_1:sub(#"remove_background_done:" + 1)), "_")
                img_no_background = lg.newImage(decoded_FileData)
                print_to_screen("Background removed from image successfully")
                final_message(1)
            elseif last_message_1 and last_message_1:match("^remove_background_error:") then
                local error_text = last_message_1:sub(#"remove_background_error:" + 1)
                print_to_screen("Background removal failed: " .. error_text)
                final_message(1)
            end

            -- Check messages from worker 2 - image upscaling
            local last_message_2 = Threading.consume_last_message(2)
            if last_message_2 and last_message_2:match("^upscale_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message_2:sub(#"upscale_done:" + 1)), "_")
                img_upscaled = lg.newImage(decoded_FileData)
                print_to_screen("Image upscaled successfully")
                final_message(2)
            elseif last_message_2 and last_message_2:match("^upscale_error:") then
                local error_text = last_message_2:sub(#"upscale_error:" + 1)
                print_to_screen("Image upscaling failed: " .. error_text)
                final_message(2)
            end
        end
    end
end


function love.quit()
    Threading.shutdown()
end


function love.draw()
    -- if processing_start_time then
    --     -- lg.print(string.format("Background removal timer: %d seconds", last_elapsed_seconds or 0), 10, 10)
    --     return
    -- end
    -- lg.print(love.graphics.getStats().drawcalls, 10, 10)

    lg.clear(0, 0, 1, 1)
    lg.setColor(1, 1, 1, 1)

    camera.attach()
    lg.draw(img_parrot, 200, 10)
    if img_upscaled then
        lg.draw(img_upscaled, 200 + img_parrot:getWidth(), 10)
    end
    if img_no_background then
        lg.draw(img_no_background, 200 + img_parrot:getWidth(), 10)
    end
    camera.detach()
end


function love.mousemoved(x, y, dx, dy, istouch)
    if active_drag_buttons <= 0 then
        return
    end

    local camera_x, camera_y = camera.getCoords()
    local scale_x, scale_y = camera.getScale()
    camera.setCoords(camera_x - dx / scale_x, camera_y - dy / scale_y)
end


function love.mousepressed(x, y, button)
    if drag_buttons[button] then
        return
    end

    drag_buttons[button] = true
    active_drag_buttons = active_drag_buttons + 1
end


function love.mousereleased(x, y, button)
    if not drag_buttons[button] then
        return
    end

    drag_buttons[button] = nil
    active_drag_buttons = math.max(0, active_drag_buttons - 1)
end


function love.wheelmoved(x, y)
    if y == 0 then
        return
    end

    local current_scale = camera.getScale()
    local target_scale = math.clamp(current_scale * (CAMERA_ZOOM_STEP ^ y), CAMERA_MIN_SCALE, CAMERA_MAX_SCALE)
    if target_scale == current_scale then
        return
    end

    local mouse_x, mouse_y = love.mouse.getPosition()
    set_camera_zoom(target_scale, mouse_x, mouse_y)
end


function love.keypressed(key, scancode, isrepeat)
end


function love.keyreleased(key, scancode)
end
