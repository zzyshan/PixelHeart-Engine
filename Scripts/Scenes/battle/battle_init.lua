local battle_init = {}

Encounter = require("Scripts/Waves/" .. scenes.var.BATTLE .. "/Encounter") -- 这个scenes.BATTLE详见MainLibrary/scenes.lua
Arenas = require("Scripts/Libraries/Arenas")

battle = {
    State = "ACTIONSELECT",
    oldState = "ACTIONSELECT",
    EncounterText = Encounter.Text or "",
    wintext = Encounter.wintext,
    nextwaves = Encounter.nextwaves or {},
    nextwave = Encounter.wave,
    wave = nil,
    nextanim = nil,
    anim = nil,
    waveindex = 1,
    load = Encounter.load,
    update = Encounter.update,
    EnteringState = Encounter.EnteringState,
    HandleActions = Encounter.HandleActions,
    HandleItems = Encounter.HandleItems,
    HandleSpare = Encounter.HandleSpare,
    DefenseEnding = Encounter.DefenseEnding,
    canflee = Encounter.canflee,
    Escapeprobability = Encounter.Escapeprobability or 0.5,
    nextscene = Encounter.scene,
    enemies = Encounter.enemies or {},
    spareenemie = 0,
    allenemy = #Encounter.enemies,
    allexp = 0,
    allgold = 0,
    path = "Scripts/Waves/" .. scenes.var.BATTLE
}

for _, enemie in ipairs(battle.enemies) do
    enemie.data = require(battle.path .. "/enemies/" .. enemie.path_name)
end

for _, enemie in ipairs(battle.enemies) do
    battle.allexp = battle.allexp + (enemie.data.exp or 0)
    battle.allgold = battle.allgold + (enemie.data.gold or 0)
end

ui = require("Scripts/Scenes/battle/ui")

function STATE(sname, var)
    if (battle) then
        if var then
            for name, var in pairs(var) do
                battle[name] = var
            end
        end
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

function battle.DeleteEnemie(index)
    if battle.enemies[index] then
        table.remove(battle.enemies, index)
        battle.allenemy = battle.allenemy - 1
    else
        print("en.Not found enemie")
    end
end

function battle.AddEnemie(path_name, pos)
    local pos = pos or #battle.enemies +1
    local enemie = {
        path_name = path_name,
        data = require(battle.path .. "/enemies/" .. path_name)
    }
    table.insert(battle.enemies, pos, enemie)
    battle.allenemy = battle.allenemy + 1
    
    print("en.Monster added")
end

function battle.GetEnemieData(index)
    if not battle.enemies[index] then return false end
    return battle.enemies[index].data
end

function battle.GetEnemie(index)
    if not battle.enemies[index] then return false end
    return battle.enemies[index]
end

function battle.AddUiState(name, pos)
    local pos = pos or #battle.enemies +1
    table.insert(ui.State, pos, name)
    
    print("en.State added")
end

function battle.DeleteUiState(index)
    if ui.State[index] then
        table.remove(ui.State, index)
        print("en.Deleted Status")
    else
        print("en.Not found enemie")
    end
end

function battle_init.load()
    scenes.Settype("battle")
    save.load(1)
    Player.init()
    if battle.load then
        battle.load()
    end
    battle.main_arena = Arenas.new({320,320}, 565, 130, 0, "rectangle", "plus")
    battle.main_arena.isactive = false
end

function battle_init.update(dt)
    typer.allPressed()
    ui.update(dt)
    Arenas.update(dt)
    if battle.update then
        battle.update(dt)
    end
end

function battle_init.draw()
    
end

function battle_init.over()
    package.loaded[battle.path .. "/Encounter"] = nil
    package.loaded["Scripts/Libraries/Arenas"] = nil
    package.loaded["Scripts/Scenes/battle/ui"] = nil
    Sprites.clear()
    typer.clear()
end

return battle_init