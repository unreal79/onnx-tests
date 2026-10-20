-- main.lua

---- Main working mode. Options: "upscaling", "inpainting", "background_removal", "colorizing"
local WORKING_MODE = "upscaling"
USE_DIRECTML = true -- Set to false to use CPU instead of GPU

local IMAGE_PATH = "assets/parrot.png" -- Main input image
local IMAGE_WITH_HOLES_PATH = "assets/parrot_with_holes.png" -- Input image with transparent "holes" for inpainting
-- local IMAGE_BW_PATH = "assets/parrot_bw.png" -- Input image in black and white
---- eiffel_bw.png image size is 982x1228, eiffel_bw_small.png is 576x720
-- local IMAGE_BW_PATH = "assets/eiffel_bw.png" -- Input image in black and white
local IMAGE_BW_PATH = "assets/eiffel_bw_small.png" -- Input image in black and white, smaller version

---- Models. Uncomment the one you want to use for upscaling.
local UPSCALER_TILE_SIZE = 256
local UPSCALER_TILE_OVERLAP = 32
local MODEL_UPSCALER_PATH = "models/upscale/4x-ClearRealityV1.onnx" -- 8 sec, x4, ADVANCED, DirectML: 3 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-Archivist_Soft.onnx" -- 7 sec, bad, eats details
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-Kim2091-DeJpeg-v0.onnx" -- 36 sec, good, DirectML: 5 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-Restoration-jpg-ESRGAN_64nf_23nb-jpg40_60-vyls.onnx" -- 200 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/4xNomos2_realplksr_dysample_256_fp32_fullyoptimized.onnx" -- 200 sec, x8, very bad
-- local MODEL_UPSCALER_PATH = "models/upscale/4xNomosWebPhoto_RealPLKSR.onnx" -- 110 sec, x4, ADVANCED, sharp, DirectML: 115 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/4x-ClearRealityV1-fp32-opset17.onnx" -- 8 sec, x4, ADVANCED, DirectML: 3 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/4x-UltraSharp-fp32-opset17.onnx" -- 220 sec, x4, ADVANCED, sharp, DirectML: 21 sec!!!
-- local MODEL_UPSCALER_PATH = "models/upscale/4x-UltraSharpV2_Lite_fp32_op17.onnx" -- 110 sec, x4, ADVANCED, creates halo inside, DirectML: 115 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/1x-SuperScale_Alt_RPLKSR_S.onnx" -- 40 sec, x1, average, DirectML: 33 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/4x_foolhardy_Remacri.onnx" -- 220 sec, x4, average, too sharp, DirectML: 20 sec!!!
-- local MODEL_UPSCALER_PATH = "models/upscale/4xPurePhoto-RealPLSKR.onnx" -- 118 sec, x4, bad, tile visible, DirectML: 120 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/4xPurePhoto-Span.onnx" -- 8 sec, x4, very good, darkens image, DirectML: 3 sec
-- local MODEL_UPSCALER_PATH = "models/upscale/4xLSDIRCompactv2.onnx" -- 8 sec, x4, average
-- local MODEL_UPSCALER_PATH = "models/upscale/ArtCNN_R8F64_RGB.onnx" -- 12 sec, x2, average
-- local MODEL_UPSCALER_PATH = "models/upscale/hdrtvnetpp_ensemble_dynamic.onnx" -- 4 sec, x1, bad, output in BT.2020 color
-- local MODEL_UPSCALER_PATH = "models/upscale/BSRGAN.onnx" -- 235 sec, x4, good, fixes JPEG halo, DirectML: 20 sec!!!
-- local MODEL_UPSCALER_PATH = "models/upscale/BSRGANx2.onnx" -- 230 sec, x2, good, fixes JPEG halo, DirectML: 19 sec!!!
-- local MODEL_UPSCALER_PATH = "models/upscale/BSRNet.onnx" -- 230 sec, x4, good, fixes JPEG halo, DirectML: 21 sec!!!
-- local MODEL_UPSCALER_PATH = "models/upscale/realesr-general-wdn-x4v3.onnx" -- 15 sec, x4, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/up4x_latest_conservative.onnx" -- 20 sec, x4, average
-- local MODEL_UPSCALER_PATH = "models/upscale/upscayl-remacri-4x.onnx" -- 230 sec, x4, average, too sharp, DirectML: 20 sec!!!
-- local MODEL_UPSCALER_PATH = "models/upscale/upscale-realplksr-onnx_x4.onnx" -- 190 sec, x8, very bad
-- local MODEL_UPSCALER_PATH = "models/upscale/waifu2x_vgg7_photo_noise0.onnx" -- 4 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/waifu2x_vgg7_photo_noise3.onnx" -- 4 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/waifu2x_vgg7_photo_scale2x.onnx" -- 4 sec, x1, very good
-- local MODEL_UPSCALER_PATH = "models/upscale/websr_cnn2x_l_rl.onnx" -- 2 sec, x2, average, adds JPEG halo

