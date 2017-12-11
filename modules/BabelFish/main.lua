-- TES3MP BabelFish -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
colour = import(getModuleFolder() .. "colour.lua")
Config.Localisation = import(getModuleFolder() .. "config.lua")
http = require("socket.http")
ltn12 = require("ltn12")


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
        return false
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, _(player, locales, "close"))
end


CommandController.registerCommand("trans", CommandHandler, colour.Command .. "/trans" .. colour.Default .. " - Translator.")
