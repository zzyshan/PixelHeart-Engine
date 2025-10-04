local ui = {
    Buttons = {
        fight = Sprites.New("ui/FIGHT 0.png", {85, 455}, 1),
        act = Sprites.New("ui/ACT 0.png", {240, 455}, 1),
        item = Sprites.New("ui/ITEM 0.png", {400, 455}, 1),
        mercy = Sprites.New("ui/MERCY 0.png", {555, 455}, 1)
    },
    name = typer.Print(Player.Name, {30, 400}, 1, {font = "Mars Needs Cunnilingus.ttf"}),
    lv = Sprites.New("ui/LV.png", {132, 403}, 1),
    lv_text = typer.Print(Player.Lv, {171, 400}, 1, {font = "Mars Needs Cunnilingus.ttf"}),
    hpname = Sprites.New("ui/HP.png", {255, 410}, 1),
    maxhp = Sprites.New("px.png", {275, 410}, 1, {g = 0, b = 0}),
    hp = Sprites.New("px.png", {275, 410}, 1, {b = 0}),
    hptext = typer.Print(Player.Hp .. " / " .. Player.maxhp, {275, 400}, 1, {font = "Mars Needs Cunnilingus.ttf"}),
    
    State = {"fight", "act", "item", "mercy"},
    Stateindex = 1,
    
    enemie_text = {},
    enemieindex = 1,
    enemie_acttext = {},
    itemtext = {},
    
    oldname = Player.Name,
    oldlv = Player.Lv,
    oldhp = Player.Hp,
    oldmaxhp = Player.maxhp
}

ui.oldState = ui.State[ui.Stateindex]
ui.newState = ui.State[ui.Stateindex]
ui.maxhp:SetPivot(0, 0.5)
ui.maxhp:SetScale(mathlib.clamp(Player.maxhp * 1.21, 20 * 1.21, 99 * 1.21), 20)
ui.hp:SetPivot(0, 0.5)
ui.hp:SetScale(mathlib.clamp(Player.Hp * 1.21, 1 * 1.21, 99 * 1.21), 20)
ui.lv:SetPivot(0, 0)
ui.hptext.x = ui.hp.x + ui.hp:getWidth() + 30
ui.Buttons[ui.newState]:Set("ui/" .. ui.newState:upper() .. " 1.png")
encounterTyper = typer.New(battle.EncounterText, {54, 270}, 3, {voice = "uifont.wav"})
encounterTyper:SetScale(28)

ACTIONSELECT = require("Scripts/Scenes/battle/State/ACTIONSELECT")
ATTACKING = require("Scripts/Scenes/battle/State/ATTACKING")
ACTMENU = require("Scripts/Scenes/battle/State/ACTMENU")
ENEMYSELECT = require("Scripts/Scenes/battle/State/ENEMYSELECT")
ITEMMENU = require("Scripts/Scenes/battle/State/ITEMMENU")
MERCYMENU = require("Scripts/Scenes/battle/State/MERCYMENU")
RUNAWAY = require("Scripts/Scenes/battle/State/RUNAWAY")
WIN = require("Scripts/Scenes/battle/State/WIN")
DEFENDING = require("Scripts/Scenes/battle/State/DEFENDING")
ANIMING = require("Scripts/Scenes/battle/State/ANIMING")
--local pb = Sprites.New("ui/640 480.png", {}, 2.5)
---------- 用的函数 --------+---
function ui.ClearTexts(textList)
    for i = #textList, 1, -1 do
        textList[i]:Remove()
        table.remove(textList, i)
    end
end
-------------------------------+----

function ui.update(dt)
    ui.hptext.x = math.max(ui.maxhp.x + ui.maxhp.scale.x + 15, ui.maxhp.x + ui.hp.scale.x + 15)
    ui.hp.scale.x = (Player.Hp / Player.maxhp) * ui.maxhp.scale.x
    ui.maxhp:SetScale(mathlib.clamp(Player.maxhp * 1.21, 1 * 1.21, 99 * 1.21), 20)

    if ui.oldname ~= Player.Name then
        ui.name.text = Player.Name
        ui.oldname = Player.Name
    end
    
    if ui.oldlv ~= Player.Lv then
        ui.lv_text.text = Player.Lv
        ui.oldlv = Player.Lv
    end 
    
    if ui.oldhp ~= Player.Hp then
        ui.hptext.text = Player.Hp .. " / " .. Player.maxhp
        ui.oldhp = Player.Hp
    end
    
    if ui.oldmaxhp ~= Player.maxhp then
        ui.hptext.text = Player.Hp .. " / " .. Player.maxhp
        ui.oldmaxhp = Player.maxhp
    end
--------------- 按键状态逻辑 ----------------------
    if ui.oldState ~= ui.newState or battle.oldState ~= battle.State then
        for i = 1, #ui.State do
            local button = ui.State[i]
            if battle.State ~= "DEFENDING" then
                if button == ui.newState then
                    ui.Buttons[button]:Set("ui/" .. button:upper() .. " 1.png")
                else
                    ui.Buttons[button]:Set("ui/" .. button:upper() .. " 0.png")
                end
            else
                ui.Buttons[button]:Set("ui/" .. button:upper() .. " 0.png")
            end
        end

        ui.newState = ui.State[ui.Stateindex]
        print("oldbutton: " .. ui.oldState .. "newbutton: " .. ui.newState)
        ui.oldState = ui.newState
    end
-------------- end -----------------------------
    
    if battle.oldState ~= battle.State then
        if battle.State == "ACTIONSELECT" then
            battle.main_arena:Resize(565, 130)
            battle.main_arena:RotateTo(0)
            Player.sprite.hide = false
            battle.main_arena.isactive = false
            Player.canmove = false
            encounterTyper:SetText(battle.EncounterText)
        elseif battle.State == "DEFENDING" then
            encounterTyper:SetText("")
            Player.sprite.hide = false
            battle.main_arena.isactive = true
            Player.canmove = true
        end
        battle.EnteringState(battle.State, battle.oldState)
        print("newState:" .. battle.State .. " oldState:" .. battle.oldState)
        battle.oldState = battle.State
    end
       
    if battle.State == "ACTIONSELECT" then -- 玩家选择
        ACTIONSELECT.update(ui)
    elseif battle.State == "ENEMYSELECT" then -- 选择怪物
        ENEMYSELECT.update(ui)
    elseif battle.State == "ATTACKING" then
        ATTACKING.update(ui)
    elseif battle.State == "ACTMENU" then -- 行动菜单
        ACTMENU.update(ui)
    elseif battle.State == "ITEMMENU" then
        ITEMMENU.update(ui)
    elseif battle.State == "MERCYMENU" then
        MERCYMENU.update(ui)
    elseif battle.State == "RUNAWAY" then
        RUNAWAY.update(ui)
    elseif battle.State == "WIN" then
        WIN.update(ui)
    elseif battle.State == "DEFENDING" then
        DEFENDING.update(dt)
    elseif battle.State == "ANIMING" then
        ANIMING.update(dt, ui)
    end
end

return ui