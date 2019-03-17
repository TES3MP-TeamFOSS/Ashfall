-- StarterKit.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer

local StarterKit = {}

local skillBlock       =  0
local skillArmorer     =  1
local skillMediumArmor =  2
local skillHeavyArmor  =  3
local skillBluntWeapon =  4
local skillLongBlade   =  5
local skillAxe         =  6
local skillSpear       =  7
local skillAthletics   =  8
local skillEnchant     =  9
local skillDestruction = 10
local skillAlteration  = 11
local skillIllusion    = 12
local skillConjuration = 13
local skillMysticism   = 14
local skillRestoration = 15
local skillAlchemy     = 16
local skillUnarmored   = 17
local skillSecurity    = 18
local skillSneak       = 19
local skillAcrobatics  = 20
local skillLightArmor  = 21
local skillShortBlade  = 22
local skillMarksman    = 23
local skillMercantile  = 24
local skillSpeechcraft = 25
local skillHandToHand  = 26

function StarterKit.OnPlayerEndCharGen(eventStatus, pid)
    local index = 0
    local tmp   = {}
    local temp  = 0
    local race  = tes3mp.GetRace(pid)
    local spell = {}
    local preferredArmorClass  = 0
    local preferredWeaponClass = 0
    local starterKit = { { "iron fork", 1, -1 } }

    -- Determine preferred armor class.
    tmp[0] = tes3mp.GetSkillBase(pid, skillUnarmored)
    tmp[1] = tes3mp.GetSkillBase(pid, skillLightArmor)
    tmp[2] = tes3mp.GetSkillBase(pid, skillMediumArmor)
    tmp[3] = tes3mp.GetSkillBase(pid, skillHeavyArmor)

    while tmp[index] ~=nil do
        if tmp[index] > temp then
            preferredArmorClass = index
            temp = tmp[index]
        end
        index = index + 1
    end
    index = 0
    temp  = 0

    -- Unarmored.
    if preferredArmorClass == 0 then
        table.insert(starterKit, { "sc_firstbarrier",  2, -1 })
        table.insert(starterKit, { "sc_secondbarrier", 2, -1 })
        table.insert(starterKit, { "sc_thirdbarrier",  2, -1 })
    end
    -- LightArmor.
    if preferredArmorClass == 1 then
        table.insert(starterKit, { "fur_helm",    1, -1 })
        table.insert(starterKit, { "fur_greaves", 1, -1 })


        if race ~= "argonian" and race ~= "khajiit" then
            table.insert(starterKit, { "fur_boots",   1, -1 })
            table.insert(starterKit, { "fur_cuirass", 1, -1 })
        else
            table.insert(starterKit, { "imperial_studded_cuirass", 1, -1 })
        end
    end
    -- MediumArmor.
    if preferredArmorClass == 2 then
        table.insert(starterKit, { "nordic_ringmail_cuirass",  1, -1 })
        table.insert(starterKit, { "imperial_chain_coif_helm", 1, -1 })
    end
    -- HeavyArmor.
    if preferredArmorClass == 3 then
        table.insert(starterKit, { "iron_cuirass", 1, -1 })
        table.insert(starterKit, { "iron_helmet",  1, -1 })
    end
    -- Block.
    if tes3mp.GetSkillBase(pid, skillBlock) >= 15 then
        table.insert(starterKit, { "nordic_leather_shield", 1, -1 })
    end

    -- Determine preferred weapon class.
    tmp[0] = tes3mp.GetSkillBase(pid, skillAxe)
    tmp[1] = tes3mp.GetSkillBase(pid, skillBluntWeapon)
    tmp[2] = tes3mp.GetSkillBase(pid, skillHandToHand)
    tmp[3] = tes3mp.GetSkillBase(pid, skillLongBlade)
    tmp[4] = tes3mp.GetSkillBase(pid, skillMarksman)
    tmp[5] = tes3mp.GetSkillBase(pid, skillShortBlade)
    tmp[6] = tes3mp.GetSkillBase(pid, skillSpear)

    while tmp[index] ~=nil do
        if tmp[index] > temp then
            preferredWeaponClass = index
            temp = tmp[index]
        end
        index = index + 1
    end
    index = 0
    temp  = 0

    -- Axe.
    if preferredWeaponClass == 0 then
        table.insert(starterKit, { "iron war axe", 1, -1 })
    end
    -- BluntWeapon.
    if preferredWeaponClass == 1 then
        table.insert(starterKit, { "iron club", 1, -1 })
    end
    -- HandToHand.
    if preferredWeaponClass == 2 then
        table.insert(starterKit, { "p_restore_fatigue_s", 5, -1 })
    end
    -- LongBlade.
    if preferredWeaponClass == 3 then
        table.insert(starterKit, { "iron saber", 1, -1 })
    end
    -- Marksman.
    if preferredWeaponClass == 4 then
        table.insert(starterKit, { "short bow",   1, -1 })
        table.insert(starterKit, { "iron arrow", 50, -1 })
    end
    -- ShortBlade.
    if preferredWeaponClass == 5 then
        table.insert(starterKit, { "iron shortsword", 1, -1 })
    end
    -- Spear.
    if preferredWeaponClass == 6 then
        table.insert(starterKit, { "iron spear", 1, -1 })
    end

    -- All about magic.
    tmp[0] = tes3mp.GetSkillBase(pid, skillAlteration)
    tmp[1] = tes3mp.GetSkillBase(pid, skillConjuration)
    tmp[2] = tes3mp.GetSkillBase(pid, skillDestruction)
    tmp[3] = tes3mp.GetSkillBase(pid, skillIllusion)
    tmp[4] = tes3mp.GetSkillBase(pid, skillMysticism)
    tmp[5] = tes3mp.GetSkillBase(pid, skillRestoration)
    tmp[6] = nil

    while tmp[index] ~=nil do
        if tmp[index] >= 15 then temp = temp + 2 end
        index = index + 1
    end
    -- index = 0
    if temp > 0 then
        table.insert(starterKit, { "p_restore_magicka_s", temp, -1 })
    end
    -- temp  = 0

    -- Alteration.
    if tmp[0] >= 15 then
        spell = { spellId = "ondusi's open door" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    -- Conjuration.
    if tmp[1] >= 15 then
        spell = { spellId = "summon least bonewalker" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    -- Destruction.
    if tmp[2] then
        spell = { spellId = "clench" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    -- Illusion.
    if tmp[3] >= 15 then
        spell = { spellId = "demoralize creature" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    -- Mysticism.
    if tmp[4] >= 15 then
        spell = { spellId = "detect key" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    -- Restoration.
    if tmp[5] >= 15 then
        spell = { spellId = "cure common disease on other" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    -- Alchemy.
    if tes3mp.GetSkillBase(pid, skillAlchemy) >= 15 then
        table.insert(starterKit, { "apparatus_a_mortar_01",      1, -1 })
        table.insert(starterKit, { "apparatus_a_calcinator_01",  1, -1 })
        table.insert(starterKit, { "ingred_wickwheat_01",       20, -1 })
        table.insert(starterKit, { "ingred_saltrice_01",        20, -1 })
    end
    -- Enchant.
    temp = tes3mp.GetSkillBase(pid, skillEnchant)
    if temp >= 15 then
        table.insert(starterKit, { "misc_soulgem_petty", 5, -1 })
        spell = { spellId = "soul trap" }
        table.insert(Players[pid].data.spellbook, spell)
    end
    if temp >= 30 then
        table.insert(starterKit, { "misc_soulgem_lesser", 5, -1 })
    end

    -- Miscellaneous.
    -- Acrobatics.
    if tes3mp.GetSkillBase(pid, skillAcrobatics) >= 15 then
        table.insert(starterKit, { "p_restore_fatigue_s", 5, -1 })
        table.insert(starterKit, { "sc_tinurshoptoad",    2, -1 })
    end
    -- Armorer.
    if tes3mp.GetSkillBase(pid, skillArmorer) >= 15 then
        table.insert(starterKit, { "hammer_repair", 5, -1 })
    end
    -- Athletics.
    if tes3mp.GetSkillBase(pid, skillAthletics) >= 15 then
        table.insert(starterKit, { "p_restore_fatigue_s", 5, -1 })
        table.insert(starterKit, { "sc_celerity",         2, -1 })
        table.insert(starterKit, { "sc_vigor",            2, -1 })
    end
    -- Security.
    if tes3mp.GetSkillBase(pid, skillSecurity) >= 15 then
        table.insert(starterKit, { "pick_apprentice_01",  5, -1 })
        table.insert(starterKit, { "probe_apprentice_01", 5, -1 })
    end
    -- Sneak.
    if tes3mp.GetSkillBase(pid, skillSneak) >= 15 then
        table.insert(starterKit, { "sc_golnaraseyemaze", 2, -1 })
        table.insert(starterKit, { "sc_invisibility",    2, -1 })
    end
    -- Speechcraft.
    if tes3mp.GetSkillBase(pid, skillSpeechcraft) >= 15 then
        table.insert(starterKit, { "sc_heartwise", 2, -1 })
    end
    -- Last but not least: Mercantile/Base gold.
    tmp[0] = tes3mp.GetSkillBase(pid, skillMercantile)
    if     tmp[0] >= 30 then temp = 500
    elseif tmp[0] >= 15 then temp = 250
    else   temp    = 50 end
    table.insert(starterKit, { "gold_001", temp, -1 })

    for _, item in pairs(starterKit) do
        local structuredItem = { refId = item[1], count = item[2], charge = item[3] }
        table.insert(Players[pid].data.inventory, structuredItem)
    end

    Players[pid]:LoadInventory()
    Players[pid]:LoadEquipment()
    Players[pid]:LoadQuickKeys()
    Players[pid]:LoadSpellbook()
end

customEventHooks.registerHandler("OnPlayerEndCharGen", StarterKit.OnPlayerEndCharGen)
