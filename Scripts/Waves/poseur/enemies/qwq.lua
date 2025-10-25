local qwq = {
    name = "???",
    hp = 1000,
    maxdamage = 200,
    commands = {"Observation"}
}

function qwq.HandleActions(enemy_name, action, enemy)
    if action == "Observation" then
        battle.DeleteEnemie(1)
        STATE("ANIMING", {nextanim = "into"})
    end
end

local slice
local miss
function qwq.customAttack(time, AA)
    if time == 1 then
        slice = AA.slice()
    end
    if slice.remove then
        miss = AA.PopUpText("[skip]MISS", {320, 180}, {g = 1, b = 1})
        slice.remove = false
    end
    
    if miss and miss.y >= miss.starty then
        AA.Removesprite()
        miss:Remove()
        miss = nil
        battle.EncounterText = "[font:SmileySans-Oblique.ttf][font_size:30]* 你是永远打不破一片虚无的..."
        return true
    end
end

return qwq