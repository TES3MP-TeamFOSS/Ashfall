-- BannedItems.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


local Methods = {}


-- Add [ BannedItems = require("BannedItems") ] to the top of myMod.lua

-- Find "OnPlayerInventory(pid)" inside myMod.lua and insert:
-- [ BannedItems.Remove(pid) ]
-- directly underneath [ Players[pid]:SaveInventory() ].


local removeBannedItems = false


Methods.Remove = function(pid)
    local message = color.Crimson .. "Banned item has been removed.\n" .. color.Default

    -- Ridiculously over-powerful items which can be obtained without
    -- difficulty. Or items that simply destroy the overall balance:
    local bannedItems = {
        "amulet_gaenor",
        "azura's servant",
        "bm_amulstr1",
        "bm_mace_aevar_uni",
        "bm_nordic01_robe_whitewalk",
        "boots of blinding speed[unique]",
        "bound_boots",
        "bound_cuirass",
        "bound_gauntlet_left",
        "bound_gauntlet_right",
        "bound_helm",
        "bound_shield",
        "cuirass_savior_unique",
        "daedric dagger_mtas",
        "daedric_boots",
        "daedric_crescent_unique",
        "daedric_cuirass",
        "daedric_cuirass_htab",
        "daedric_fountain_helm",
        "daedric_gauntlet_left",
        "daedric_gauntlet_right",
        "daedric_god_helm",
        "daedric_greaves",
        "daedric_greaves_htab",
        "daedric_helm_clavicusvile",
        "daedric_pauldron_left",
        "daedric_pauldron_right",
        "daedric_scourge_unique",
        "daedric_shield",
        "daedric_terrifying_helm",
        "daedric_towershield",
        "dragonbone_cuirass_unique",
        "ebon_plate_cuirass_unique",
        "ebony scimitar_her",
        "ebony_cuirass_soscean",
        "gauntlet_fists_l_unique",
        "gauntlet_fists_r_unique",
        "gravedigger",
        "helm_bearclaw_unique",
        "helseth's ring",
        "king's_oath_pc",
        "longsword_umbra_unique",
        "mantle of woe",
        "necromancers_amulet_uniq",
        "nerevarblade_01_flame",
        "ring_denstagmer_unique",
        "ring_marara_unique",
        "ring_phynaster_unique",
        "ring_wind_unique",
        "spell_breaker_unique",
        "staff_hasedoki_unique",
        "sword of almalexia",
        "tenpaceboots",
        "towershield_eleidon_unique"
    }

    local hadBannedItem = false

    for index, item in pairs(bannedItems) do
        if tableHelper.containsKeyValue(Players[pid].data.inventory, "refId", item, true) then
            hadBannedItem = true
            local itemIndex = tableHelper.getIndexByNestedKeyValue(Players[pid].data.inventory, "refId", item)
            Players[pid].data.inventory[itemIndex] = nil
        end

        if tableHelper.containsKeyValue(Players[pid].data.equipment, "refId", item, true) then
            hadBannedItem = true
            local itemIndex = tableHelper.getIndexByNestedKeyValue(Players[pid].data.equipment, "refId", item)
            Players[pid].data.equipment[itemIndex] = nil
        end
    end

    if hadBannedItem == true then
        Players[pid]:Save()
        Players[pid]:LoadInventory()
        Players[pid]:LoadEquipment()
        tes3mp.SendMessage(pid, message, false)
    end
end


return Methods
