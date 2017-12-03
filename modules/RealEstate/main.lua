-- TES3MP RealEstate -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


JsonInterface = require("jsonInterface")
Config.RealEstate = import(getModuleFolder() .. "config.lua")
colour = import(getModuleFolder() .. "colour.lua")


local cellMonitorLastVisitTimer
local storage = JsonInterface.load(getDataFolder() .. "storage.json")
local locales = JsonInterface.load(getDataFolder() .. "locales.json")


function CommandHandler(player, args)
    if args[1] == nil then
        CellShowPlayerCellGUI(player)
        return true
    end

    if args[1] == "add" then
        if args[2] ~= nil then
            GuestListAdd(player, args[2])
            return true
        end
    end

    if args[1] == "remove" then
        if args[2] ~= nil then
            GuestListRemove(player, args[2])
            return true
        end
    end

    if args[1] == "guests" then
        GuestListShow(player)
        return true
    end

    if args[1] == "lock" then
        CellLockPlayerCell(player)
        return true
    end

    Help(player)
    return true
end


function Help(player)
    local lang = Data.LanguageGet(player)

    local f = io.open(getDataFolder() .. "help_" .. lang .. ".txt", "r")
    if f == nil then
        f = io.open(getDataFolder() .. "help.txt", "r")

        if f == nil then
            return false
        end
    end

    local message = f:read("*a")
    f:close()

    player:getGUI():customMessageBox(-1, message, Data._(player, locales, "close"))
end


function CellCheck(player)
    local message = ""
    local sendMessage = false
    local cellCurrent = player:getCell().description
    local cellOwner = CellGetOwner(cellCurrent)
    local cells = CellGetList()
    local goldCurrencyName = GoldGetCurrencyName()
    local playerName = string.lower(player.name)

    if cells == -1 then return -1 end

    for index, cell in pairs(cells) do
        if cellCurrent == cell then
            if cellOwner ~= nil then
                if CellGetLockState(currentCell) == true and playerName ~= cellOwner then
                    message = colour.Warning .. Data._(player, locales, "houseFoundUnlocked") .. ".\n"
                    sendMessage = true

                elseif playerName ~= cellOwner and GuestListCheck(cellCurrent, playerName) == false then
                    message = colour.Caution .. Data._(player, locales, "houseOwnedBy") .. " " .. cellOwner .. ".\n"
                    if previousCell ~= cellCurrent then
                        WarpToPreviousPosition(player)
                    else
                        WaroToSeydaNeen(player)
                    end
                    sendMessage = true

                elseif playerName == cellOwner then
                    message = colour.Confirm .. Data._(player, locales, "welcomeHome") .. " " .. playerName .. ".\n"
                    sendMessage = true
                    CellUpdateLastVisit(cellCurrent)

                elseif GuestListCheck(cellCurrent, playerName) then
                    message = colour.Confirm .. Data._(player, locales, "houseOwnedBy") .. " " .. cellOwner .. ".\n" .. Data._(player, locales, "behaveYourself") .. ".\n"
                    CellUpdateLastVisit(cellCurrent)
                    sendMessage = true

                end
            else
                local housePrice = CellGetPrice(cellCurrent)
                if housePrice == -1 then
                    housePrice = Config.RealEstate.basePrice
                end

                local playerCell = CellGetPlayerCell(player)
                if playerCell == nil then
                    player:getGUI():customMessageBox(232, Data._(player, locales, "houseForSale") .. "\n(" .. housePrice .. " " .. goldCurrencyName .. ").\n", Data._(player, locales, "close") .. ";" .. Data._(player, locales, "buy"))
                else
                    player:getGUI():customMessageBox(233, Data._(player, locales, "houseForSale") .. ". " .. Data._(player, locales, "youAlreadyOwn") .. " " .. playerCell .. ".\n", Data._(player, locales, "close") .. ";" .. Data._(player, locales, "releaseAndBuy") .. " (" .. housePrice .. " " .. goldCurrencyName .. ")")
                end
            end
        end
    end

    message = message .. colour.Default
    if sendMessage == true then
        player:message(message, false)
    end

    return 0
