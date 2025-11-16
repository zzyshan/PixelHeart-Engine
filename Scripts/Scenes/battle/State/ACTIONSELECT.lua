local ACTIONSELECT = {}

local function Createenemie()
    for _, enemie in ipairs(battle.enemies) do
        local enemie = enemie.data
        local enemiename = typer.Print("[size:28]* " .. enemie.name, {100, 270 + 32 * (_ - 1)}, 3)
        
        if enemie.canspare then
            enemiename.color.b = 0
            enemiename:Reparse()
        end
        table.insert(ui.enemie_text, enemiename)
    end
end

function ACTIONSELECT.update(ui)
    Player.canmove = false
    Player.sprite.x = ui.Buttons[ui.newState].x - 38
    Player.sprite.y = ui.Buttons[ui.newState].y
    
    if input.getKeyState("right") == 1 then
        if ui.Stateindex < #ui.State then
            ui.Stateindex = ui.Stateindex + 1
        else
            ui.Stateindex = 1
        end
        
        Audio.PlaySound("snd_menu_0.wav")
        ui.newState = ui.State[ui.Stateindex]
    end
    
    if input.getKeyState("left") == 1 then
        if ui.Stateindex > 1 then
            ui.Stateindex = ui.Stateindex - 1
        else
            ui.Stateindex = #ui.State
        end
        
        Audio.PlaySound("snd_menu_0.wav")
        ui.newState = ui.State[ui.Stateindex]
    end
    
    if input.getKeyState("z") == 1 then
        Audio.PlaySound("snd_menu_1.wav")
        if ui.newState == "fight" then -- 战斗
            Createenemie()
            STATE("ENEMYSELECT")
        elseif ui.newState == "act" then -- 行动
            Createenemie()
            STATE("ENEMYSELECT")
        elseif ui.newState == "item" then -- 物品
            local into = ITEMMENU.init()  -- 重置状态
            
            -- 设置状态
            if into then
                ITEMMENU.CreateItemTexts(ui)
                STATE("ITEMMENU")
            else
                return 
            end
        elseif ui.newState == "mercy" then -- 仁慈
            MERCYMENU.init()
            STATE("MERCYMENU")
        end
        
        encounterTyper:SetText("")
    end
end

return ACTIONSELECT