local MODEL_COLORIZER_TYPE = "ddcolor" -- possible values: "ddcolor", "deoldify", "colorize"
local MODEL_COLORIZER_PATH = "models/colorize/ddcolor-512-fp16.onnx" -- 11/16 sec, very good, average RAM hungry, DirectML wrong colorizing
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor_modelscope.onnx" -- 17/19 sec, very good, RAM hungry
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor_artistic.onnx" -- 17/25 sec, good, but very small bugs, RAM hungry
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor_paper_tiny.onnx" -- 6/6 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor-fp16.onnx" -- 3/3 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/colorear_v1.onnx" -- 3/3 sec, ok, but big bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor-large-hq8.onnx" -- 4/7 sec, good, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor-large-int8.onnx" -- 9/9 sec, very good, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor-tiny.onnx" -- 6/6 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor_tiny_fp16.onnx" -- 7/8 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ddcolor-tiny-fp16.onnx" -- 7/9 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/photorestore-ddcolor.onnx" -- 7/7 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/ptl1998naganodevall-ddcolor.onnx" -- 3/4 sec, ok, but small bugs
-- local MODEL_COLORIZER_PATH = "models/colorize/DeOldifyArtistic_dyn.onnx" -- 26/97 sec, average RAM hungry, DirectML: 20/VRAM sec
-- local MODEL_COLORIZER_PATH = "models/colorize/DeOldifyStable_dyn.onnx" -- 33/155 sec, RAM hungry
-- local MODEL_COLORIZER_PATH = "models/colorize/DeoldifyVideo_dyn.onnx" -- 32/81 sec, RAM hungry
-- local MODEL_COLORIZER_PATH = "models/colorize/deoldify_quantized.onnx" -- 4/8 sec, bad, many bugs everywhere
-- local MODEL_COLORIZER_PATH = "models/colorize/manga-colorize-fp16.onnx" -- 20/48 sec, bad, low resolution

local BACKGROUND_REMOVAL_THRESHOLD = 0.25
local MODEL_BG_REMOVER_PATH = "models/bg_remove/birefnet-lite-512.onnx" -- 12 sec, above average RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/BiRefNet_512x512_fp16.onnx" -- 40 sec, average RAM hungry, DirectML: 20 sec
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/BiRefNet_lite.onnx" -- 50 sec, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/BiRefNet_lite_fp16.onnx" -- 70 sec, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/u2net.onnx" -- 4 sec
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/u2netp.onnx" -- 1 sec
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/fey-nobg_fp16.onnx" -- 80 sec, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/lucida.onnx" -- 65 sec, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/RMBG-2.0_fp16.onnx" -- 75 sec, very RAM hungry, crashed with SetSessionGraphOptimizationLevel 1
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/RMBG-2.0_quantized.onnx" -- 100 sec, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/RMBG-2.0_int8.onnx" -- 110 sec, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/rmbg_q4f16.onnx" -- 130 sec, very RAM hungry, requires setting width to 1024
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/rmbg-1-4.onnx" -- 5 sec, very bad result
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/rmbg-1-4_quantized.onnx" -- 5 sec, very bad result
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/rmbg.onnx" -- 5 sec, very bad result
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/quitar_fondo_v2.onnx" -- 30 sec, threshold dependent, very RAM hungry
-- local MODEL_BG_REMOVER_PATH = "models/bg_remove/isnet-general-use.onnx" -- 2 sec, need code changed

