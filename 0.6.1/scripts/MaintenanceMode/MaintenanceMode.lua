-- MaintenanceMode.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


local Methods = {}


-- Add [ MaintenanceMode = require("MaintenanceMode") ] to the top of server.lua

-- Find "function UpdateTime()" inside server.lua and insert
-- [ MaintenanceMode.CheckIfActive() ]
-- directly underneath it.

-- Find "myMod.OnPlayerConnect(pid, playerName)" inside server.lua and insert:
-- [ MaintenanceMode.Bouncer(pid) ]
-- directly underneath it.


local maintenanceFile = "/path/to/maintenance.lock"
local lastMessage = ""


Methods.CheckIfActive = function()
    local lastPid

    local f = io.open(maintenanceFile, "r")

    if f ~= nil and tableHelper.getCount(Players) > 0 then
        local timer = tes3mp.CreateTimerEx("WarningTimerExpired", time.seconds(10), "i", 0)
        tes3mp.StartTimer(timer)

        local message = color.Crimson
        message = message .. "The server is going into maintenance mode.\n"
        message = message .. "To prevent file corruption, you will be kicked within 10 seconds.\n"
        message = message .. color.Default

        lastPid = tes3mp.GetLastPlayerId()
        for pid = 0, lastPid do
            if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and message ~= lastMessage then
                tes3mp.SendMessage(pid, message, true)
                lastMessage = message
                break
            end
        end
    end
end


Methods.Bouncer = function(pid)
    if Players[pid]:IsAdmin() == false then
        local f= io.open(maintenanceFile, "r")
        if f ~=nil then Players[pid]:Kick() end
    end
end


function WarningTimerExpired()
    local lastPid

    if tableHelper.getCount(Players) > 0 then
        lastPid = tes3mp.GetLastPlayerId()

        for pid = 0, lastPid do
            if Players[pid] ~= nil and Players[pid]:IsLoggedIn() and Players[pid]:IsAdmin() == false then
                Players[pid]:Kick()
            end
        end
    end
end


return Methods
