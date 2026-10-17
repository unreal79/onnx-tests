-- main.lua
lg = love.graphics
la = love.audio

io.popen("chcp 65001")

require("libs.errorhandler")
utf8 = require("utf8")
Onnx = require("onnx")
Threading = require("libs.threading")
CameraMgr = require("libs.CameraMgr.lib.CameraMgr").newManager()
require("utils")

local THREAD_WORKER_PATH = "thread_worker.lua"
local IMAGE_PATH = "assets/parrot.png"

-- local MODEL_UPSCALER_PATH = "models/upscale/1x-Archivist_Soft.onnx" -- 7 sec, bad, eats details
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-Kim2091-DeJpeg-v0.onnx" -- 36 sec, good
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-Restoration-jpg-ESRGAN_64nf_23nb-jpg40_60-vyls.onnx" -- 200 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/4xNomos2_realplksr_dysample_256_fp32_fullyoptimized.onnx" -- 200 sec, x8, very bad
-- local MODEL_UPSCALER_PATH = "models/upscale/4xNomosWebPhoto_RealPLKSR.onnx" -- 110 sec, x4, ADVANCED, sharp
-- local MODEL_UPSCALER_PATH = "models/upscale/4x-ClearRealityV1.onnx" -- 8 sec, x4, ADVANCED
local MODEL_UPSCALER_PATH = "models/upscale/4x-ClearRealityV1-fp32-opset17.onnx" -- 8 sec, x4, ADVANCED
-- local MODEL_UPSCALER_PATH = "models/upscale/4x-UltraSharp-fp32-opset17.onnx" -- 220 sec, x4, ADVANCED, sharp
-- local MODEL_UPSCALER_PATH = "models/upscale/4x-UltraSharpV2_Lite_fp32_op17.onnx" -- 110 sec, x4, ADVANCED, creates halo inside
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-SuperScale_Alt_RPLKSR_S.onnx" -- 40 sec, x1, average
-- local MODEL_UPSCALER_PATH = "models/upscale/4x_foolhardy_Remacri.onnx" -- 220 sec, x4, average, too sharp
-- local MODEL_UPSCALER_PATH = "models/upscale/4xPurePhoto-RealPLSKR.onnx" -- 118 sec, x4, slow, bad tile
-- local MODEL_UPSCALER_PATH = "models/upscale/4xPurePhoto-Span.onnx" -- 8 sec, x4, very good, darkens image
-- local MODEL_UPSCALER_PATH = "models/upscale/4xLSDIRCompactv2.onnx" -- 8 sec, x4, average
-- local MODEL_UPSCALER_PATH = "models/upscale/ArtCNN_R8F64_RGB.onnx" -- 12 sec, x2, average
-- local MODEL_UPSCALER_PATH = "models/upscale/hdrtvnetpp_ensemble_dynamic.onnx" -- 4 sec, x1, bad BT.2020 color output
-- local MODEL_UPSCALER_PATH = "models/upscale/BSRGAN.onnx" -- 235 sec, x4, good, fixes JPEG halo
-- local MODEL_UPSCALER_PATH = "models/upscale/BSRGANx2.onnx" -- 230 sec, x2, good, fixes JPEG halo
-- local MODEL_UPSCALER_PATH = "models/upscale/BSRNet.onnx" -- 230 sec, x4, good, fixes JPEG halo
-- local MODEL_UPSCALER_PATH = "models/upscale/realesr-general-wdn-x4v3.onnx" -- 15 sec, x4,very good
-- local MODEL_UPSCALER_PATH = "models/upscale/up4x_latest_conservative.onnx" -- 20 sec, x4, average
-- local MODEL_UPSCALER_PATH = "models/upscale/upscayl-remacri-4x.onnx" -- 230 sec, x4, average, too sharp
-- local MODEL_UPSCALER_PATH = "models/upscale/upscale-realplksr-onnx_x4.onnx" -- 190 sec, x8, very bad
-- local MODEL_UPSCALER_PATH = "models/upscale/waifu2x_vgg7_photo_noise0.onnx" -- 4 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/waifu2x_vgg7_photo_noise3.onnx" -- 4 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/waifu2x_vgg7_photo_scale2x.onnx" -- 4 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/websr_cnn2x_l_rl.onnx" -- 2 sec, x2, average, adds JPEG halo

