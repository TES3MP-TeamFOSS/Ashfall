-- TES3MP HardcoreMode -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
Config.HardcoreMode = import(getModuleFolder() .. "config.lua")
colour = import(getModuleFolder() .. "colour.lua")


local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")

Data.overrideChat = true


function CommandHandler(player, args)
    if args[1] == "toggle" then
        ModeToggle(player)
        return true
    end

    if args[1] == "ladder" then
        LadderShow(player)
        return true
    end

    Help(player)
    return true
end


function Help(player)
    local lang = Data.LanguageGet(player)

    local f = io.open(getDataFolder() .. "help_" .. lang .. ".txt", "r")
    if f == nil then
        return false
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, Data._(player, locales, "close"))
end


function ModeToggle(player, force)
    force = force or false

    local message = ""
    local playerName = string.lower(player.name)

    if storage[playerName] == nil then
        storage[playerName] = {}
        storage[playerName].name = player.name
        storage[playerName].isDeath = false
        storage[playerName].isEnabled = force
        storage[playerName].levelEntry = player.level
        storage[playerName].levelCurrent = player.level
    end

    if storage[playerName].isEnabled == true and force == false then
        if Config.HardcoreMode.force == true then --or Config.HardcoreMode.oneTimeDecision == true then
            message = colour.Caution .. Data._(player, locales, "noTurningBack") .. ".\n"
        else
            if storage[playerName].isDeath == false then
                storage[playerName] = nil
                message = colour.Neutral .. Data._(player, locales, "disabled") .. ".\n"
            else
                message = colour.Warning .. Data._(player, locales, "goneForGood") .. ". " .. Data._(player, locales, "noTurningBack") .. ".\n"
            end
        end
    else
        storage[playerName].isEnabled = true
        message = colour.Caution .. Data._(player, locales, "enabled") .. ".\n"
    end

    player:message(message, false)
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


-- Thanks to Texafornian (https://github.com/Texafornian).
function LadderShow(player)
    local message = ""
    local ladder = {}

    for index, item in pairs(storage) do
        if item.isDeath == false and item.isEnabled == true then
            --if Config.HardcoreMode.oneTimeDecision == true then
            --ladder[item.name] = item.levelCurrent
            --else
            ladder[item.name] = item.levelCurrent - item.levelEntry
            --end
        end
    end

    message = colour.Heading .. Data._(player, locales, "ladder") .. "\n\n"
    for index, item in spairs(ladder, function(t, a, b) return t[b] < t[a] end) do
        message = message .. index .. " (" .. item .. ")" .. "\n"
    end

    player:getGUI():customMessageBox(-1, message, Data._(player, locales, "close"))
end


-- https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end


Event.register(Events.ON_PLAYER_CELLCHANGE, function(player)
                   local playerName = string.lower(player.name)

                   if storage[playerName] ~= nil then
                       if storage[playerName].isDeath == true then
                           if player:getCell().description ~= Config.HardcoreMode.afterlife then
                               player:getCell().description = Config.HardcoreMode.afterlife
                           end
                       end
                   end
end)


Event.register(Events.ON_PLAYER_DEATH, function(player)
                   local playerName = string.lower(player.name)

                   storage[playerName].isDeath = true
                   JsonInterface.save(getDataFolder() .. "storage.json", storage)

                   Players.for_each(function(player)
                           player:message(colour.Warning .. player.name .. " " .. Data._(player, locales, "deathMessage") .. ".\n", false)
                   end)
end)


Event.register(Events.ON_PLAYER_ENDCHARGEN, function(player)
                   --if Config.HarcoreMode.oneTimeDecision == true then
                       -- Todo
                   --end

                   if Config.HardcoreMode.force == true then
                       ModeToggle(player, true)
                   else
                       ModeToggle(player)
                   end
end)


Event.register(Events.ON_PLAYER_LEVEL, function(player)
                   local playerName = string.lower(player.name)

                   if storage[playerName] ~= nil then
                       if storage[playerName].isDeath == false then
                           storage[playerName].levelCurrent = player.level
                       end
                   end

                   JsonInterface.save(getDataFolder() .. "storage.json", storage)
end)


Event.register(Events.ON_PLAYER_RESURRECT, function(player)
                   local playerName = string.lower(player.name)

                   if storage[playerName] ~= nil then
                       if storage[playerName].isDeath == true then
                           if player:getCell().description ~= Config.HardcoreMode.afterlife then
                               player:getCell().description = Config.HardcoreMode.afterlife
                           end
                       end
                   end
end)


Event.register(Events.ON_PLAYER_SENDMESSAGE, function(player, message)
                   local chatMessage = ("%s (%d): %s\n"):format(player.name, player.pid, message)
                   io.write(chatMessage)

                   if player:getCell().description == Config.HardcoreMode.afterlife then
                       Players.for_each(function(player)
                               if player:getCell().description == Config.HardcoreMode.afterlife then
                                   chatMessage = (colour.Neutral .. "%s " .. colour.Default .. "(%d): %s\n"):format(player.name, player.pid, message)
                                   player:message(chatMessage, false)
                               end
                       end)

                       return
                   end

                   player:message(colour.Default .. chatMessage, true)
end)


CommandController.registerCommand("hardcore", CommandHandler, colour.Command .. "/hardcore help" .. colour.Default .. " - Hardcore mode.")
