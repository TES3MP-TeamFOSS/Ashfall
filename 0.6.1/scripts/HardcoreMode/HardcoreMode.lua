-- HardcoreMode.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


require("color")

Methods = {}


-- Add [ HardcoreMode = require("HardcoreMode") ] to the top of myMod.lua
-- Find "Players[pid]:ProcessDeath()" inside myMod.lua and replace it with:
-- [ if HardcoreMode.Check(pid) then HardcoreMode.DeletePlayer(pid) else Players[pid]:ProcessDeath() end ]

-- Add [ HardcoreMode = require("HardcoreMode") ] to the top of server.lua
-- Find "elseif cmd[1] == "difficulty" and admin then" inside server.lua and insert:
-- [ elseif cmd[1] == "hardcore" then HardcoreMode.Toggle(pid) ]
-- directly above it.


Methods.DeletePlayer = function(pid)
    local message = color.Crimson .. tes3mp.GetName(pid) .. " is dead and gone for good. Press F to pay respects.\n" .. color.Default
    os.remove(os.getenv("MOD_DIR") .. "/player/" .. tes3mp.GetCaseInsensitiveFilename(os.getenv("MOD_DIR").."/player/", Players[pid].data.login.name .. ".json"))
    tes3mp.SendMessage(pid, message, true)
    Players[pid]:Kick()
end


Methods.Check = function(pid)
	return Players[pid].data.customVariables.hardcore or false
end


Methods.Toggle = function(pid)
    local message = ""

    if Players[pid].data.customVariables.hardcore then
        message = message .. color.MediumSpringGreen .. "Hardcore mode disabled.\n"
        Players[pid].data.customVariables.hardcore = false
		Players[pid]:Save()
    else
        message = message .. color.Crimson .. "Hardcore mode enabled. Be careful, death is now permanent!\n"
        Players[pid].data.customVariables.hardcore = true
		Players[pid]:Save()
    end

    tes3mp.SendMessage(pid, message, false)
end


return Methods
