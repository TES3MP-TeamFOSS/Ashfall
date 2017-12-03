-- TES3MP UserConfig -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


function Init(playerName)
    local config = getDataFolder() .. "users" .. package.config:sub(1,1) .. string.lower(playerName) .. ".cfg"

    local f = io.open(config, "r")
    if f == nil then
        f = io.open(config, "w+")
        f:close()
    end
end


function GetValue(playerName, keyword)
    local settings = {}

    settings = ReadSettings(string.lower(playerName))
    if settings == nil then return 0 end

    local i = 0
    local hit = false
    for index, item in pairs(settings) do
        for substr in string.gmatch(item, '([^=]+)') do
            if substr == keyword then hit = true end
            if hit == true and i %2 ~= 0 then return substr end
            i = i + 1
        end
    end

    return 0
end


function SetValue(playerName, keyword, value)
    local settings = {}
    local tmp      = {}

    tmp = ReadSettings(string.lower(playerName))
    if tmp == nil then return false end

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
    WriteSettings(playerName, settings)

    return true
end


function ReadSettings(playerName)
    local config   = getDataFolder() .. "users" .. package.config:sub(1,1) .. string.lower(playerName) .. ".cfg"
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


function WriteSettings(playerName, settings)
    local config = getDataFolder() .. "users" .. package.config:sub(1,1) .. string.lower(playerName) .. ".cfg"

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


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   Init(player.name)
                   return true
end)


Data["UserConfig"] = {}
Data.UserConfig["GetValue"] = GetValue
Data.UserConfig["SetValue"] = SetValue