-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/birefnet-lite-512.onnx" -- 15 sec
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/BiRefNet_512x512_fp16.onnx" -- 50 sec
local MODEL_BG_REMOVER_PATH = "models/bg_remove/u2net.onnx" -- 4 sec
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/u2netp.onnx" -- 4 sec

local MODEL_INPAINTER_PATH = "models/bg_remove/lama_fp32.onnx"

local BACKGROUND_REMOVAL_THRESHOLD = 0.25
local CAMERA_ZOOM_STEP = 1.15
local CAMERA_MIN_SCALE = 0.2
local CAMERA_MAX_SCALE = 16
local SCREEN_FILTER_MODES = {
    { label = "Nearest", min = "nearest", mag = "nearest" },
    { label = "Linear", min = "linear", mag = "linear" },
    { label = "Linear min / Nearest mag", min = "linear", mag = "nearest" },
    { label = "Nearest min / Linear mag", min = "nearest", mag = "linear" },
}

font_mplusrounded14 = lg.newFont("assets/fonts/MPLUSRounded1c-Regular.ttf", 14)

local img_parrot = lg.newImage(IMAGE_PATH)
local img_upscaled = nil
local img_no_background = nil
local processing_start_time = nil
local last_elapsed_seconds = nil
local active_drag_buttons = 0
local drag_buttons = {}
local current_screen_filter_mode = 1


local function apply_screen_filter_to_image(image)
    if not image then
        return
    end

    local mode = SCREEN_FILTER_MODES[current_screen_filter_mode]
    image:setFilter(mode.min, mode.mag)
end


local function apply_screen_filter_mode()
    local mode = SCREEN_FILTER_MODES[current_screen_filter_mode]
    lg.setDefaultFilter(mode.min, mode.mag)
    apply_screen_filter_to_image(img_parrot)
    apply_screen_filter_to_image(img_upscaled)
    apply_screen_filter_to_image(img_no_background)
    print("Screen smoothing: " .. mode.label)
end


local function cycle_screen_filter_mode(step)
    current_screen_filter_mode = current_screen_filter_mode + step
    if current_screen_filter_mode > #SCREEN_FILTER_MODES then
        current_screen_filter_mode = 1
    elseif current_screen_filter_mode < 1 then
        current_screen_filter_mode = #SCREEN_FILTER_MODES
    end

    apply_screen_filter_mode()
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


local function final_message_and_save_image(thread_id, image_data, model_path)
    print_to_screen(string.format("ONNX processing time: %.3f seconds",
        love.timer.getTime() - processing_start_time))
    print_to_screen(string.format("Memory usage - RAM: %d " ..
        "MB, Virtual: %d MB, Peak: %d MB", get_memory_usage()))
    processing_start_time = nil
    last_elapsed_seconds = nil
    Threading.stop(thread_id)

    if image_data == nil then return end

    local output_path = model_path:gsub("^models/", "_output/"):gsub("%.onnx$", ".png")
    local absolute_output_path = love.filesystem.getSource() .. "/" .. output_path
    local absolute_output_dir = absolute_output_path:match("^(.+)/[^/]+$")
    local normalized_output_dir = absolute_output_dir:gsub("/", package.config:sub(1, 1))

    local ok, err_or_result = pcall(function()
        print("Saving processed image to: " .. absolute_output_path)
        print("Creating output directory: " .. normalized_output_dir)
        local f, err = io.popen("mkdir " .. normalized_output_dir)
        love.timer.sleep(0.1)
        if f == nil then
            print("Failed to create subprocess: " .. tostring(err))
        else
            f:close()
        end
        local encoded_file_data = image_data:encode("png")
        local output_file = assert(io.open(absolute_output_path, "wb"))
        output_file:write(encoded_file_data:getString())
        output_file:close()
        return absolute_output_path
    end)

    if ok then
        print("Saved processed image to: " .. output_path)
    else
        print("Failed to save processed image: " .. tostring(err_or_result))
    end
