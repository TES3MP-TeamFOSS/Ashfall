-- GeoLocation -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer
local http = require("socket.http")
local ltn12 = require("ltn12")

local GeoLocation = {}

local geoLoc = {}
local intervalCleanup = 30
local timerCleanup = tes3mp.CreateTimerEx("Cleanup", time.seconds(intervalCleanup), "i", 0)

tes3mp.StartTimer(timerCleanup)

-- TODO: this is unused.  Michael: what's this for?
-- local function Cleanup()
--     for pid, player in pairs(Players) do
--         if player:IsLoggedIn() == false then
--             geoLoc[pid] = {}
--         end
--     end

--     jsonInterface.save("GeoLocation.json", geoLoc)
--     tes3mp.StartTimer(timerCleanup)
-- end

function GeoLocation.Update(pid)
    geoLoc[pid] = {}
    local resp = {}
    local url = "http://freegeoip.net/csv/" .. tes3mp.GetIP(pid)

    http.request{
        url = url,
        sink = ltn12.sink.table(resp)
    }

    local index = 0
    for substr in string.gmatch(resp[1], '([^,]+)') do
        if index == 1 then geoLoc[pid].countryCode = substr end
        if index == 2 then geoLoc[pid].countryName = substr end
        if index == 5 then geoLoc[pid].city = substr end
        if index > 5 then break end

        index = index + 1
    end

    jsonInterface.save("GeoLocation.json", geoLoc)
end

customEventHooks.registerHandler("OnPlayerConnect", GeoLocation.Update)
