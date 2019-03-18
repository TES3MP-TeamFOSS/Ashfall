# RealEstate

A module to provide houses buyable by players.

Requires a CoreScripts version that supports event hooks.

## Installation

1. Copy [`RealEstate.lua`](RealEstate.lua) to `CoreScripts/scripts/custom/`.  Symlinks are OK.

1. Copy [`data`](data) to `CoreScripts/data/` and rename it to `RealEstate`.  Symlinks are OK.

1. Optionally edit the path to the above data folder.

1. Add the following to `CoreScripts/customScripts.lua`:

        require("RealEstate")

