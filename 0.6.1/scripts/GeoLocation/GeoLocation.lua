-- GeoLocation -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


json = require("dkjson")
http = require("socket.http")
ltn12 = require("ltn12")


Methods = {}


-- Add [ GeoLocation = require("GeoLocation") ] to the top of server.lua

-- Find "myMod.OnPlayerConnect(pid, playerName)" inside server.lua and insert:
-- [ GeoLocation.Update(pid) ]
-- directly underneath it.


local geoLocation = {}
local pathJson = "/path/"
local intervalCleanup = 1
local timerCleanup = tes3mp.CreateTimerEx("Cleanup", time.seconds(intervalCleanup), "i", 0)


tes3mp.StartTimer(timerCleanup)


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


function Methods.Update(pid)
    geoLocation[pid] = {}
    local resp = {}
    local url = "http://freegeoip.net/csv/" .. tes3mp.GetIP(pid)

    http.request{
        url = url,
        sink = ltn12.sink.table(resp)
    }

    local index = 0
    for substr in string.gmatch(resp[1], '([^,]+)') do
        if index == 1 then geoLocation[pid].countryCode = substr end
        if index == 2 then geoLocation[pid].countryName = substr end
        if index == 5 then oLocation[pid].city = substr end
        if index > 5 then break end

        index = index + 1
    end

    geoLocation[pid].name = Players[pid].data.login.name
    JsonSave(pathJson .. "GeoLocation.json", geoLocation)
end


function Cleanup()
    for pid, player in pairs(Players) do
        if player:IsLoggedIn() == false then
            geoLocation[pid] = {}
        end
    end

    JsonSave(pathJson .. "GeoLocation.json", geoLocation)
    tes3mp.StartTimer(timerCleanup)
end


return Methods
