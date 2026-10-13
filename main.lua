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
require("utils")

local img_parrot = lg.newImage("assets/parrot.png")
local img_parrot_data = love.image.newImageData("assets/parrot.png")
local img_no_background = nil
local MODEL = "models/u2net.onnx" -- u2netp, u2net


function love.load()
    math.randomseed( os.time() )
    font_mplusrounded14 = lg.newFont("assets/fonts/MPLUSRounded1c-Regular.ttf", 14)
    lg.setFont(font_mplusrounded14)

    print_to_screen("Love2D loaded")

    local time_initial = love.timer.getTime()

    local onnx_api, state = Onnx.init("onnxruntime/onnxruntime")
    if not onnx_api then
        local error_message = codepage2codepage(state.load_error, 1251, 866)
        print("Failed to initialize ONNX: " .. error_message)
        error_message = codepage2codepage(error_message, 866, 65001)
        print_to_screen("Failed to initialize ONNX: " .. error_message, true)
    else
        print_to_screen("ONNX initialized successfully")
        local session = Onnx.create_session(MODEL)
        print_to_screen(session.message)
        img_no_background = Onnx.remove_background(session, img_parrot_data)

        local time_final = love.timer.getTime()
        print_to_screen("Background removed from image successfully")
        print_to_screen(string.format("ONNX processing time: %.3f seconds", time_final - time_initial))
    end

    -- lg.present() -- force the graphics to update immediately
    love.timer.sleep(2.1) -- give some time for the graphics to update
end


function love.update(dt)
end


function love.quit()
    -- Threading.shutdown()
end


function love.draw()
    lg.print(love.graphics.getStats().drawcalls, 10, 10)
    lg.draw(img_parrot, 200, 10)
    lg.draw(img_no_background or img_parrot, 210 + img_parrot:getWidth(), 10)
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