local INPAINTER_ALPHA_THRESHOLD = 0.001
local MODEL_INPAINTER_PATH = "models/inpaint/inpainting_lama_2025jan.onnx" -- 25 sec, not DirectML compatible
-- local MODEL_INPAINTER_PATH = "models/inpaint/lama_fp32.onnx" -- 29 sec, not DirectML compatible
-- local MODEL_INPAINTER_PATH = "models/inpaint/lama_fp16.onnx" -- 10 sec, not DirectML compatible
-- local MODEL_INPAINTER_PATH = "models/inpaint/lama-manga-dynamic.onnx" -- 25 sec
-- local MODEL_INPAINTER_PATH = "models/inpaint/lama_fp32_js.onnx" -- 10 sec, not DirectML compatible
-- local MODEL_INPAINTER_PATH = "models/inpaint/lama_1024.onnx" -- 58 sec
-- local MODEL_INPAINTER_PATH = "models/inpaint/lama_2048.onnx" -- 250 sec, very RAM hungry

local CAMERA_ZOOM_STEP = 1.15
local CAMERA_MIN_SCALE = 0.2
local CAMERA_MAX_SCALE = 16
local SCREEN_FILTER_MODES = {
    { label = "Nearest", min = "nearest", mag = "nearest" },
    { label = "Linear", min = "linear", mag = "linear" },
    { label = "Linear min / Nearest mag", min = "linear", mag = "nearest" },
    { label = "Nearest min / Linear mag", min = "nearest", mag = "linear" },
}
local THREAD_WORKER_PATH = "thread_worker.lua"

io.popen("chcp 65001") -- set console code page to UTF-8
SYSTEM_CODE_PAGE = 1251

require("libs.errorhandler")
utf8 = require("utf8")
require("utils")
-- Onnx = require("onnx")
Threading = require("libs.threading")
CameraMgr = require("libs.CameraMgr.lib.CameraMgr").newManager()

lg = love.graphics
la = love.audio

