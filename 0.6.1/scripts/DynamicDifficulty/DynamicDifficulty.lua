-- DynamicDifficulty.lua -*-lua-*-
-- "THE BEER-WARE LICENCE" (Revision 42):
-- <mail@michael-fitzmayer.de> wrote this file.  As long as you retain
-- this notice you can do whatever you want with this stuff. If we meet
-- some day, and you think this stuff is worth it, you can buy me a beer
-- in return.  Michael Fitzmayer


require("config")


local Methods = {}


-- Add [ DynamicDifficulty = require("DynamicDifficulty") ] to the top of server.lua

-- Find "function OnPlayerCellChange(pid)" inside server.lua and add:
-- [ DynamicDifficulty.Update(pid) ]
-- directly underneath it.


Methods.Update = function(pid)
    local difficulty
    local difficultyMin = config.difficulty
    local difficultyCap = 150

    -- Level cap without abusing skill drain:
    -- Major skills: (100 - 30) * 5 = 350 / 10 = 35
    -- Minor skills: (100 - 15) * 5 = 425 / 10 ≈ 42
    local endgameLevel = 77
    local currentLevel = tes3mp.GetLevel(pid)

    difficulty = difficultyMin + (currentLevel * (difficultyCap - difficultyMin) / endgameLevel)
    difficulty = math.floor(difficulty)

    if difficulty < difficultyMin then difficulty = difficultyMin end
    if difficulty > difficultyCap then difficulty = difficultyCap end

    tes3mp.SetDifficulty(pid, difficulty)
    tes3mp.SendSettings(pid)
end


return Methods
