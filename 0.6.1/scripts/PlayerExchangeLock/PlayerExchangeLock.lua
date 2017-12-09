-- PlayerExchangeLock.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


json = require("dkjson")


Methods = {}


-- Add [ PlayerExchangeLock = require("PlayerExchangeLock") ] to the top of server.lua

-- This script is considered experimental. Please use it only if you
-- understand it's purpose.


local statusLocal = {}
local statusRemote = {}
local jsonLocal = "/path/to/local.json"
local jsonRemote = "/path/to/remote.json"
local timerUpdate = tes3mp.CreateTimerEx("TimerUpdateExpired", 500, "i", 0)


tes3mp.StartTimer(timerUpdate)


function JsonLoad(fileName)
    local file = assert(io.open(fileName, 'r'), 'Error loading file: ' .. fileName);
    local content = file:read("*all");
    file:close();
    return json.decode(content, 1, nil);
end


function JsonSave(fileName, data, keyOrderArray)
    local content = json.encode(data, { indent = true, keyorder = keyOrderArray })
    local file = assert(io.open(fileName, 'w+b'), 'Error loading file: ' .. fileName)
    file:write(content)
    file:close()
end


function Update()
    statusLocal = {}
    statusRemote = JsonLoad(jsonRemote)

    for pid, player in pairs(Players) do
        local playerName = Players[pid].name

        if player:IsLoggedIn() then
            statusLocal[playerName] = {}
            statusLocal[playerName].online = true
        end

        if statusRemote[playerName] ~= nil then
            if statusRemote[playerName].online == true then
                Players[pid]:Kick()
            end
        end
    end
    JsonSave(jsonLocal, statusLocal)

    tes3mp.StartTimer(timerUpdate)
end


function TimerUpdateExpired()
    Update()
end


return Methods
