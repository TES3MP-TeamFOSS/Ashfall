-- TES3MP Localisation -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
colour = import(getModuleFolder() .. "colour.lua")
Config.Localisation = import(getModuleFolder() .. "config.lua")

if Config.Localisation.enableAutoMode == true then
    http = require("socket.http")
    ltn12 = require("ltn12")
end


local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")


function CommandHandler(player, args)
    if args[1] == "set" then
        if args[2] ~= nil then
            LanguageSet(player, args[2])
            return true
        end
    end

    if args[1] == "auto" then
        if Config.Localisation.enableAutoMode == true then
            LanguageModeToggle(player)
        else
            player:message(colour.Neutral .. _(player, locales, "featureDisabled") .. colour.Default .. ".\n", false)
        end
        return true
    end

    Help(player)
    return true
end


function Help(player)
    local lang = LanguageGet(player)

    local f = io.open(getDataFolder() .. "help_" .. lang .. ".txt", "r")
    if f == nil then
        return false
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, _(player, locales, "close"))
end


function LanguageGet(player)
    storage = JsonInterface.load(getDataFolder() .. "storage.json")
    local playerName = string.lower(player.name)

    if storage[playerName] == nil then
        return "en"
    end

    return storage[playerName].lang
end


function LanguageModeToggle(player)
    local playerName = string.lower(player.name)
    local playerLang = LanguageGet(player)

    if storage[playerName] == nil then
        storage[playerName] = {}
        storage[playerName].autoMode = true
    end

    if storage[playerName].autoMode == true then
        LanguageSet(player, playerLang)
        storage = JsonInterface.load(getDataFolder() .. "storage.json")
        storage[playerName].autoMode = false
    else
        LanguageSet(player, playerLang, true)
        storage = JsonInterface.load(getDataFolder() .. "storage.json")
        storage[playerName].autoMode = true
    end

    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function LanguageSet(player, lang, autoMode)
    autoMode = autoMode or false

    local playerName = string.lower(player.name)

    if storage[playerName] == nil then
        storage[playerName] = {}
    end

    if autoMode == false then
        storage[playerName].lang = lang
    else
        local resp = {}
        -- Needs to be fixed asap:
        local ipAddr = "188.68.43.183"
        local url = "http://freegeoip.net/csv/" .. ipAddr

        http.request{
            url = url,
            sink = ltn12.sink.table(resp)
        }

        local index = 0
        for substr in string.gmatch(resp[1], '([^,]+)') do
            if index == 1 then
                storage[playerName].lang = string.lower(substr)
                break
            end
            index = index + 1
        end
    end

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


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   local playerName = string.lower(player.name)

                   if Config.Localisation.enableAutoMode == true then
                       if storage[playerName] ~= nil then
                           if storage[playerName].autoMode == false then
                               return true
                           end
                       end

                       local playerLang = LanguageGet(player)
                       LanguageSet(player, playerLang, true)
                   end
                   return true
end)


CommandController.registerCommand("lang", CommandHandler, colour.Command .. "/lang" .. colour.Default .. " - Localisation system.")


Data._ = _
Data.LanguageGet = LanguageGet
