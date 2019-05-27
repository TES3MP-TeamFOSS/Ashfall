# IrcBridge

A module to bridge IRC and the in-game chat. It can be easily enhanced to work with Discord using [matterbridge](https://github.com/42wim/matterbridge).

Requires a CoreScripts version that supports event hooks.

## Installation

1. Copy [`lib/socket`](lib/socket) to `CoreScripts/lib/`.  Symlinks are OK.

1. Copy [`lib/lua/socket.lua`](lib/lua/socket.lua) to `CoreScripts/lib/lua/`.  Symlinks are OK.

1. Copy [`lib/lua/irc`](lib/lua/irc) to `CoreScripts/lib/lua/`.  Symlinks are OK.

1. Copy [`lib/lua/irc.lua`](lib/lua/irc.lua) to `CoreScripts/lib/lua/`.  Symlinks are OK.

1. Copy [`IrcBridge.lua`](IrcBridge.lua) to `CoreScripts/scripts/custom/`.  Symlinks are OK.

1. Configure [your bot settings](IrcBridge/IrcBridge.lua#L11-L15) ([DataManager](https://github.com/tes3mp-scripts/DataManager) is optionally supported).

1. Add the following to `CoreScripts/customScripts.lua`:

        require("IrcBridge")

