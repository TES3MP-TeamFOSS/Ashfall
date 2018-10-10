-- PvP.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


require("color")


local Methods = {}


-- Add [ PvP = require("PvP") ] to the top of myMod.lua
-- Find "Players[pid]:ProcessDeath()" inside myMod.lua and replace it with:
-- [ if PvP.IsPvP(pid) then PvP.Resurrect(pid) else Players[pid]:ProcessDeath() end ]

-- Find "function OnPlayerCellChange(pid)" inside server.lua and add:
-- [ if PvP.IsPvP(pid) then PvP.ShowMessage(pid) end ]
-- directly underneath it.


Methods.IsPvP = function(pid)
    if tes3mp.GetCell(pid) == "Vivec, Arena Pit" then return true end

    return false
end


Methods.Resurrect = function(pid)
    local respawnTime = time.seconds(10)

    local timer = tes3mp.CreateTimerEx("RespawnTimerExpired", respawnTime, "i", pid)
    local message = color.Crimson .. "You have lost consciousness." .. color.Default

    tes3mp.SendMessage(pid, message, false)
    tes3mp.StartTimer(timer)
end


Methods.ShowMessage = function(pid)
    local message = color.MediumSpringGreen .. "You have entered a PvP safezone.\n" .. color.Default
    tes3mp.SendMessage(pid, message, false)
end


function RespawnTimerExpired(pid)
    local health = (tes3mp.GetHealthBase(pid)/100)*25
    tes3mp.Resurrect(pid, 0)
    tes3mp.SetHealthCurrent(pid, health)
    tes3mp.SendStatsDynamic(pid)
end


return Methods
