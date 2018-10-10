-- IrcBridge.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


require("color")
require("irc")


local Methods = {}


-- Add [ IrcBridge = require("IrcBridge") ] to the top of server.lua

-- Find
-- "return true -- default behavior, chat messages should not"
-- inside server.lua and insert:
-- [ IrcBridge.SendMessage(myMod.GetChatName(pid) .. ": " .. message) ]
-- directly above it.

-- Find "function UpdateTime()" inside server.lua and insert
-- [ IrcBridge.RecvMessage() ]
-- directly underneath it.


local nick       = "DagothUr"
local server     = "irc.freenode.net"
local nspasswd   = "pleasedonttellanyone"
local channel    = "#tes3mp"
local nickfilter = "Discord_Bridge"


local s = irc.new { nick = nick }
s:connect(server)
nspasswd = "identify " .. nspasswd
s:sendChat("NickServ", nspasswd)
s:join(channel)
local lastMessage = ""


Methods.RecvMessage = function()
    local message

    s:think()
    s:hook("OnChat", function(user, channel, message)
               if lastMessage ~= message and tableHelper.getCount(Players) > 0 then
                   for pid, player in pairs(Players) do
                       if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
                           user.nick = string.gsub(user.nick, nickfilter, "")
                           tes3mp.SendMessage(pid, color.GreenYellow .. user.nick .. color.Default .. ": " .. message .. "\n", true)
                           lastMessage = message
                           break
                       end
                   end
               end
    end)
end


Methods.SendMessage = function(message)
    s:sendChat(channel, message)
    s:think()
end


Methods.KeepAlive = function()
    s:think()
end


return Methods
