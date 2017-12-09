# PlayerExchangeLock

An experimental module for servers who share the same player base. It prevents players from joining server A in case they already logged into server B.

## Configuration

Update interval in milliseconds:
```Lua
config.intervalUpdate = 500
```
```Lua
config.jsonLocal = "/path/to/serverA.json"
config.jsonRemote = "/path/to/serverB.json"
```
