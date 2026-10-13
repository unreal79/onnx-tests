
function love.conf(t)
    DEBUG = true
    if DEBUG == nil then
        DEBUG = false
    end

    t.title = "ONNX test"
    game_version = "v0.3.0" -- post jam
    base_res_x = 1920 -- base resolution for scaling, not necessarily the actual window size
    base_res_y = 1080 -- base resolution for scaling, not necessarily the actual window size
    t.window.width = base_res_x
    t.window.height = base_res_y
    if DEBUG then
        t.window.width = 1280
        t.window.height = 720
        t.console = true
    else
        t.console = false
    end
    t.window.resizable = true
    t.window.windowed = true
    t.window.centered = true
    t.version = "11.5" -- minimum required LÖVE version
    t.window.highdpi = true -- enable high DPI mode for better scaling
    t.window.usedpiscale = true -- use high DPI scaling
end