local img_parrot = lg.newImage(IMAGE_PATH) -- Main input image
local img_parrot_with_holes = lg.newImage(IMAGE_WITH_HOLES_PATH)
local img_parrot_bw = lg.newImage(IMAGE_BW_PATH)
local img_no_background = nil -- output image after background removal
local img_upscaled = nil -- output image after upscaling
local img_inpainted = nil -- output image after inpainting
local img_colorized = nil -- output image after colorizing
local font_mplusrounded16 = lg.newFont("assets/fonts/MPLUSRounded1c-Regular.ttf", 16)
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
    apply_screen_filter_to_image(img_parrot_bw)
    apply_screen_filter_to_image(img_upscaled)
    apply_screen_filter_to_image(img_no_background)
    apply_screen_filter_to_image(img_inpainted)
    apply_screen_filter_to_image(img_colorized)
    print_log("Screen smoothing: " .. mode.label)
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
        print_log("Background removal is already running")
        return
    end

    local ok, err = Threading.run(THREAD_WORKER_PATH, 1, {"remove_background"})
    if not ok then
        print_log("Failed to start the worker thread: " .. tostring(err))
        return
    end

    local command = string.format("remove_background|%s|%s|%s|%s", MODEL_BG_REMOVER_PATH, IMAGE_PATH,
            tostring(BACKGROUND_REMOVAL_THRESHOLD), tostring(USE_DIRECTML))
    ok, err = Threading.command(1, command)
    if not ok then
        print_log("Failed to queue background removal: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_log("Started background removal in a worker thread...")
end

local function start_upscale()
    if Threading.is_running(2) then
        print_log("Upscale is already running")
        return
    end

    local ok, err = Threading.run(THREAD_WORKER_PATH, 2, {"upscale"})
    if not ok then
        print_log("Failed to start the worker thread: " .. tostring(err))
        return
    end

    local command = string.format("upscale|%s|%s|%s|%s|%s", MODEL_UPSCALER_PATH, IMAGE_PATH,
            tostring(UPSCALER_TILE_SIZE), tostring(UPSCALER_TILE_OVERLAP), tostring(USE_DIRECTML))
    ok, err = Threading.command(2, command)
    if not ok then
        print_log("Failed to queue upscale: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_log("Started upscale in a worker thread...")
end


local function start_inpaint()
    if Threading.is_running(3) then
        print_log("Inpaint is already running")
        return
    end

    local ok, err = Threading.run(THREAD_WORKER_PATH, 3, {"inpaint"})
    if not ok then
        print_log("Failed to start the worker thread: " .. tostring(err))
        return
    end

    local command = string.format("inpaint|%s|%s|%s|%s", MODEL_INPAINTER_PATH, IMAGE_WITH_HOLES_PATH,
            tostring(INPAINTER_ALPHA_THRESHOLD), tostring(USE_DIRECTML))
    ok, err = Threading.command(3, command)
    if not ok then
        print_log("Failed to queue inpaint: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_log("Started inpainting in a worker thread...")
end


local function start_colorizing()
    if Threading.is_running(4) then
        print_log("Colorizing is already running")
        return
    end

    local ok, err = Threading.run(THREAD_WORKER_PATH, 4, {"colorize"})
    if not ok then
        print_log("Failed to start the worker thread: " .. tostring(err))
        return
    end

    local command = string.format("colorize|%s|%s|%s|%s", MODEL_COLORIZER_PATH, IMAGE_BW_PATH,
        MODEL_COLORIZER_TYPE, tostring(USE_DIRECTML))
    ok, err = Threading.command(4, command)
    if not ok then
        print_log("Failed to queue colorizing: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_log("Started colorizing in a worker thread...")
end


local function final_message_and_save_image(thread_id, image_data, model_path)
    print_log(string.format("ONNX processing time: %.3f seconds",
        love.timer.getTime() - processing_start_time))
    print_log(string.format("Memory usage - RAM: %d " ..
        "MB, Virtual: %d MB, Peak: %d MB", get_memory_usage()))
    processing_start_time = nil
    last_elapsed_seconds = nil
    Threading.stop(thread_id)

    if image_data == nil then return end

    local output_path = model_path:gsub("^models/", "_output/"):gsub("%.onnx$", ".png")
    local absolute_output_path = love.filesystem.getSource() .. "/" .. output_path
    absolute_output_path = codepage2codepage(absolute_output_path, 65001, SYSTEM_CODE_PAGE)
    local absolute_output_dir = absolute_output_path:match("^(.+)/[^/]+$")
    local normalized_output_dir = absolute_output_dir:gsub("/", package.config:sub(1, 1))

    local ok, err_or_result = pcall(function()
        print_log("Saving processed image to: " .. codepage2codepage(absolute_output_path, SYSTEM_CODE_PAGE, 65001))
        print_log("Creating output directory: " .. codepage2codepage(normalized_output_dir, SYSTEM_CODE_PAGE, 65001))
        local f, err = io.popen("mkdir " .. normalized_output_dir)
        love.timer.sleep(0.1)
        if f == nil then
            print_log("Failed to create subprocess: " .. tostring(err))
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
        print_log("Saved processed image to: " .. output_path)
    else
        print_log("Failed to save processed image: " .. tostring(err_or_result))
    end
end


function love.load()
    math.randomseed( os.time() )
    CameraMgr.setCoords(lg.getWidth() / 2, lg.getHeight() / 2)
    apply_screen_filter_mode()

    print_log("Love2D loaded")
    local working_set, commit_size, peak_working_set = get_memory_usage()
    if working_set and commit_size and peak_working_set then
        print_log(string.format("Memory usage - Working Set: %.2f MB, Commit " ..
            "Size: %.2f MB, Peak Working Set: %.2f MB", working_set, commit_size, peak_working_set))
    else
        print_log("Failed to get memory usage")
    end

    if WORKING_MODE == "background_removal" then
        start_background_removal()
    elseif WORKING_MODE == "upscaling" then
        start_upscale()
    elseif WORKING_MODE == "inpainting" then
        start_inpaint()
    elseif WORKING_MODE == "colorizing" then
        start_colorizing()
    else
        error("Unknown working mode: " .. tostring(WORKING_MODE) ..
            ". WORKING_MODE is expected to be 'background_removal', 'upscaling', " ..
            "'inpainting', or 'colorizing'")
    end
end


function love.update(dt)
    Threading.update()
    CameraMgr.update(dt)

    if processing_start_time then
        for i = 1, 4 do
            if Threading.has_crashed(i) then
                print_log("Worker thread " .. tostring(i) .. " has crashed")
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
            print_log(string.format("  [Timer]: %d seconds. Memory usage - RAM: %d " ..
                "MB, Peak: %d MB", elapsed_seconds, working_set, peak_working_set))

            -- Check messages from worker 1 - background removal
            local last_message_1 = Threading.consume_last_message(1)
            if last_message_1 and last_message_1:match("^remove_background_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message_1:sub(#"remove_background_done:" + 1)), "_")
                local output_image_data = love.image.newImageData(decoded_FileData)
                img_no_background = lg.newImage(output_image_data)
                apply_screen_filter_to_image(img_no_background)
                print_log("Background removed from image successfully")
                final_message_and_save_image(1, output_image_data, MODEL_BG_REMOVER_PATH)
            elseif last_message_1 and last_message_1:match("^remove_background_error:") then
                local error_text = last_message_1:sub(#"remove_background_error:" + 1)
                print_log("Background removal failed: " .. error_text)
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
                print_log("Image upscaled successfully")
                final_message_and_save_image(2, output_image_data, MODEL_UPSCALER_PATH)
            elseif last_message_2 and last_message_2:match("^upscale_error:") then
                local error_text = last_message_2:sub(#"upscale_error:" + 1)
                print_log("Image upscaling failed: " .. error_text)
                final_message_and_save_image(2)
            end

            -- Check messages from worker 3 - inpainting
            local last_message_3 = Threading.consume_last_message(3)
            if last_message_3 and last_message_3:match("^inpaint_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message_3:sub(#"inpaint_done:" + 1)), "_")
                local output_image_data = love.image.newImageData(decoded_FileData)
                img_inpainted = lg.newImage(output_image_data)
                apply_screen_filter_to_image(img_inpainted)
                print_log("Image inpainted successfully")
                final_message_and_save_image(3, output_image_data, MODEL_INPAINTER_PATH)
            elseif last_message_3 and last_message_3:match("^inpaint_error:") then
                local error_text = last_message_3:sub(#"inpaint_error:" + 1)
                print_log("Image inpainting failed: " .. error_text)
                final_message_and_save_image(3)
            end

            -- Check messages from worker 4 - colorizing
            local last_message_4 = Threading.consume_last_message(4)
            if last_message_4 and last_message_4:match("^colorize_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message_4:sub(#"colorize_done:" + 1)), "_")
                local output_image_data = love.image.newImageData(decoded_FileData)
                img_colorized = lg.newImage(output_image_data)
                apply_screen_filter_to_image(img_colorized)
                print_log("Image colorized successfully")
                final_message_and_save_image(4, output_image_data, MODEL_COLORIZER_PATH)
            elseif last_message_4 and last_message_4:match("^colorize_error:") then
                local error_text = last_message_4:sub(#"colorize_error:" + 1)
                print_log("Image colorizing failed: " .. error_text)
                final_message_and_save_image(4)
            end
        end
    end
end


function love.quit()
    Threading.shutdown()
end


function love.draw()
    lg.clear(0.85, 0.85, 0.85, 1)
    local checker_size = 25
    local screen_width = lg.getWidth()
    local screen_height = lg.getHeight()

    for y = 0, screen_height, checker_size do
        for x = 0, screen_width, checker_size do
            if ((x / checker_size) + (y / checker_size)) % 2 == 0 then
                lg.setColor(0.85, 0.85, 0.85, 1)
            else
                lg.setColor(0.0, 0.0, 0.65, 1)
            end
            lg.rectangle("fill", x, y, checker_size, checker_size)
        end
    end

    lg.setColor(1, 1, 1, 1)
    lg.setFont(font_mplusrounded16)

    local source_image = img_parrot
    if WORKING_MODE == "colorizing" then
        source_image = img_parrot_bw
    end

    CameraMgr.attach()
        lg.draw(source_image, 200, 10)
        if WORKING_MODE == "inpainting" then
            lg.draw(img_parrot_with_holes, 200 + img_parrot:getWidth(), 10)
        end
        if img_upscaled then
            lg.draw(img_upscaled, 200 + img_parrot:getWidth(), 10)
        end
        if img_no_background then
            lg.draw(img_no_background, 200 + img_parrot:getWidth(), 10)
        end
        if img_inpainted then
            lg.draw(img_inpainted, 200 + img_parrot:getWidth() + img_parrot_with_holes:getWidth(), 10)
        end
        if img_colorized then
            lg.draw(img_colorized, 200 + source_image:getWidth(), 10)
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
