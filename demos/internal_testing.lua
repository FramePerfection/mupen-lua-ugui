local function folder(file)
    local s = debug.getinfo(2, "S").source:sub(2)
    local p = file:gsub("[%(%)%%%.%+%-%*%?%^%$]", "%%%0"):gsub("[\\/]", "[\\/]") .. "$"
    return s:gsub(p, "")
end


dofile(folder('demos\\internal_testing.lua') .. 'mupen-lua-ugui.lua')

local initial_size = wgui.info()
wgui.resize(initial_size.width + 200, initial_size.height)
local index = 1
emu.atupdatescreen(function()
    BreitbandGraphics.renderers.d2d.fill_rectangle({
        x = initial_size.width,
        y = 0,
        width = 200,
        height = initial_size.height,
    }, {
        r = 253,
        g = 253,
        b = 253,
    })

    local keys = input.get()

    Mupen_lua_ugui.begin_frame(BreitbandGraphics.renderers.d2d, Mupen_lua_ugui.stylers.windows_10, {
        pointer = {
            position = {
                x = keys.xmouse,
                y = keys.ymouse,
            },
            is_primary_down = keys.leftclick,
        },
        keyboard = {
            held_keys = keys,
        },
    })



    Mupen_lua_ugui.combobox({
        uid = 0,
        is_enabled = true,
        rectangle = {
            x = initial_size.width + 10,
            y = 20,
            width = 90,
            height = 30,
        },
        items = {
            'Item A',
            'Item B',
            'Item C',
        },
        selected_index = 0,
    })
    if Mupen_lua_ugui.button({
            uid = 1,
            is_enabled = true,
            rectangle = {
                x = initial_size.width + 10,
                y = 90,
                width = 90,
                height = 30,
            },
            text = 'Test',
        }) then
        print(math.random())
    end

    Mupen_lua_ugui.combobox({
        uid = 2,
        is_enabled = true,
        rectangle = {
            x = initial_size.width + 100,
            y = 20,
            width = 90,
            height = 30,
        },
        items = {
            'Item A',
            'Item B',
            'Item C',
        },
        selected_index = 0,
    })
    Mupen_lua_ugui.combobox({
        uid = 3,
        is_enabled = true,
        rectangle = {
            x = initial_size.width + 100,
            y = 90,
            width = 90,
            height = 30,
        },
        items = {
            'Item A',
            'Item B',
            'Item C',
        },
        selected_index = 0,
    })

    index = Mupen_lua_ugui.carrousel_button({
        uid = 4,
        is_enabled = true,
        rectangle = {
            x = initial_size.width + 100,
            y = 150,
            width = 90,
            height = 30,
        },
        items = {
            'Item A',
            'Item B',
            'Item C',
        },
        selected_index = index,
    })

    Mupen_lua_ugui.end_frame()
end)

emu.atstop(function()
    wgui.resize(initial_size.width, initial_size.height)
end)
