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
require("utils")

font_mplusrounded14 = lg.newFont("assets/fonts/MPLUSRounded1c-Regular.ttf", 14)

local WORKER_FILE = "thrd_wrkr_bg_remover.lua" -- thread worker
local IMAGE_PATH = "assets/parrot.png"
local img_parrot = lg.newImage(IMAGE_PATH)
local img_upscaled = nil
local img_no_background = nil
-- local MODEL_UPSCALER_PATH = "models/4x-ClearRealityV1.onnx"
local MODEL_UPSCALER_PATH = "models/1x-Kim2091-DeJpeg-v0.onnx"
local MODEL_BG_REMOVER_PATH = "models/u2net.onnx"
-- local MODEL_BG_REMOVER_PATH = "models/birefnet-lite-512.onnx"
local BACKGROUND_REMOVAL_THRESHOLD = 0.25

local processing_start_time = nil
local last_elapsed_seconds = nil


local function start_background_removal()
    if Threading.is_running(1) then
        print_to_screen("Background removal is already running")
        return
    end

    local ok, err = Threading.run(WORKER_FILE, 1)
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
    print_to_screen("Starting ONNX upscale on the main thread...")
    local processing_start_time = love.timer.getTime()

    local ok, result_or_err = xpcall(function()
        local onnx_api, init_state = Onnx.init("onnxruntime/onnxruntime")
        if not onnx_api then
            error((init_state and init_state.load_error) or "Failed to initialize ONNX Runtime")
        end

        local session = Onnx.create_session(MODEL_UPSCALER_PATH)
        if not session or not session.session then
            error((session and tostring(session.message)) or "Failed to create ONNX session")
        end
        print(session.message)

        local image_data = love.image.newImageData(IMAGE_PATH)
        return Onnx.upscale(session, image_data)
    end, debug.traceback)

    if not ok then
        print_to_screen("Upscale failed: " .. tostring(result_or_err))
        return
    end

    img_upscaled = result_or_err
    print_to_screen("Image upscaled successfully")
    print_to_screen(string.format("ONNX processing time: %.3f seconds",
        love.timer.getTime() - processing_start_time))

    local working_set, commit_size, peak_working_set = get_memory_usage()
    if working_set and commit_size and peak_working_set then
        print_to_screen(string.format("Memory usage - RAM: %d MB, Virtual: %d MB, Peak: %d MB",
            working_set, commit_size, peak_working_set))
    end
end


function love.load()
    math.randomseed( os.time() )

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

    if processing_start_time then
        if Threading.has_crashed(1) then
            print_to_screen("Worker thread 1 has crashed")
            processing_start_time = nil
            last_elapsed_seconds = nil
            Threading.stop(1)
            Threading.shutdown()
            return
        end

        local elapsed_seconds = math.floor(love.timer.getTime() - processing_start_time)
        if last_elapsed_seconds ~= elapsed_seconds and elapsed_seconds > 0 then -- once per second
            last_elapsed_seconds = elapsed_seconds
            local working_set, commit_size, peak_working_set = get_memory_usage()
            print_to_screen(string.format("  [Timer]: %d seconds. Memory usage - RAM: %d " ..
                "MB, Virtual: %d MB", elapsed_seconds, working_set, commit_size))

            local last_message = Threading.consume_last_message(1)
            if last_message and last_message:match("^remove_background_done:") then
                local decoded_FileData = love.filesystem.newFileData(love.data.decode("data", "base64",
                        last_message:sub(#"remove_background_done:" + 1)), "_")
                img_no_background = lg.newImage(decoded_FileData)
                print_to_screen("Background removed from image successfully")
                print_to_screen(string.format("ONNX processing time: %.3f seconds",
                        love.timer.getTime() - processing_start_time))
                working_set, commit_size, peak_working_set = get_memory_usage()
                print_to_screen(string.format("Memory usage - RAM: %d " ..
                    "MB, Virtual: %d MB, Peak: %d MB", working_set, commit_size, peak_working_set))

                processing_start_time = nil
                last_elapsed_seconds = nil
                Threading.stop(1)
            elseif last_message and last_message:match("^remove_background_error:") then
                local error_text = last_message:sub(#"remove_background_error:" + 1)
                print_to_screen("Background removal failed: " .. tostring(error_text))
                processing_start_time = nil
                last_elapsed_seconds = nil
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
    lg.draw(img_parrot, 200, 10)
    if img_upscaled then
        lg.draw(img_upscaled, 200 + img_parrot:getWidth(), 10)
    end
    if img_no_background then
        lg.draw(img_no_background, 200 + img_parrot:getWidth(), 10)
    end
end


function love.mousemoved(x, y, dx, dy, istouch)
end


function love.mousepressed(x, y, button)
end


function love.wheelmoved(x, y)
end


function love.keypressed(key, scancode, isrepeat)
end


function love.keyreleased(key, scancode)
end
