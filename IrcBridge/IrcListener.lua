-- -*- lua -*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer
local IrcBridge = require("IrcBridge")
local IrcListener = {}

function IrcListener.RecvMessage()
    IrcBridge.KeepAlive()
    IrcBridge.client:hook("OnChat", IrcBridge.ChatHook)
end

return IrcListener
