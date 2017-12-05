-- TES3MP MaintenanceMode -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
colour = import(getModuleFolder() .. "colour.lua")


local timerCheckStatus
local status = false
local lockFile = getDataFolder() .. package.config:sub(1, 1) .. "maintenance.lock"
local locales = JsonInterface.load(getDataFolder() .. "locales.json")


function CheckStatus()
    local f = io.open(lockFile, "r")

    if status == true then
        Players.for_each(function(player)
                player:kick()
        end)
        status = false
    end

    if f ~= nil then
        status = true

        Players.for_each(function(player)
                local message = colour.Caution .. Data._(player, locales, "warning") .. ".\n" .. colour.Default
                player:getGUI():customMessageBox(-1, message, Data._(player, locales, "close"))
        end)
        f:close()
        timerCheckStatus:restart(10000)
    else
        status = false
        timerCheckStatus:restart(1000)
    end
end


Event.register(Events.ON_POST_INIT, function()
                   timerCheckStatus = TimerCtrl.create(CheckStatus, 1000, { timerCheckStatus })
                   timerCheckStatus:start()
end)


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   local f = io.open(lockFile, "r")
                   if f ~= nil then player:kick() end
                   return true
end)
