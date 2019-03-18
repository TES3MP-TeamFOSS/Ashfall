-- FixQuest.lua -*-lua-*-
-- "THE BEER-WARE LICENSE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer

local FixQuest = {}

-- Author: https://www.patreon.com/davidcernat
local function GetQuestHighestIndex(quest)
    local highestIndex = 0

    for _, journalItem in pairs(WorldInstance.data.journal) do
        if journalItem.quest == quest and journalItem.index > highestIndex then
            highestIndex = journalItem.index
        end
    end

    return highestIndex
end

-- Note: This fix is only needed if Torasa Aram from the Museum of
-- Artifacts has been permanently removed.
FixQuest.TR_Blade = function(eventStatus, pid)
    local index = GetQuestHighestIndex("tr_blade")

    if index == 25 then
        tes3mp.InitializeJournalChanges(pid)
        tes3mp.AddJournalEntry(pid, "tr_blade", 30, "barenziah")
        tes3mp.AddJournalEntry(pid, "tr_blade", 35, "karrod")
        tes3mp.AddJournalEntry(pid, "tr_blade", 40, "torasa aram")
        tes3mp.AddJournalEntry(pid, "tr_blade", 45, "torasa aram")
        tes3mp.AddTopic(pid, "dwemer battle shield")
        tes3mp.SendJournalChanges(pid)
        tes3mp.SendJournalChanges(pid, true)
        tes3mp.SendTopicChanges(pid)
        tes3mp.SendTopicChanges(pid, true)
        tes3mp.AddItem(pid, "dwemer_shield_battle_unique", 1, -1)
        tes3mp.SendInventoryChanges(pid)
    end
end


FixQuest.MV_TraderLate = function(eventStatus, pid)
    local index = GetQuestHighestIndex("mv_traderlate")

    if index == 10 then
        tes3mp.InitializeJournalChanges(pid)
        tes3mp.AddJournalEntry(pid, "mv_traderlate", 20, "rasha")
        tes3mp.AddJournalEntry(pid, "mv_traderlate", 40, "rasha")
        tes3mp.SendJournalChanges(pid)
        tes3mp.SendJournalChanges(pid, true)
    end
end


FixQuest.TT_SanctusShrine = function(eventStatus, pid)
    local index = GetQuestHighestIndex("tt_sanctusshrine")

    if index == 10 then
        tes3mp.InitializeJournalChanges(pid)
        tes3mp.AddJournalEntry(pid, "tt_sanctusshrine", 20, "endryn llethan")
        tes3mp.AddJournalEntry(pid, "tt_sanctusshrine", 50, "endryn llethan")
        tes3mp.AddJournalEntry(pid, "tt_sanctusshrine", 100, "endryn llethan")
        tes3mp.SendJournalChanges(pid)
        tes3mp.SendJournalChanges(pid, true)
    end


end

customEventHooks.registerHandler("OnPlayerJournal", FixQuest.TR_Blade)
customEventHooks.registerHandler("OnPlayerJournal", FixQuest.MV_TraderLate)
customEventHooks.registerHandler("OnPlayerJournal", FixQuest.TT_SanctusShrine)
