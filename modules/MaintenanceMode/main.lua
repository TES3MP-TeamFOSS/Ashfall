-- TES3MP MaintenanceMode -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


colour = import(getModuleFolder() .. "colour.lua")


local timer
local status   = false
local lockFile = getDataFolder() .. package.config:sub(1, 1) .. "maintenance.lock"


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

        local message = colour.Caution .. "The server is going into maintenance mode.\nTo prevent file corruption, you will be kicked within 10 seconds.\n" .. colour.Default
        Players.for_each(function(player)
                player:message(message, false)
        end)
        f:close()
        timer:restart(10000)
    else
        status = false
        timer:restart(1000)
    end
end


Event.register(Events.ON_POST_INIT, function()
                   timer = TimerCtrl.create(CheckStatus, 1000, { timer })
                   timer:start()
end)


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   local f = io.open(lockFile, "r")
                   if f ~= nil then player:kick() end
                   return true
end)
