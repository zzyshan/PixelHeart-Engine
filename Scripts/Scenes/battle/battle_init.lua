local battle_init = {}

local path = "Scripts/Scenes/Overworld/"
Encounter = require("Scripts/Waves/" .. scenes.BATTLE .. "/Encounter") -- 这个scenes.BATTLE详见MainLibrary/scenes.lua
Arenas = require("Scripts/Libraries/Arenas")

battle = {
    State = "ACTIONSELECT",
    oldState = "ACTIONSELECT",
    EncounterText = Encounter.Text or "",
    wintext = Encounter.wintext,
    nextwaves = Encounter.nextwaves or {},
    nextwave = Encounter.wave,
    wave = nil,
    waveindex = 1,
    Playerload = Encounter.Player,
    EnteringState = Encounter.EnteringState,
    HandleActions = Encounter.HandleActions,
    HandleItems = Encounter.HandleItems,
    DefenseEnding = Encounter.DefenseEnding,
    canflee = Encounter.canflee or true,
    Escapeprobability = Encounter.Escapeprobability or 0.5,
    nextscene = Encounter.scene,
    enemies = Encounter.enemies or {},
    spareenemie = 0,
    allenemy = #Encounter.enemies,
    allexp = 0,
    allgold = 0
}
package.loaded[Encounter] = nil

for _, enemie in ipairs(battle.enemies) do
    battle.allexp = battle.allexp + (enemie.exp or 0)
    battle.allgold = battle.allgold + (enemie.gold or 0)
end

ui = require("Scripts/Scenes/battle/ui/ui")

function STATE(sname)
    if (battle) then
        battle.State = sname
    end
end

function BattleDialogue(texts, targetState, isskip)
    local tab, tstate
    if (type(texts) == "string") then
        tab = {texts}
    else
        tab = texts
    end
    if (type(targetState) == "string") then
        tstate = targetState
    else
        tstate = "ACTIONSELECT"
    end
    
    tab[#tab + 1] = "[noskip][nextpage]"
    local t = typer.New(tab, {60, 270}, 3, {voice = "uifont.wav"})
    t.mode = "manual"
    if isskip then
        t:skip()
    end
    t.over = function()
        Player.sprite.hide = false
        STATE(tstate)
    end
end

function battle_init.load()
    scenes.Settype("battle")
    save.load(1)
    Player.init()
    if battle.Playerload then
        battle.Playerload()
    end
    battle.main_arena = Arenas.new({320,320}, 565, 130, 0, "rectangle", "plus")
    battle.main_arena.isactive = false
end

function battle_init.update(dt)
    typer.allPressed()
    ui.update(dt)
    Arenas.update(dt)
end

function battle_init.draw()
    if battle_init.newmap then
        if battle_init.newmap.draw then
            battle_init.newmap.draw()
        end
    end 
end

function battle_init.over()
    package.loaded[Arenas] = nil
    package.loaded[ui] = nil
    Sprites.clear()
    typer.clear()
end

return battle_init