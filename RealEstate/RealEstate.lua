-- RealEstate.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer
local RealEstate = {}
-- TODO: Read the path from a config file.

local cellsTextFile = tes3mp.GetModDir() .. "/custom/RealEstate/cells.txt"
local helpTextFile = tes3mp.GetModDir() .. "/custom/RealEstate/help.txt"
local jsonFileName = "custom/RealEstate/RealEstateOwned.json"
local basePrice = 500000

local maxAbandonTime = 336
-- local portkey = true
-- local portkeySlot = 16
-- local portkeyRefId = "iron fork"

local cellMonitorLastVisitTimer = tes3mp.CreateTimerEx("RealEstateCellMonitorLastVisit", 300000, "i", 0)

tes3mp.StartTimer(cellMonitorLastVisitTimer)

local storage = jsonInterface.load(jsonFileName)

local function Help(pid)
    local f = io.open(helpTextFile, "r")
    if f == nil then
        return false
    end

    local message = f:read("*a")
    f:close()

    tes3mp.CustomMessageBox(pid, -1, message, "Close")
end

local function CellRelease(cell)
    if storage[cell] == nil then
        storage[cell] = {}
    end
    storage[cell] = {}
    jsonInterface.save(jsonFileName, storage)
end

-- Ignore the linter complaint about the below function [W111]
function RealEstateCellMonitorLastVisit()
    local timeCurrent = os.time()

    for index, _ in pairs(storage) do
        if storage[index].lastVisit ~= nil then
            if timeCurrent - storage[index].lastVisit >= (maxAbandonTime * 3600) then
                CellRelease(index)
                local message = index .. " has been abandoned.\n"
                tes3mp.LogMessage(1, message)
                for pid, _ in pairs(Players) do
                    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
                        tes3mp.SendMessage(pid, "#FF8C00" .. message, false)
                    end
                end
            end
        end
    end

    tes3mp.StartTimer(cellMonitorLastVisitTimer)
end

local function CellUpdateLastVisit(cell)
    if storage[cell] == nil then
        storage[cell] = {}
    end

    storage[cell].lastVisit = os.time()
    jsonInterface.save(jsonFileName, storage)
end

local function CellGetPlayerCell(pid)
    for index, _ in pairs(storage) do
        if storage[index].owner == string.lower(tes3mp.GetName(pid)) then
            return index
        end
    end

    return nil
end

local function CellLockPlayerCell(pid)
    local message
    local playerCell = CellGetPlayerCell(pid)

    if playerCell == nil then
        message = "#DC143CYou do not own a house yet.\n"
    else
        if storage[playerCell].isUnlocked == true then
            storage[playerCell].isUnlocked = false
            message = "#00FA9A" .. playerCell .. " has been locked.\n"
        else
            storage[playerCell].isUnlocked = true
            message = "#FF8C00" .. playerCell .. " has been unlocked. Be careful.\n"
        end
    end

    message = message .. "#FFFFFF"
    tes3mp.SendMessage(pid, message, false)
end

local function CellGetLockState(cell)
    if storage[cell] == nil then
        return false
    end

    return storage[cell].isUnlocked
end

local function CellGetPrice(cell)
    local price
    local tmp = {}
    local hit = false

    local f = io.open(cellsTextFile, "r")
    if f ~= nil then
        for line in f:lines() do
            table.insert(tmp, line)
        end
        f:close()

        for _, item in pairs(tmp) do
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

local function CellSetOwner(cell, pid)
    if storage[cell] == nil then
        storage[cell] = {}
    end

    storage[cell].owner = string.lower(tes3mp.GetName(pid))
    storage[cell].isUnlocked = false
    storage[cell].lastVisit = os.time()
    jsonInterface.save(jsonFileName, storage)
end

local function GoldGetAmount(pid)
    local goldIndex

    if tableHelper.containsKeyValue(Players[pid].data.inventory, "refId", "gold_001", true) then
        goldIndex = tableHelper.getIndexByNestedKeyValue(Players[pid].data.inventory, "refId", "gold_001")

        return Players[pid].data.inventory[goldIndex].count
    end

    return 0
end

local function GoldSetAmount(pid, gold)
    local goldIndex

    if tableHelper.containsKeyValue(Players[pid].data.inventory, "refId", "gold_001", true) then
        goldIndex = tableHelper.getIndexByNestedKeyValue(Players[pid].data.inventory, "refId", "gold_001")

        Players[pid].data.inventory[goldIndex].count = gold
        Players[pid]:Save()
        Players[pid]:LoadInventory()
        Players[pid]:LoadEquipment()
    end
end

local function GuestListGetList(cell)
    if storage[cell].guestList == nil then
        storage[cell].guestList = {}
    end

    return storage[cell].guestList
