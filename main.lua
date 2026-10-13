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
Threading = require("libs.threading.threading")
require("utils")

local WORKER_FILE = "thrd_wrk_bg_remover.lua"
local IMAGE_PATH = "assets/parrot.png"
local img_parrot = lg.newImage(IMAGE_PATH)
-- local img_parrot_data = love.image.newImageData("assets/parrot.png")
local img_no_background = nil
local MODEL_PATH = "models/u2net.onnx" -- u2netp, u2net, birefnet-lite-512
-- local MODEL_PATH = "models/birefnet-lite-512.onnx" -- u2netp, u2net, birefnet-lite-512
local THRESHOLD = 0.25
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

    local command = string.format("remove_background|%s|%s|%s", MODEL_PATH, IMAGE_PATH, tostring(THRESHOLD))
    ok, err = Threading.command(1, command)
    if not ok then
        print_to_screen("Failed to queue background removal: " .. tostring(err))
        return
    end

    processing_start_time = love.timer.getTime()
    last_elapsed_seconds = nil
    print_to_screen("Started background removal in a worker thread...")
end


function love.load()
    math.randomseed( os.time() )
    font_mplusrounded14 = lg.newFont("assets/fonts/MPLUSRounded1c-Regular.ttf", 14)
    lg.setFont(font_mplusrounded14)

    print_to_screen("Love2D loaded")

    -- local onnx_api, state = Onnx.init("onnxruntime/onnxruntime")
    -- if not onnx_api then
    --     local error_message = codepage2codepage(state.load_error, 1251, 866)
    --     print("Failed to initialize ONNX: " .. error_message)
    --     error_message = codepage2codepage(error_message, 866, 65001)
    --     print_to_screen("Failed to initialize ONNX: " .. error_message)
    --     return
    -- end

    start_background_removal()

    -- lg.present() -- force the graphics to update immediately
    love.timer.sleep(0.1) -- give some time for the graphics to update
end


function love.update(dt)
    Threading.update()

    if processing_start_time then
        local elapsed_seconds = math.floor(love.timer.getTime() - processing_start_time)
        if last_elapsed_seconds ~= elapsed_seconds and elapsed_seconds > 0 then
            last_elapsed_seconds = elapsed_seconds
            print_to_screen(string.format("  [Timer]: %d seconds", elapsed_seconds))
        end
    end

    local last_message = Threading.consume_last_message(1)
    if last_message and last_message:match("^remove_background_done:") then
        -- local output_path = last_message:sub(#"remove_background_done:" + 1)
        -- img_no_background = lg.newImage(output_path)
        local decoded_FileData = love.data.decode("data", "base64", last_message:sub(#"remove_background_done:" + 1))
        img_no_background = lg.newImage(decoded_FileData)
        print_to_screen("Background removed from image successfully")
        print_to_screen(string.format("ONNX processing time: %.3f seconds",
                love.timer.getTime() - processing_start_time))
        processing_start_time = nil
        last_elapsed_seconds = nil
        if Threading.is_running(1) then
            Threading.stop(1)
        end
    elseif last_message and last_message:match("^remove_background_error:") then
        local error_text = last_message:sub(#"remove_background_error:" + 1)
        print_to_screen("Background removal failed: " .. tostring(error_text))
        processing_start_time = nil
        last_elapsed_seconds = nil
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