end


function love.load()
    math.randomseed( os.time() )
    CameraMgr.setCoords(lg.getWidth() / 2, lg.getHeight() / 2)
    apply_screen_filter_mode()

    print_to_screen("Love2D loaded")
    local working_set, commit_size, peak_working_set = get_memory_usage()
    if working_set and commit_size and peak_working_set then
        print_to_screen(string.format("Memory usage - Working Set: %.2f MB, Commit " ..
            "Size: %.2f MB, Peak Working Set: %.2f MB", working_set, commit_size, peak_working_set))
    else
        print_to_screen("Failed to get memory usage")
    end

    start_background_removal()
    -- start_upscale()
end


function love.update(dt)
    Threading.update()
    CameraMgr.update(dt)

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
                local output_image_data = love.image.newImageData(decoded_FileData)
                img_no_background = lg.newImage(output_image_data)
                apply_screen_filter_to_image(img_no_background)
                print_to_screen("Background removed from image successfully")
                final_message_and_save_image(1, output_image_data, MODEL_BG_REMOVER_PATH)
            elseif last_message_1 and last_message_1:match("^remove_background_error:") then
                local error_text = last_message_1:sub(#"remove_background_error:" + 1)
                print_to_screen("Background removal failed: " .. error_text)
                final_message_and_save_image(1)
            end

            -- Check messages from worker 2 - upscaling/restoring
            local last_message_2 = Threading.consume_last_message(2)
            if last_message_2 and last_message_2:match("^upscale_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message_2:sub(#"upscale_done:" + 1)), "_")
                local output_image_data = love.image.newImageData(decoded_FileData)
                img_upscaled = lg.newImage(output_image_data)
                apply_screen_filter_to_image(img_upscaled)
                print_to_screen("Image upscaled successfully")
                final_message_and_save_image(2, output_image_data, MODEL_UPSCALER_PATH)
            elseif last_message_2 and last_message_2:match("^upscale_error:") then
                local error_text = last_message_2:sub(#"upscale_error:" + 1)
                print_to_screen("Image upscaling failed: " .. error_text)
                final_message_and_save_image(2)
            end
        end
    end
end


function love.quit()
    Threading.shutdown()
end


function love.draw()
    lg.clear(0, 0, 1, 1)
    lg.setColor(1, 1, 1, 1)
    lg.setFont(font_mplusrounded14)

    CameraMgr.attach()
        lg.draw(img_parrot, 200, 10)
        if img_upscaled then
            lg.draw(img_upscaled, 200 + img_parrot:getWidth(), 10)
        end
        if img_no_background then
            lg.draw(img_no_background, 200 + img_parrot:getWidth(), 10)
        end
    CameraMgr.detach()

    local mode = SCREEN_FILTER_MODES[current_screen_filter_mode]
    lg.setColor(0, 0, 0, 1)
    lg.print("Press PageUp/PageDown to change screen smoothing level", 700, 10)
    lg.print("Screen smoothing: " .. mode.label, 700, 30)
end


function love.mousemoved(x, y, dx, dy, istouch)
    if active_drag_buttons <= 0 then
        return
    end

    local camera_x, camera_y = CameraMgr.getCoords()
    local scale_x, scale_y = CameraMgr.getScale()
    CameraMgr.setCoords(camera_x - dx / scale_x, camera_y - dy / scale_y)
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

    local current_scale = CameraMgr.getScale()
    local target_scale = math.clamp(current_scale * (CAMERA_ZOOM_STEP ^ y), CAMERA_MIN_SCALE, CAMERA_MAX_SCALE)
    if target_scale == current_scale then
        return
    end

    local mouse_x, mouse_y = love.mouse.getPosition()
    set_camera_zoom(target_scale, mouse_x, mouse_y)
end


function love.keypressed(key, scancode, isrepeat)
    if isrepeat then return end

    if key == "pageup" then
        cycle_screen_filter_mode(1)
    elseif key == "pagedown" then
        cycle_screen_filter_mode(-1)
    end
end


function love.keyreleased(key, scancode)
end
