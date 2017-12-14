-- TES3MP BabelFish -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
colour = import(getModuleFolder() .. "colour.lua")
Config.BabelFish = import(getModuleFolder() .. "config.lua")
http = require("socket.http")
url = require("socket.url")
ltn12 = require("ltn12")


local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")
Data.overrideChat = true


function CommandHandler(player, args)
    if args[1] == nil then
        ModeToggle(player)
        return true
    end

    if args[1] == "opt" then
        ConsentToggle(player)
        return true
    end

    Help(player)
    return true
end


function Help(player)
    local lang = Data.LanguageGet(player)

    local f = io.open(getDataFolder() .. "help_" .. lang .. ".txt", "r")
    if f == nil then
        f = io.open(getDataFolder() .. "help_en.txt", "r")
        if f == nil then
            return false
        end
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, Data._(player, locales, "close"))
end


function ModeToggle(player)
    local playerName = string.lower(player.name)

    if storage[playerName] == nil then
        storage[playerName] = {}
        storage[playerName].translate = false
    end

    local message
    if storage[playerName].translate == true then
        message = colour.Warning .. Data._(player, locales, "disabled")
        storage[playerName].translate = false
    else
        message = colour.Confirm .. Data._(player, locales, "enabled")
        storage[playerName].translate = true
    end

    player:message(0, message .. ".\n", false)
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function ConsentToggle(player)
    local playerName = string.lower(player.name)

    if storage[playerName] == nil then
        storage[playerName] = {}
        storage[playerName].consent = false
    end

    local message
    if storage[playerName].consent == true then
        message = colour.Warning .. Data._(player, locales, "optout")
        storage[playerName].consent = false
    else
        message = colour.Confirm .. Data._(player, locales, "optin")
        storage[playerName].consent = true
    end

    player:message(0, message .. ".\n", false)
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function Translate(from, to, text)
    local resp = {}
    local url = Config.BabelFish.url .. "?from=" .. from .. "&to=" .. to .. "&text=" .. url.escape(text)

    http.request{
        url = url,
        sink = ltn12.sink.table(resp)
    }

    return resp[1]
end


Event.register(Events.ON_PLAYER_SENDMESSAGE, function(player, message, channel)
                   if channel == nil then channel = 0 end

                   Data.BabelFishMessage = nil
                   local translations = {}
                   local chatMessage
                   local playerName = player.name
                   local playerPid = player.pid
                   local playerLang = Data.LanguageGet(player)

                   Players.for_each(function(receiver)
                           local receiverName = string.lower(receiver.name)
                           local receiverLang = Data.LanguageGet(receiver)

                           if translations[receiverLang] == nil then
                               if storage[string.lower(playerName)] ~= nil then
                                   if storage[string.lower(playerName)].consent == true and playerLang ~= receiverLang then
                                       translations[receiverLang] = Translate(playerLang, receiverLang, message)
                                   end
                               end

                               if translations[receiverLang] == nil then
                                  translations[receiverLang] = message
                               end
                           end

                           if storage[receiverName].translate == true then
                               chatMessage = ("%s (%d): %s\n"):format(playerName, playerPid, translations[receiverLang])
                           else
                               chatMessage = ("%s (%d): %s\n"):format(playerName, playerPid, message)
                           end

                           receiver:message(channel, chatMessage, false)
                   end)

                   if Config.BabelFish.forceSpecificTranslation == true then
                       if translations[Config.BabelFish.forcedLanguage] == nil and playerLang ~= Config.BabelFish.forcedLanguage then
                           translations[Config.BabelFish.forcedLanguage] = Translate(playerLang, Config.BabelFish.forcedLanguage, message)
                           Data.BabelFishMessage = translations[Config.BabelFish.forcedLanguage]
                       end
                   end

                   io.write(("Channel #%d %s"):format(channel, message))
end)


CommandController.registerCommand("babelfish", CommandHandler, colour.Command .. "/babelfish" .. colour.Default .. " - Translator.")
