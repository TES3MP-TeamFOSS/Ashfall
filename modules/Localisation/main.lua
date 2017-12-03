-- TES3MP Localisation -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
colour = import(getModuleFolder() .. "colour.lua")


local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")


function CommandHandler(player, args)
    if args[1] == "set" then
        if args[2] ~= nil then
            LanguageSet(player, args[2])
            return true
        end
    end

    Help(player)
    return true
end


function Help(player)
    local lang = LanguageGet(player)

    local f = io.open(getDataFolder() .. "help_" .. lang .. ".txt", "r")
    if f == nil then
        f = io.open(getDataFolder() .. "help.txt", "r")

        if f == nil then
            return false
        end
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, _(player, locales, "close"))
end


function LanguageGet(player)
    storage = JsonInterface.load(getDataFolder() .. "storage.json")
    playerName = string.lower(player.name)

    if storage[playerName] == nil then
        return "en"
    end

    return storage[playerName].lang
end


function LanguageSet(player, lang)
    playerName = string.lower(player.name)

    if storage[playerName] == nil then
        storage[playerName] = {}
    end

    storage[playerName].lang = lang
    JsonInterface.save(getDataFolder() .. "storage.json", storage)

    player:message(colour.Neutral .. _(player, locales, "langSet") .. ": " .. LanguageGet(player) .. "\n" .. colour.Default, false)
end


function _(player, locales, id)
    if locales[LanguageGet(player)] == nil then
        return locales["en"][id]
    end

    if locales[LanguageGet(player)][id] == nil then
        return locales["en"][id]
    end

    return locales[LanguageGet(player)][id]
end


CommandController.registerCommand("lang", CommandHandler, colour.Command .. "/lang" .. colour.Default .. " - Localisation system.")


Data._ = _
Data.LanguageGet = LanguageGet