end


local function GuestListCheck(cell, guestName)
    local guestList = GuestListGetList(cell)

    if guestList[1] == nil then
        return false
    end

    for _, item in pairs(guestList) do
        if item == guestName then
            return true
        end
    end

    return false
end

local function GuestListAdd(pid, _guestName)
    local guestName = string.lower(_guestName)
    local message
    local playerCell = CellGetPlayerCell(pid)

    if playerCell == nil then
        message = "#DC143CYou do not own a house yet.\n"
    else
        if GuestListCheck(playerCell, guestName) then
            message = "#FF8C00" .. guestName .. " is already on your guest list.\n"
        else
            if storage[playerCell].guestList == nil then
                storage[playerCell].guestList = {}
            end

            table.insert(storage[playerCell].guestList, guestName)
            message = "#00FA9A" .. guestName .. " is now considered a guest.\n"
            jsonInterface.save(jsonFileName, storage)
        end
    end

    message = message .. "#FFFFFF"
    tes3mp.SendMessage(pid, message, false)
    return true
end

local function GuestListRemove(pid, guestName)
    local message
    local playerCell = CellGetPlayerCell(pid)

    guestName = string.lower(guestName)

    if playerCell == nil then
        message = "#DC143CYou do not own a house yet.\n"
    else
        if GuestListCheck(playerCell, guestName) then
            for index, item in pairs(storage[playerCell].guestList) do
                if item == string.lower(guestName) then
                    table.remove(storage[playerCell].guestList, index)
                end
            end
            message = "#00FA9A" .. guestName .. " is no longer welcome in your house.\n"
            jsonInterface.save(jsonFileName, storage)
        else
            message = "#FF8C00" .. guestName .. " is not on your guest list.\n"
        end
    end

    message = message .. "#FFFFFF"
    tes3mp.SendMessage(pid, message, false)
    return true
end


local function GuestListShow(pid)
    local message = ""
    local sendMessage = false
    local playerCell = CellGetPlayerCell(pid)

    if playerCell == nil then
        message = "#DC143CYou do not own a house yet.\n"
        sendMessage = true
    else
        local guestList = GuestListGetList(playerCell)

        if guestList[1] == nil then
            message = "#DC143CYour guest list is empty.\n"
            sendMessage = true
        else
            message = message .. "#FF8C00Guests of " ..  playerCell .. "\n\n"
            for _, item in pairs(guestList) do
                message = message .. item .. "\n"
            end
            tes3mp.CustomMessageBox(pid, -1, message, "Close")
        end
    end

    message = message .. "#FFFFFF"
    if sendMessage == true then
        tes3mp.SendMessage(pid, message, false)
    end

    return true
end

local function CellGetList()
    local tmp = {}
    local cells = {}

    local f = io.open(cellsTextFile, "r")
    if f ~= nil then
        for line in f:lines() do
            table.insert(tmp, line)
        end
        f:close()

        for _, item in pairs(tmp) do
            for substr in string.gmatch(item, '([^:]+)') do
                table.insert(cells, substr)
                break
            end
        end

        return cells
    end

    return -1
end

local function CellGetOwner(cell)
    if storage[cell] == nil then
        return nil
    end

    return storage[cell].owner
end

local function CellBuy(pid)
    local message = ""
    local sendMessage = false
    local cellCurrent = tes3mp.GetCell(pid)
    local cellOwner   = CellGetOwner(cellCurrent)
    local cells = CellGetList()
    local goldAmount = GoldGetAmount(pid)

    if cells == -1 then return -1 end

    for _, cell in pairs(cells) do
        if cellCurrent == cell and cellOwner == nil then

            local housePrice = CellGetPrice(cellCurrent)
            if housePrice == -1 then
                housePrice = basePrice
            end

            if goldAmount < housePrice then
                message = "#DC143CYou need at least " .. tostring(housePrice) .. " Drakes.\n"
                sendMessage = true
            else
                local playerCell = CellGetPlayerCell(pid)
                if playerCell ~= nil then
                    CellRelease(playerCell)
                end

                message = "#00FA9AWelcome home, " .. tes3mp.GetName(pid) .. ".\n"
                CellSetOwner(cellCurrent, pid)
                GoldSetAmount(pid, (goldAmount - housePrice))

                sendMessage = true
            end
        end
    end

    message = message .. "#FFFFFF"
    if sendMessage == true then
        tes3mp.SendMessage(pid, message, false)
    end

    return 0
end

-- https://i.imgur.com/FCGYYqH.jpg
-- It's a meme, not a typo.
local function WaroToSeydaNeen(pid)
    tes3mp.SetCell(pid, "-2, -9")
    tes3mp.SendCell(pid)
end

