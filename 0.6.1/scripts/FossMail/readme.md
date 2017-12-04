# FossMail
A script for sending messages and items between players, regardless of whether they are on/offline, via an ingame GUI.

## Features
* View + compose messages via an ingame GUI.
* Add items from your inventory as attachments.
* Support for other scripts to create + send messages, with the ability to create special attachments that execute external functions when claimed.

## Usage
### Commands
* `/mail` - Opens the mod's GUI

### Support for Scripts
I'll write all the info for other scripts here once I get the time :P - Atkana.

## Known Issues
* It's possible to write a message long enough that important buttons (such as close) are pushed off of the screen. A length limit was planned for release 1, but was pushed back because of some weirdness with how tes3mp was behaving.
* Items have to display their refIds, rather than their names. This is due to a limitation with the current version of tes3mp. In the future, itemInfo support might be added so that they display their proper names.
* You can't send items with the same refId as items you currently have equipped. This is a workaround to get around some gaps in my (Atkana's) knowledge. Once I fully understand how equipment is handled, this limitation will definitely be removed.
