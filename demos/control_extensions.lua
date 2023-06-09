function folder(thisFileName)
    local str = debug.getinfo(2, "S").source:sub(2)
    return (str:match("^.*/(.*).lua$") or str):sub(1, -(thisFileName):len() - 1)
end

dofile(folder('demos\\control_extensions.lua') .. 'mupen-lua-ugui.lua')


Mupen_lua_ugui.spinner = function(control)
    local value = control.value

    Mupen_lua_ugui.textbox({
        uid = control.uid,
        is_enabled = true,
        rectangle = {
            x = control.rectangle.x,
            y = control.rectangle.y,
            width = control.rectangle.width - 40,
            height = control.rectangle.height,
        },
        text = tostring(control.value)
    })

    if (Mupen_lua_ugui.button({
            uid = control.uid + 1,
            is_enabled = true,
            rectangle = {
                x = control.rectangle.x + control.rectangle.width - 40,
                y = control.rectangle.y,
                width = 40,
                height = control.rectangle.height / 2,
            },
            text = "^"
        }))
    then
        value = value + 1
    end

    if (Mupen_lua_ugui.button({
            uid = control.uid + 1,
            is_enabled = true,
            rectangle = {
                x = control.rectangle.x + control.rectangle.width - 40,
                y = control.rectangle.y + control.rectangle.height / 2,
                width = 40,
                height = control.rectangle.height / 2,
            },
            text = "v"
        }))
    then
        value = value - 1
    end

    return value
end

local initial_size = wgui.info()
wgui.resize(initial_size.width + 200, initial_size.height)
local some_number = 0

emu.atupdatescreen(function()
    BreitbandGraphics.renderers.d2d.fill_rectangle({
        x = initial_size.width,
        y = 0,
        width = 200,
        height = initial_size.height
    }, {
        r = 253,
        g = 253,
        b = 253
    })

    local keys = input.get()

    Mupen_lua_ugui.begin_frame(BreitbandGraphics.renderers.d2d, Mupen_lua_ugui.stylers.windows_10, {
        pointer = {
            position = {
                x = keys.xmouse,
                y = keys.ymouse,
            },
            is_primary_down = keys.leftclick
        },
        keyboard = {
            held_keys = keys
        }
    })

    some_number = Mupen_lua_ugui.spinner({
        uid = 1,
        is_enabled = true,
        rectangle = {
            x = initial_size.width + 10,
            y = 30,
            width = 80,
            height = 30,
        },
        value = some_number
    })

    Mupen_lua_ugui.end_frame()
end)

emu.atstop(function()
    wgui.resize(initial_size.width, initial_size.height)
end)
