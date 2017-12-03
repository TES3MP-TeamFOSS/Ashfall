-- TES3MP IrcBridge -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


require("irc")
Config.IrcBridge = import(getModuleFolder() .. "config.lua")
colour = import(getModuleFolder() .. "colour.lua")


local timer
local lastMessage = ""
local s = irc.new { nick = Config.IrcBridge.nick }

s:connect(Config.IrcBridge.server)
s:sendChat("NickServ", "identify " .. Config.IrcBridge.nickservPassword)
s:join(Config.IrcBridge.channel)


function RecvMessage()
    s:think()
    s:hook("OnChat", function(user, channel, message)
               if lastMessage ~= message then
                   user.nick = string.gsub(user.nick, Config.IrcBridge.nickFilter, "")
                   Players.for_each(function(player)
                           player:message(colour.Neutral .. user.nick .. colour.Default .. ": " .. message .. "\n", false)
                   end)
                   lastMessage = message
               end
    end)
    timer:start()
end


function SendMessage(message)
    s:sendChat(Config.IrcBridge.channel, message)
    s:think()
end


Event.register(Events.ON_PLAYER_CONNECT, function(player)
                   if Config.IrcBridge.notifyConnect == true then
                       local message = player.name .. " joined the server\n"
                       SendMessage(message)
                   end

                   return true
end)


Event.register(Events.ON_PLAYER_CELLCHANGE, function(player)
                   if Config.IrcBridge.notifyCellChange == true and player:getCell():isExterior() == false then
                       local message = player.name .. " entered " .. player:getCell().description .. "\n"
                       SendMessage(message)
                   end
end)


Event.register(Events.ON_PLAYER_DEATH, function(player, deathReason)
                   if Config.IrcBridge.notifyDeath == true then
                       local reason = ": "
                       if deathReason == "suicide" then
                           reason = " commited suicide"
                       end

                       local message = player.name .. reason .. "\n"
                       SendMessage(message)
                   end
end)


Event.register(Events.ON_PLAYER_DISCONNECT, function(player)
                   if Config.IrcBridge.notifyDisconnect == true then
                       local message = player.name .. " left the server\n"
                       SendMessage(message)
                   end
end)


Event.register(Events.ON_PLAYER_LEVEL, function(player)
                   if player.level > 1 and Config.IrcBridge.notifyLevel == true then
                       local message = player.name .. " reached level " .. player.level .. "\n"
                       SendMessage(message)
                   end
end)


Event.register(Events.ON_POST_INIT, function()
                   timer = TimerCtrl.create(RecvMessage, 1000, { timer })
                   timer:start()
end)


Event.register(Events.ON_PLAYER_SENDMESSAGE, function(player, message)
                   SendMessage(string.sub(message, 8))
end)
