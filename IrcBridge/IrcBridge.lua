-- -*- lua -*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer
local irc = require("irc")
local time = require("time")

local IrcBridge = {}

local nick       = "TES3MPLoveBot"
local server     = "irc.freenode.net"
local nspasswd   = "PleaseNoCorprus"
local channel    = "#tes3mp"
local nickfilter = ""
local updateInt  = 1

-- Optionally use DataManager
if DataManager ~= nil then
   IrcBridge.defaultConfig = {
      nick = nick,
      server = server,
      nspasswd = nspasswd,
      channel = channel,
      nickfilter = nickfilter,
      updateInt = updateInt
   }

   IrcBridge.config = DataManager.loadConfiguration("IrcBridge", IrcBridge.defaultConfig)

   nick = IrcBridge.config.nick
   server = IrcBridge.config.server
   nspasswd = IrcBridge.config.nspasswd
   channel = IrcBridge.config.channel
   nickfilter = IrcBridge.config.nickfilter
   updateInt = IrcBridge.config.updateInt
end

IrcBridge.client = irc.new { nick = nick }
local lastMessage = ""
local timerIrcBridgeUpdate = tes3mp.CreateTimerEx("TimerIrcBridgeUpdateExpired",
                                                time.seconds(updateInt), "i", 0)

function IrcBridge.ConnectBot()
   IrcBridge.client:connect(server)
   nspasswd = "identify " .. nspasswd
   IrcBridge.client:sendChat("NickServ", nspasswd)
   IrcBridge.client:join(channel)
end

local function aPlayerIsLoggedIn()
   for pid, _ in pairs(Players) do
      if Players[pid]:IsLoggedIn() then
         return true
      end
   end
   return false
end

local function sendMessage(message)
    IrcBridge.client:sendChat(channel, message)
    IrcBridge.client:think()
end

local function stringStarts(String, Start)
   return string.sub(String, 1, string.len(Start)) == Start
end

local function chatHook(user, _channel, message)
   if lastMessage ~= message and tableHelper.getCount(Players) > 0 then
      for pid, _ in pairs(Players) do
         if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            user.nick = string.gsub(user.nick, nickfilter, "")
            tes3mp.SendMessage(pid, color.GreenYellow .. user.nick ..
                                  color.Default .. ": " .. message .. "\n", true)
            lastMessage = message
            break
         end
      end
   end
end

function IrcBridge.KeepAlive()
    IrcBridge.client:think()
end

function IrcBridge.OnPlayerAuthentified(eventStatus, pid)
   sendMessage(logicHandler.GetChatName(pid) .. " joined the server.")
end

function IrcBridge.OnPlayerDeath(eventStatus, pid)
   -- TODO: announce the actual death reason
   sendMessage(logicHandler.GetChatName(pid) .. " has died.\n")
end

function IrcBridge.OnPlayerDisconnect(eventStatus, pid)
   if Players[pid]:IsLoggedIn() then
      sendMessage(logicHandler.GetChatName(pid) .. " left the server.\n")
   end
end

function IrcBridge.OnPlayerSendMessage(eventStatus, pid, message)
    if not stringStarts(message, "/") then
       sendMessage(logicHandler.GetChatName(pid) .. ": " .. message)
    end
end

function IrcBridge.RecvMessage()
   if aPlayerIsLoggedIn() then
      IrcBridge.KeepAlive()
      IrcBridge.client:hook("OnChat", chatHook)
      tes3mp.StartTimer(timerIrcBridgeUpdate)
   end
end

function TimerIrcBridgeUpdateExpired()
   IrcBridge.RecvMessage()
end


customEventHooks.registerHandler("OnServerPostInit", IrcBridge.ConnectBot)
customEventHooks.registerHandler("OnPlayerAuthentified", IrcBridge.OnPlayerAuthentified)
customEventHooks.registerHandler("OnPlayerAuthentified", IrcBridge.RecvMessage)
customEventHooks.registerHandler("OnPlayerDeath", IrcBridge.OnPlayerDeath)
customEventHooks.registerHandler("OnPlayerSendMessage", IrcBridge.OnPlayerSendMessage)

customEventHooks.registerValidator("OnPlayerDisconnect", IrcBridge.OnPlayerDisconnect)