end


function CellMonitorLastVisit()
    local timeCurrent = os.time()

    for index, item in pairs(storage) do
        if storage[index].lastVisit ~= nil then
            if timeCurrent - storage[index].lastVisit >= (Config.RealEstate.maxAbandonTime * 3600) then
                CellRelease(index)
                logMessage(Log.LOG_INFO, message)
                Players.for_each(function(player)
                        local message = index .. " " .. Data._(player, locales, "houseAbandoned") .. ".\n"
                        player:message(colour.Warning .. message)
                end)
            end
        end
    end

    cellMonitorLastVisitTimer:start()
end


function CellUpdateLastVisit(cell)
    if storage[cell] == nil then
        storage[cell] = {}
    end

    storage[cell].lastVisit = os.time()
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function CellBuy(player)
    local message = ""
    local sendMessage = false
    local cellCurrent = player:getCell().description
    local cellOwner   = CellGetOwner(cellCurrent)
    local cells = CellGetList()
    local goldCurrencyName = GoldGetCurrencyName()
    local goldAmount = GoldGetAmount(player)

    if cells == -1 then return -1 end

    for index, cell in pairs(cells) do
        if cellCurrent == cell and cellOwner == nil then

            local housePrice = CellGetPrice(cellCurrent)
            if housePrice == -1 then
                housePrice = Config.RealEstate.basePrice
            end

            if goldAmount < housePrice then
                message = colour.Caution .. Data._(player, locales, "youNeedAtLeast") .. " " .. tostring(housePrice) .. " " .. goldCurrencyName .. ".\n"
                sendMessage = true
            else
                message = colour.Confirm .. Data._(player, locales, "welcomeHome") .. " " .. player.name .. ".\n"
                CellSetOwner(cellCurrent, player)
                GoldSetAmount(player.name, (goldAmount - housePrice))

                sendMessage = true
            end
        end
    end

    message = message .. colour.Default
    if sendMessage == true then
        player:message(message, false)
    end

    return 0
end


function CellRelease(cell)
    if storage[cell] == nil then
        storage[cell] = {}
    end
    storage[cell] = {}
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function CellGetList()
    local tmp = {}
    local cells = {}

    local f = io.open(getDataFolder() ..  package.config:sub(1, 1) .. "cells.txt", "r")
    if f ~= nil then
        for line in f:lines() do
            table.insert(tmp, line)
        end
        f:close()

        for index, item in pairs(tmp) do
            for substr in string.gmatch(item, '([^:]+)') do
                table.insert(cells, substr)
                break
            end
        end

        return cells
    end

    return -1
end


function CellGetOwner(cell)
    if storage[cell] == nil then
        return nil
    end

    return storage[cell].owner
end


function CellGetPlayerCell(player)
    for index, item in pairs(storage) do
        if storage[index].owner == string.lower(player.name) then
            return index
        end
    end

    return nil
end


function CellLockPlayerCell(player)
    local message = ""
    local playerCell = CellGetPlayerCell(player)

    if playerCell == nil then
        message = colour.Caution .. Data._(player, locales, "youDontOwn") .. ".\n"
    else
        if storage[playerCell].isUnlocked == true then
            storage[playerCell].isUnlocked = false
            message = colour.Confirm .. playerCell .. " " .. Data._(player, locales, "houseLocked") .. ".\n"
        else
            storage[playerCell].isUnlocked = true
            message = colour.Warning .. playerCell .. " " .. Data._(player, locales, "houseUnlocked") .. ".\n"
        end
    end

    message = message .. colour.Default
    player:message(message, false)
end


function CellShowPlayerCellGUI(player)
    local message = colour.Heading .. Data._(player, locales, "modName") .. colour.Default
    local buttons =
        Data._(player, locales, "close") .. ";" ..
        Data._(player, locales, "add") .. ";" ..
        Data._(player, locales, "remove") .. ";" ..
        Data._(player, locales, "list") .. ";" ..
        Data._(player, locales, "lock") .. "/" ..
        Data._(player, locales, "unlock")

    player:getGUI():customMessageBox(234, message, buttons)
