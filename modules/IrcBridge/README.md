# IrcBridge

A module to bridge IRC and the in-game chat. It can be easily enhanced to work with Discord using [matterbridge](https://github.com/42wim/matterbridge).

## Dependencies

This module requires `luasocket` which is part of the `lib` sub-directory in this repository.

## Configuration

```Lua
config.nick             = "DagothUr"
```
```Lua
config.server           = "irc.freenode.net"
```
```Lua
config.nickservPassword = "pleasedonttellanyone"
```
```Lua
config.channel          = "#tes3mp"
```
```Lua
config.nickFilter       = "Discord_Bridge"
```
```Lua
config.notifyDeath      = true
config.notifyCellChange = true
config.notifyConnect    = true
config.notifyDisconnect = true
config.notifyLevel      = true
```
