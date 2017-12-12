-- TES3MP VirtualDrakes -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
Config.VirtualDrakes = import(getModuleFolder() .. "config.lua")
colour = import(getModuleFolder() .. "colour.lua")


local accountCheckLastVisitTimer
local accountGenerateDrakesTimer
local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")


function Init(player)
    if AccountCheckStatus(player.name) == false then
        AccountOpen(player.name)
        message = colour.Confirm .. Data._(player, locales, "newBankAccount") .. ".\n" .. colour.Default
        player:message(0, message, false)
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
    local lang = Data.LanguageGet(player)

    local f = io.open(getDataFolder() .. "help_" .. lang .. ".txt", "r")
    if f == nil then
        f = io.open(getDataFolder() .. "help_en.txt", "r")
        if f == nil then
            return false
        end
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, Data._(player, locales, "close"))
end


function AccountCheckLastVisit()
    local timeCurrent = os.time()

    for index, item in pairs(storage) do
        if storage[index].lastVisit ~= nil then
            if timeCurrent - storage[index].lastVisit >= (Config.VirtualDrakes.maxAbandonTime * 3600) then
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


function AccountGenerateDrakes()
    local timeCurrent = os.time()

    Players.for_each(function(player)
            local timeLastActivity = player.customData["lastActivity"]

            if (timeCurrent - timeLastActivity) < Config.VirtualDrakes.maxAFKTime then
                local drakesCurrent = AccountGetDrakes(player.name)
                drakesCurrent = math.ceil(drakesCurrent + Config.VirtualDrakes.drakesPerMinute)
                AccountSetDrakes(player.name, drakesCurrent)

                if player.customData["isAFK"] == true then
                    player:message(0, colour.Confirm .. Data._(player, locales, "paymentContinued") .. ".\n", false)
                    player.customData["isAFK"] = false
                end
            else
                player:message(0, colour.Warning .. Data._(player, locales, "paymentStopped") .. ".\n", false)
                player.customData["isAFK"] = true
            end
    end)

    accountGenerateDrakesTimer:start()
end


function AccountGetDrakes(playerName)
    local drakesCurrent = storage[string.lower(playerName)].drakes

    if drakesCurrent ~= nil then
        return drakesCurrent
    else
        return 0
    end
end


function AccountOpen(playerName)
    storage[string.lower(playerName)] = {}
    storage[string.lower(playerName)].drakes = 0
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function AccountSetDrakes(playerName, count)
    storage[string.lower(playerName)].drakes = count
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function AccountShow(player)
    local drakesCurrent = AccountGetDrakes(player.name)
    player:getGUI():customMessageBox(441, colour.Heading .. Data._(player, locales, "accountBalance") .. "\n\n" .. colour.Default .. drakesCurrent .. " " .. Data._(player, locales, "currencyName"),  Data._(player, locales, "close"))

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
                   accountGenerateDrakesTimer = TimerCtrl.create(AccountGenerateDrakes, 60000, { accountGenerateDrakesTimer })
                   accountCheckLastVisitTimer:start()
                   accountGenerateDrakesTimer:start()
end)


CommandController.registerCommand("vd", CommandHandler, colour.Command .. "/vd help" .. colour.Default .. " - Virtual Drakes.")


Data["VirtualDrakes"] = {}
Data.VirtualDrakes["Get"] = AccountGetDrakes
Data.VirtualDrakes["Set"] = AccountSetDrakes
