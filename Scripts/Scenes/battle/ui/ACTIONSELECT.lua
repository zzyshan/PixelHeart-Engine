local ACTIONSELECT = {}

local function Createenemie()
    for _, enemie in ipairs(battle.enemies) do
        local enemiename = typer.New("[skip]* " .. enemie.name, {100, 270 + 32 * (_ - 1)}, 3, {voice = "uifont.wav"})
        
        if enemie.canspare then
            enemiename:SetColor(1, 1, 0)
        end
        encounterTyper:SetScale(28)
        table.insert(ui.enemie_text, enemiename)
    end
end

function ACTIONSELECT.update(ui)
    Player.canmove = false
    Player.sprite.x = ui.Buttons[ui.newState].x - 38
    Player.sprite.y = ui.Buttons[ui.newState].y
    
    if Keyboard.getState("right") == 1 then
        if ui.Stateindex < #ui.State then
            ui.Stateindex = ui.Stateindex + 1
        else
            ui.Stateindex = 1
        end
        
        Audio.PlaySound("snd_menu_0.wav")
        ui.newState = ui.State[ui.Stateindex]
    end
    
    if Keyboard.getState("left") == 1 then
        if ui.Stateindex > 1 then
            ui.Stateindex = ui.Stateindex - 1
        else
            ui.Stateindex = #ui.State
        end
        
        Audio.PlaySound("snd_menu_0.wav")
        ui.newState = ui.State[ui.Stateindex]
    end
    
    if Keyboard.getState("z") == 1 then
        encounterTyper:SetText("")
        Audio.PlaySound("snd_menu_1.wav")
        if ui.newState == "fight" then -- 战斗
            Createenemie()
            STATE("ENEMYSELECT")
        elseif ui.newState == "act" then -- 行动
            Createenemie()
            STATE("ENEMYSELECT")
        elseif ui.newState == "item" then -- 物品
            ITEMMENU.init()  -- 重置状态
            ITEMMENU.CreateItemTexts(ui)
            
            -- 设置状态
            STATE("ITEMMENU")
        elseif ui.newState == "mercy" then -- 仁慈
            MERCYMENU.init()
            STATE("MERCYMENU")
        end
    end
end

return ACTIONSELECT