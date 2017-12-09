-- TES3MP PlayerExchangeLock -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
Config.PlayerExchangeLock = import(getModuleFolder() .. "config.lua")


local statusLocal = {}
local statusRemote = {}
local timerUpdate = tes3mp.CreateTimerEx("TimerUpdateExpired", Config.PlayerExchangeLock.updateInterval, "i", 0)


function Update()
    statusLocal = {}
    statusRemote = JsonInterface.load(Config.PlayerExchangeLock.jsonRemote)

    Players.for_each(function(player)
            local playerName = string.lower(player.name)

            statusLocal[playerName] = {}
            statusLocal[playerName].online = true

            if statusRemote[playerName] ~= nil then
                if statusRemote[playerName].online == true then
                    player:kick()
                end
            end
    end)

    JsonInterface.save(Config.PlayerExchangeLock.jsonLocal, statusLocal)
    timerUpdate:start()
end


Event.register(Events.ON_POST_INIT, function()
                   timerUpdate = TimerCtrl.create(Update, Config.PlayerExchangeLock.updateInterval, { timerUpdate })
                   timerUpdate:start()
end)