end


function CellGetLockState(cell)
    if storage[cell] == nil then
        return false
    end

    return storage[cell].isUnlocked
end


function CellGetPrice(cell)
    local price = 0
    local tmp = {}
    local hit = false

    local f = io.open(getDataFolder() .. "cells.txt", "r")
    if f ~= nil then
        for line in f:lines() do
            table.insert(tmp, line)
        end
        f:close()

        for index, item in pairs(tmp) do
            for substr in string.gmatch(item, '([^:]+)') do
                if hit == true then
                    price = tonumber(substr)
                    if price then return price end
                end
                if substr == cell then hit = true end
            end
            if hit == true then break end
        end
    end

    return -1
end


function CellSetOwner(cell, player)
    if storage[cell] == nil then
        storage[cell] = {}
    end

    storage[cell].owner = string.lower(player.name)
    storage[cell].isUnlocked = false
    storage[cell].lastVisit = os.time()
    JsonInterface.save(getDataFolder() .. "storage.json", storage)
end


function GoldGetCurrencyName()
    if Config.RealEstate.useVirtualDrakes == true then
        return Config.RealEstate.nameCurrencyRegular
    else
        return Config.RealEstate.nameCurrencyVirtual
    end
end


function GoldGetAmount(player)
    if Config.RealEstate.useVirtualDrakes == true then
        return Data.VirtualDrakes.Get(player.name)
    end

    -- Todo: else return gold amount from inventory
    return 1000000
end


function GoldSetAmount(player, gold)
    if Config.RealEstate.useVirtualDrakes == true then
        Data.VirtualDrakes.Set(player, gold)
    else
        -- Todo: set gold in inventory
    end
end


function GuestListGetList(cell)
    if storage[cell].guestList == nil then
        storage[cell].guestList = {}
    end

    return storage[cell].guestList
end


function GuestListCheck(cell, guestName)
    local guestList = GuestListGetList(cell)

    if guestList[1] == nil then
        return false
    end

    for index, item in pairs(guestList) do
        if item == guestName then
            return true
        end
    end

    return false
end


function GuestListAdd(player, guestName)
    local guestName = string.lower(guestName)
    local message = ""
    local playerCell = CellGetPlayerCell(player)

    if playerCell == nil then
        message = colour.Caution .. Data._(player, locales, "youDontOwn") .. ".\n"
    else
        if GuestListCheck(playerCell, guestName) then
            message = colour.Warning .. guestName .. " " .. Data._(player, locales, "alreadyOnList") .. ".\n"
        else
            if storage[playerCell].guestList == nil then
                storage[playerCell].guestList = {}
            end

            table.insert(storage[playerCell].guestList, guestName)
            message = colour.Confirm .. guestName .. " " .. Data._(player, locales, "newGuest") .. ".\n"
            JsonInterface.save(getDataFolder() .. "storage.json", storage)
        end
    end

    message = message .. colour.Default
    player:message(message, false)
    return true
end


function GuestListRemove(player, guestName)
    local message = ""
    local playerCell = CellGetPlayerCell(player)

    guestName = string.lower(guestName)

    if playerCell == nil then
        message = colour.Caution .. Data._(player, locales, "youDontOwn") .. ".\n"
    else
        if GuestListCheck(playerCell, guestName) then
            for index, item in pairs(storage[playerCell].guestList) do
                if item == string.lower(guestName) then
                    table.remove(storage[playerCell].guestList, index)
                end
            end
            message = colour.Confirm .. guestName .. " " .. Data._(player, locales, "noLongerWelcome") .. ".\n"
            JsonInterface.save(getDataFolder() .. "storage.json", storage)
        else
            message = colour.Warning .. guestName .. " " .. Data._(player, locales, "notYourGuest") .. ".\n"
        end
    end

    message = message .. colour.Default
    player:message(message, false)
    return true
end


