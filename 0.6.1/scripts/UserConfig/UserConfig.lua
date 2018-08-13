-- UserConfig.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


local Methods = {}


local userConfigPath = "/path/to/user_config/"


Methods.Init = function(pid)
    local config   = userConfigPath .. string.lower(tes3mp.GetName(pid)) .. ".txt"

    local f = io.open(config, "r")
    if f == nil then
        f = io.open(config, "w+")
        f:close()
    end
end


Methods.GetValue = function(pid, keyword)
    local settings = {}

    settings = ReadSettings(pid)
    if settings == nil then return -1 end

    local i   = 0
    local hit = false
    for index, item in pairs(settings) do
        for substr in string.gmatch(item, '([^=]+)') do
            if substr == keyword then hit = true end
            if hit == true and i %2 ~= 0 then return substr end
            i = i + 1
        end
    end

    return -1
end


Methods.SetValue = function(pid, keyword, value)
    local settings = {}
    local tmp      = {}

    tmp = ReadSettings(pid)
    if tmp == nil then return -1 end

    local i = 0
    for index, item in pairs(tmp) do
        for substr in string.gmatch(item, '([^=]+)') do
            if substr ~= keyword and i %2 == 0 then
                settings[index] = item
            end
            i = i + 1
        end
    end

    table.insert(settings, keyword .. "=" .. value)
    WriteSettings(pid, settings)

    return 0
end


function ReadSettings(pid)
    local config = userConfigPath .. string.lower(tes3mp.GetName(pid)) .. ".txt"
    local settings = {}

    local f = io.open(config, "r")
    if f == nil then
        return nil
    else
        for line in f:lines() do
            table.insert(settings, line)
        end
        f:close()
        return settings
    end

    return 0
end


function WriteSettings(pid, settings)
    local config = userConfigPath .. string.lower(tes3mp.GetName(pid)) .. ".txt"

    local f = io.open(config, "w+")
    if f == nil then
        return -1
    else
        for index, item in pairs(settings) do
            f:write(item .. "\n")
        end
        f:close()
        return 0
    end
end


return Methods
