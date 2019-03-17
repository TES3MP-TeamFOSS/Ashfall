# IrcBridge

A module to bridge IRC and the in-game chat. It can be easily enhanced to work with Discord using [matterbridge](https://github.com/42wim/matterbridge).

Requires a CoreScripts version that supports event hooks.

## Installation

1. Copy [`lib/socket`](lib/socket) to `CoreScripts/lib/`.  Symlinks are OK.

1. Copy [`lib/lua/irc`](lib/lua/irc) to `CoreScripts/lib/lua/`.  Symlinks are OK.

1. Copy [`lib/lua/irc.lua`](lib/lua/irc.lua) to `CoreScripts/lib/lua/`.  Symlinks are OK.

1. Copy [`IrcListener.lua`](IrcListener.lua) to `CoreScripts/scripts/`.  Symlinks are OK.

1. Copy [`IrcBridge.lua`](IrcBridge.lua) to `CoreScripts/scripts/`.  Symlinks are OK.

1. Configure [your bot settings](IrcBridge/IrcBridge.lua#L11-L15).

1. Add the following to the top of `CoreScripts/serverCore.lua` (beneath `require("customScripts")`):

        IrcListener = require("IrcListener")

1. Add the following to `CoreScripts/customScripts.lua`:

        require("IrcBridge")

