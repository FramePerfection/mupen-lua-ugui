--- mupen-lua-ugui test runner
--- https://github.com/Aurumaker72/mupen-lua-ugui

function folder(file)
    local s = debug.getinfo(2, 'S').source:sub(2)
    local p = file:gsub('[%(%)%%%.%+%-%*%?%^%$]', '%%%0'):gsub('[\\/]', '[\\/]') .. '$'
    return s:gsub(p, '')
end

local groups = {
    dofile(folder('runner.lua') .. 'button.lua'),
    dofile(folder('runner.lua') .. 'toggle_button.lua'),
    dofile(folder('runner.lua') .. 'carrousel_button.lua'),
}

local verbose = true

for key, group in pairs(groups) do
    print(string.format('Setting up %s...', group.name or ('test ' .. key)))

    -- Reset the ugui state completely between groups
    dofile(folder('tests\\runner.lua') .. 'mupen-lua-ugui.lua')

    if group.setup then
        group.setup()
    end

    for _, test in pairs(group.tests) do
        -- Optionally reset the state between individual tests too
        if group.keep_state_between_tests then
            dofile(folder('tests\\runner.lua') .. 'mupen-lua-ugui.lua')
        end

        local passed = true

        local test_context = {
            fail = function()
                passed = false
            end,
            log = function(str)
                if verbose then
                    print('\t[@] ' .. str)
                end
            end,
        }

        test.func(test_context)

        if passed then
            print(string.format('\t%s passed', test.name))
        else
            print(string.format('\t%s failed [!!!]', test.name))
        end
    end
    
    print('')
end