function GuestListShow(player)
    local message = ""
    local sendMessage = false
    local playerCell = CellGetPlayerCell(player)

    if playerCell == nil then
        message = colour.Caution .. Data._(player, locales, "youDontOwn") .. ".\n"
        sendMessage = true
    else
        local guestList = GuestListGetList(playerCell)

        if guestList[1] == nil then
            message = colour.Caution .. Data._(player, locales, "guestListEmpty") .. ".\n"
            sendMessage = true
        else
            message = message .. colour.Warning .. Data._(player, locales, "guestsOf") .. " " ..  playerCell .. "\n\n"
            for index, item in pairs(guestList) do
                message = message .. item .. "\n"
            end
            player:getGUI():customMessageBox(234, message, Data._(player, locales, "close"))
        end
    end

    message = message .. colour.Default
    if sendMessage == true then
        player:message(message, false)
    end

    return true
end


function WarpHome(player)
    if player:getInventory():hasItemEquipped(string.lower(Config.RealEstate.portkeyRefId)) and Config.RealEstate.portkey == true then
        local message = ""
        local sendMessage = false
        local playerCell = CellGetPlayerCell(player)

        if playerCell == nil then
            message = colour.Caution .. Data._(player, locales, "youDontOwn") .. ".\n" .. colour.Default
            sendMessage = true
        else
            player:getInventory():unequipItem(Config.RealEstate.portkeySlot)
            player:getCell().description = playerCell
        end

        if sendMessage == true then
            player:message(message, false)
        end
    end
end


function WarpToPreviousPosition(player)
    player:getCell().description = player.customData.cellPrevious
    --local posx = tes3mp.GetPreviousCellPosX(pid)
    --local posy = tes3mp.GetPreviousCellPosY(pid)
    --local posz = tes3mp.GetPreviousCellPosZ(pid)
end


-- https://i.imgur.com/FCGYYqH.jpg
-- It's a meme, not a typo.
function WaroToSeydaNeen(player)
    player:getCell().description = "-2, -9"
end


Event.register(Events.ON_GUI_ACTION, function(player, id, data)
                   if id == 232 then
                       if tonumber(data) == 1 then
                           CellBuy(player)
                       end
                   elseif id == 233 then
                       if tonumber(data) == 1 then
                           local cell = CellGetPlayerCell(player)
                           CellRelease(cell)
                           CellBuy(player)
                       end
                   elseif id == 234 then
                       if tonumber(data) == 1 then
                           player:getGUI():inputDialog(235, Data._(player, locales, "add"))
                       elseif tonumber(data) == 2 then
                           player:getGUI():inputDialog(236, Data._(player, locales, "remove"))
                       elseif tonumber(data) == 3 then
                           GuestListShow(player)
                       elseif tonumber(data) == 4 then
                           CellLockPlayerCell(player)
                       end
                   elseif id == 235 then
                       GuestListAdd(player, data)
                   elseif id == 236 then
                       GuestListRemove(player, data)
                   end
end)


Event.register(Events.ON_PLAYER_CELLCHANGE, function(player)
                   -- Dirty hack to determine previous cell.
                   -- Todo:
                   --   GetPreviousCellPosX
                   --   GetPreviousCellPosY
                   --   GetPreviousCellPosZ
                   if player:getCell():isExterior() == true then
                       player.customData["cellPrevious"] = player:getCell().description
                   end
                   --
                   CellCheck(player)
end)


Event.register(Events.ON_PLAYER_EQUIPMENT, function(player)
                   WarpHome(player)
end)


Event.register(Events.ON_POST_INIT, function()
                   cellMonitorLastVisitTimer = TimerCtrl.create(CellMonitorLastVisit, 300000, { cellMonitorLastVisitTimer })
                   cellMonitorLastVisitTimer:start()

                   if Config.RealEstate.useVirtualDrakes == true then
                       local hit = false

                       for index, mod in pairs(Data.Core.loadedModules) do
                           if mod == "VirtualDrakes" then
                               hit = true
                           end
                       end

                       if hit == false then
                           logAppend(Log.LOG_ERROR, "useVirtualDrakes enabled but mod not installed.\n")
                           stopServer(-1)
                       end
                   end
end)


CommandController.registerCommand("house", CommandHandler, colour.Command .. "/house help" .. colour.Default .. " - Real estate system.")