local function WarpToPreviousPosition(pid)
    local posx = tes3mp.GetPreviousCellPosX(pid)
    local posy = tes3mp.GetPreviousCellPosY(pid)
    local posz = tes3mp.GetPreviousCellPosZ(pid)

    tes3mp.SetCell(pid, "")
    tes3mp.SetPos(pid, posx, posy, posz)
    tes3mp.SendCell(pid)
    tes3mp.SendPos(pid)
end

function RealEstate.CommandHandler(pid, args)
    local command
    local parameter

    local i = 0
    for _, arg in pairs(args) do
       if i == 0 then command = arg end
       if i == 1 then parameter = arg end
    end

    if command == "buy" then
        CellBuy(pid)
        return true
    end

    if command == "add" then
        if parameter == nil then
            print("nil?")
            Help(pid)
            return false
        end
        GuestListAdd(pid, parameter)
        return true
    end

    if command == "remove" then
        if parameter == nil then
            Help(pid)
            return false
        end
        GuestListRemove(pid, parameter)
        return true
    end

    if command == "guests" then
        GuestListShow(pid)
        return true
    end

    if command == "lock" then
        CellLockPlayerCell(pid)
        return true
    end

    Help(pid)
    return true
end

function RealEstate.CellCheck(eventStatus, pid)
    local message = ""
    local sendMessage = false
    local cellCurrent = tes3mp.GetCell(pid)
    local cellOwner = CellGetOwner(cellCurrent)
    local cellPrevious = Players[pid].data.location.cell
    local cells = CellGetList()
    local playerName = string.lower(tes3mp.GetName(pid))

    if cells == -1 then return -1 end

    for _, cell in pairs(cells) do
        if cellCurrent == cell then
            if cellOwner ~= nil then
                if CellGetLockState(cellCurrent) == true and playerName ~= cellOwner then
                    message = "#FF8C00You found this house unlocked.\n"
                    sendMessage = true

                elseif playerName ~= cellOwner and GuestListCheck(cellCurrent, playerName) == false and Players[pid]:IsAdmin() == false then
                    message = "#DC143CThis house is owned by " .. cellOwner .. ".\n"
                    if cellPrevious ~= cellCurrent then
                        WarpToPreviousPosition(pid)
                    else
                        WaroToSeydaNeen(pid)
                    end
                    sendMessage = true

                elseif playerName == cellOwner then
                    message = "#00FA9AWelcome home, " .. tes3mp.GetName(pid) .. ".\n"
                    sendMessage = true
                    CellUpdateLastVisit(cellCurrent)

                elseif GuestListCheck(cellCurrent, playerName) then
                    message = "#00FA9AThis house is owned by " .. cellOwner .. ".\nBehave yourself accordingly.\n"
                    CellUpdateLastVisit(cellCurrent)
                    sendMessage = true

                end
            else
                local housePrice = CellGetPrice(cellCurrent)
                if housePrice == -1 then
                    housePrice = basePrice
                end

                local playerCell = CellGetPlayerCell(pid)
                message = "#FF8C00"
                if playerCell == nil then
                    message = message .. "This house is for sale. You can buy it for " .. housePrice .. " Drakes. Enter #FA8072/house buy #FF8C00to buy.\n"
                else
                    message = message .. "This house is for sale, but you already own " .. playerCell .. ". Enter #FA8072/house buy #FF8C00to release & buy (" .. housePrice .. ").\n"
                end
                sendMessage = true

            end
        end
    end

    message = message .. "#FFFFFF"
    if sendMessage == true then
        tes3mp.SendMessage(pid, message, false)
    end
end

-- TODO:
-- Optional:
-- Find "OnPlayerEquipment(pid)" inside server.lua and insert:
-- [ RealEstate.WarpHome(pid) ]
-- directly underneath it.
-- function RealEstate.WarpHome(pid)
--     if tes3mp.HasItemEquipped(pid, portkeyRefId) and portkey == true then
--         local message     = ""
--         local sendMessage = false
--         -- local playerName  = string.lower(tes3mp.GetName(pid))
--         local playerCell = CellGetPlayerCell(pid)

--         if playerCell == nil then
--             message = "#DC143CYou do not own a house yet.#FFFFFF\n"
--             sendMessage = true
--         else
--             tes3mp.UnequipItem(pid, portkeySlot)
--             tes3mp.SendEquipment(pid)
--             tes3mp.SetCell(pid, playerCell)
--             tes3mp.SendCell(pid)
--         end

--         if sendMessage == true then
--             tes3mp.SendMessage(pid, message, false)
--         end
--     end
-- end

customCommandHooks.registerCommand("house", RealEstate.CommandHandler)
customEventHooks.registerHandler("OnPlayerCellChange", RealEstate.CellCheck)
