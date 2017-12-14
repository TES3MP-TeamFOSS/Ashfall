-- TES3MP MotD -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
Config.MotD = import(getModuleFolder() .. "config.lua")
colour = import(getModuleFolder() .. "colour.lua")


local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")


function Show(player, onConnect)
    onConnect = onConnect or false

    local lang = Data.LanguageGet(player)

    local f = io.open(getDataFolder() .. "motd_" .. lang .. ".txt", "r")
    if f == nil then
        f = io.open(getDataFolder() .. "motd_en.txt", "r")
        if f == nil then
            return false
        end
    end

    local message = f:read("*a")
    f:close()

    if onConnect == true then
        if storage[string.lower(player.name)] == nil then
            storage[string.lower(player.name)] = true
            JsonInterface.save(getDataFolder() .. "storage.json", storage)
        end

        if storage[string.lower(player.name)] == true then
            if player.level == 1 and player.levelProgress == 0 then
                player:getGUI():customMessageBox(211, message, Data._(player, locales, "close") .. ";" .. Data._(player, locales, "disable"))
            else
                player:getGUI():customMessageBox(212, message, Data._(player, locales, "close") .. ";" .. Config.MotD.spawnLocation .. ";" .. Data._(player, locales, "disable"))
            end
        end
    else
        player:getGUI():customMessageBox(213, message, Data._(player, locales, "close"))
    end

    return true
end


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   Show(player, true)
                   return true
end)


Event.register(Events.ON_GUI_ACTION, function(player, id, data)
                   if id == 211 then
                       if tonumber(data) == 1 then
                           storage[string.lower(player.name)] = false
                           JsonInterface.save(getDataFolder() .. "storage.json", storage)
                       end
                   end

                   if id == 212 then
                       if tonumber(data) == 1 then
                           player:getCell().description = Config.MotD.spawnLocation
                       end
                       if tonumber(data) == 2 then
                           storage[string.lower(player.name)] = false
                           JsonInterface.save(getDataFolder() .. "storage.json", storage)
                       end
                   end

                   if id == 213 then
                       if tonumber(data) == 0 then
                           storage[string.lower(player.name)] = true
                           JsonInterface.save(getDataFolder() .. "storage.json", storage)
                       end
                   end
end)


CommandController.registerCommand("motd", Show, colour.Command .. "/motd".. colour.Default .. " - Show message of the day.")
