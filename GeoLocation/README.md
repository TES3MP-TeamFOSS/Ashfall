# GeoLocation

Store geographical information about players that log in

Requires a CoreScripts version that supports event hooks.

## Installation

1. Copy all of [`lib`](lib) to `CoreScripts/lib/`.  Symlinks are OK.

1. Copy [`GeoLocation.lua`](GeoLocation.lua) to `CoreScripts/scripts/custom/`.  Symlinks are OK.

1. Add the following to `CoreScripts/customScripts.lua`:

        require("GeoLocation")

