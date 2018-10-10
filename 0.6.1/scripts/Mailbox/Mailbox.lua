-- Mailbox.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


require("color")


local Methods = {}


-- Add [ Mailbox = require("Mailbox") ] to the top of server.lua

-- Find "myMod.OnPlayerConnect(pid, playerName)" inside server.lua and insert:
-- [ Mailbox.Init(pid) ]
-- [ Mailbox.CheckInbox(pid) ]
-- directly underneath it.

-- Find "elseif cmd[1] == "difficulty" and admin then" inside server.lua and insert:
-- [ elseif cmd[1] == "mbcheck" then Mailbox.CheckInbox(pid) ]
-- [ elseif cmd[1] == "mbread" then Mailbox.ReadMessage(pid, cmd[2]) ]
-- [ elseif cmd[1] == "mbsend" then Mailbox.SendMessage(pid, tableHelper.concatenateFromIndex(cmd, 2)) ]
-- [ elseif cmd[1] == "mbdelete" then Mailbox.DeleteMessage(pid, cmd[2]) ]
-- directly above it.


local mailboxPath  = "/path/to/mailbox/"
local messageLimit = 10


Methods.Init = function(pid)
    local playerName = string.lower(tes3mp.GetName(pid))
    local mbox  = mailboxPath .. playerName .. ".txt"
    local message

    local f = io.open(mbox, "r")
    if f == nil then
        f = io.open(mbox, "w+")
        f:write("Thanks for joining our server. - The staff\n")
        f:close()
        message = color.MediumSpringGreen .. "A new mailbox has been initialised.\n" .. color.Default
        tes3mp.SendMessage(pid, message, false)
    end
end


Methods.CheckInbox = function(pid)
    local playerName = string.lower(tes3mp.GetName(pid))
    local mbox  = mailboxPath .. playerName .. ".txt"
    local message = color.MediumSpringGreen .. "You have "
    local c = 0

    local f = io.open(mbox, "r")
    if f == nil then return -1 end
    for _ in io.lines(mbox) do c = c + 1 end
    f:close()

    message = message .. tostring(c) .. " message"
    if c > 1 or c == 0 then message = message .. "s" end

    message = message .. " in your Inbox.\n" .. color.Default
    tes3mp.SendMessage(pid, message, false)

    return c
end


Methods.ReadMessage = function(pid, id)
    if tonumber(id) == nil then return -1 end
    id = tonumber(id)
    if not math.floor(id) then return -1 end

    local playerName = string.lower(tes3mp.GetName(pid))
    local mbox  = mailboxPath .. playerName .. ".txt"
    local message = ""
    local line
    local c = 0
    local i = 0

    local f = io.open(mbox, "r")
    if f == nil then return -1 end
    for _ in io.lines(mbox) do c = c + 1 end
    if c < 1 then return -1 end

    -- Show all messages at once.
    if id == 0 then
        while true do
            line = f:read()
            if line == nil then break end

            if i % 2 == 0 then
                message = message .. color.PaleGreen .. line .. "\n" .. color.Default
            else
                message = message .. color.PaleTurquoise .. line .. "\n" .. color.Default
            end
            i = i + 1
        end
    end

    -- Show specific message.
    if id > c or id < 0 then
        message = message .. color.Crimson .. "Message " .. tostring(id) .. " does not exist.\n" .. color.Default
    else
        i = 0
        for line in f:lines() do
            if i == id - 1 then
                message = message .. color.PaleGreen .. line .. "\n" .. color.Default
            end
            i = i + 1
        end
    end

    f:close()
    tes3mp.SendMessage(pid, message, false)

    return 0
end


Methods.SendMessage = function(pid, args)
    local user = ""
    local text = ""
    local i = 0

    for substr in string.gmatch(args, '([^"]+)') do
        if i == 0 then user = substr end
        if i == 2 then text = substr end
        i = i + 1
    end
    user = string.lower(user)

    local playerName = string.lower(tes3mp.GetName(pid))
    local mbox = mailboxPath .. user .. ".txt"
    local message = ""
    local err = 0
    local c = 0

    local f = io.open(mbox, "r")
    if f == nil then
        message = message .. color.Crimson .. user .. " does not have a mailbox yet.\n" .. color.Default
        err = err + 1
    else
        for _ in io.lines(mbox) do c = c + 1 end
        if c >= messageLimit then
            message = message .. color.Crimson .. user .. "'s mailbox is full.\n" .. color.Default
            err = err + 1
        end
        f:close()
    end

    if err == 0 then
        if text == "" then
            message = color.Crimson .. "Message is empty.\n"
        else
            text = text .. " - " .. playerName .. "\n"
            f = io.open(mbox, "a")
            f:write(text)
            f:close()
            message = color.MediumSpringGreen .. "Message has been sent.\n"
        end
    end

    tes3mp.SendMessage(pid, message, false)

    return 0
end


Methods.DeleteMessage = function(pid, id)
    if tonumber(id) == nil then return -1 end
    id = tonumber(id)
    if not math.floor(id) then return -1 end

    local playerName = string.lower(tes3mp.GetName(pid))
    local mbox = mailboxPath .. playerName .. ".txt"
    local message = ""
    local line = {}
    local content = {}
    local c = 0
    local i = 0

    local f = io.open(mbox, "r")
    if f == nil then return 0 end
    for _ in io.lines(mbox) do c = c + 1 end

    -- Delete all messages.
    if id == 0 then
        f = io.open(mbox, "w+")
        f:close()
        message = color.MediumSpringGreen .. "All messages have been deleted.\n"
    else
        -- Delete specific message.
        if id > c or id < 0 then
            message = message .. color.Crimson .. "Message " .. tostring(id) .. " does not exist.\n" .. color.Default
        else
            f = io.open(mbox, "r")
            while true do
                line = f:read()
                if line == nil then break end
                content[i] = line .. "\n"
                i = i + 1
            end
            f:close()
            table.remove(content, id - 1)

            f = io.open(mbox, "w+")
            for i = 0, c - 2 do f:write(content[i]) end
            f:close()

            message = message .. color.MediumSpringGreen .. "Message " .. tostring(id) .. " has been deleted.\n" .. color.Default
        end
    end

    tes3mp.SendMessage(pid, message, false)

    return 0
end


return Methods
