-- TES3MP VirtualSeptims -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
Config.VirtualSeptims = import(getModuleFolder() .. "config.lua")
colour = import(getModuleFolder() .. "colour.lua")


local accountCheckLastVisitTimer
local accountGenerateSeptimsTimer
local storage = JsonInterface.load(getDataFolder() .. "storage.json")


function Init(player)
    if AccountCheckStatus(player.name) == false then
        AccountOpen(player.name)
        message = colour.Confirm .. "A new bank account has been opened.\n" .. colour.Default
        player:message(message, false)
    end

    AccountUpdateLastVisit(player.name)
end


function CommandHandler(player, args)
    if args[1] == "show" then
        AccountShow(player)
        return true
    end

    Help(player)
    return true
end


function Help(player)
    local f = io.open(getDataFolder() .. "help.txt", "r")
    if f == nil then
        return false
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(231, message, "Close")
end


function AccountCheckLastVisit()
    local timeCurrent = os.time()

    for index, item in pairs(storage) do
        if storage[index].lastVisit ~= nil then
            if timeCurrent - storage[index].lastVisit >= (Config.VirtualSeptims.maxAbandonTime * 3600) then
                AccountClose(index)
                local message = index .. "'s bank account has been closed.\n"
                logMessage(Log.LOG_INFO, message)
            end
        end
    end

    accountCheckLastVisitTimer:start()
end


function AccountCheckStatus(playerName)
    if storage[string.lower(playerName)] == nil then
        return false
    else
        return true
    end
end


function AccountClose(playerName)
    storage[string.lower(playerName)] = {}
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function AccountGenerateSeptims()
    local timeCurrent = os.time()

    Players.for_each(function(player)
            local timeLastActivity = player.customData["lastActivity"]

            if (timeCurrent - timeLastActivity) < Config.VirtualSeptims.maxAFKTime then
                local septimsCurrent = AccountGetSeptims(player.name)
                septimsCurrent = math.ceil(septimsCurrent + Config.VirtualSeptims.septimsPerMinute)
                AccountSetSeptims(player.name, septimsCurrent)

                if player.customData["isAFK"] == true then
                    player:message(colour.Confirm .. "The interest payment will be continued.\n", false)
                    player.customData["isAFK"] = false
                end
            else
                player:message(colour.Warning .. "The payment of interest has stopped due to inactivity.\n", false)
                player.customData["isAFK"] = true
            end
    end)

    accountGenerateSeptimsTimer:start()
end


function AccountGetSeptims(playerName)
    local septimsCurrent = storage[string.lower(playerName)].septims

    if septimsCurrent ~= nil then
        return septimsCurrent
    else
        return 0
    end
end


function AccountOpen(playerName)
    storage[string.lower(playerName)] = {}
    storage[string.lower(playerName)].septims = 0
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function AccountSetSeptims(playerName, count)
    storage[string.lower(playerName)].septims = count
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function AccountShow(player)
    local septimsCurrent = AccountGetSeptims(player.name)
    player:getGUI():customMessageBox(441, colour.Heading .. "BANK ACCOUNT\n\n" .. colour.Default .. septimsCurrent .. " Septims", "OK")

    return true
end


function AccountUpdateLastVisit(playerName)
    storage[string.lower(playerName)].lastVisit = os.time()
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   Init(player)
                   player.customData["lastActivity"] = os.time()
                   player.customData["isAFK"] = false
                   return true
end)


Event.register(Events.ON_PLAYER_CELLCHANGE, function(player)
                   player.customData["lastActivity"] = os.time()
end)


Event.register(Events.ON_PLAYER_INVENTORY, function(player)
                   player.customData["lastActivity"] = os.time()
end)


Event.register(Events.ON_PLAYER_KILLCOUNT, function(player)
                   player.customData["lastActivity"] = os.time()
end)


Event.register(Events.ON_PLAYER_SENDMESSAGE, function(player)
                   player.customData["lastActivity"] = os.time()
end)


Event.register(Events.ON_POST_INIT, function()
                   accountCheckLastVisitTimer = TimerCtrl.create(AccountCheckLastVisit, 300000, { accountCheckLastVisitTimer })
                   accountGenerateSeptimsTimer = TimerCtrl.create(AccountGenerateSeptims, 60000, { accountGenerateSeptimsTimer })
                   accountCheckLastVisitTimer:start()
                   accountGenerateSeptimsTimer:start()
end)


CommandController.registerCommand("bank", CommandHandler, colour.Command .. "/bank help" .. colour.Default .. " - Banking system.")


Data["VirtualSeptims"] = {}
Data.VirtualSeptims["Get"] = AccountGetSeptims
Data.VirtualSeptims["Set"] = AccountSetSeptims
