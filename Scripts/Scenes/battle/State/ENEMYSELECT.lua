local ENEMYSELECT = {}

local function CreateMenuact(acts, startPos)
    local actTexts = {}
    for i, text in ipairs(acts) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local x = startPos.x + col * 200
        local y = startPos.y + row * 32
        
        local actText = typer.Print("[size:28]* " .. text, {x, y}, 3)
        table.insert(actTexts, actText)
    end
    return actTexts
end

function ENEMYSELECT.update(ui)
    if ui.enemieindex > #battle.enemies then
        ui.enemieindex = #battle.enemies
    end
    local newenemie = battle.enemies[ui.enemieindex]
    
    Player.sprite.x = ui.enemie_text[ui.enemieindex].x - 25
    Player.sprite.y = ui.enemie_text[ui.enemieindex].y + 15
    
    if input.getKeyState("down") == 1 then
        ui.enemieindex = ui.enemieindex < #battle.enemies and ui.enemieindex + 1 or 1
        if #battle.enemies > 1 then
            Audio.PlaySound("snd_menu_0.wav")
        end
    end

    if input.getKeyState("up") == 1 then
        ui.enemieindex = ui.enemieindex > 1 and ui.enemieindex - 1 or #battle.enemies
    
        if #battle.enemies > 1 then
            Audio.PlaySound("snd_menu_0.wav")
        end
    end
    
    if input.getKeyState("x") == 1 then
        ui.ClearTexts(ui.enemie_text)
        STATE("ACTIONSELECT")
    elseif input.getKeyState("z") == 1 then
        if ui.newState == "act" then -- 行动中的选择
            -- 隐藏文本
            for i = #ui.enemie_text, 1, -1 do
                ui.enemie_text[i].hide = true
            end
            
            ui.enemie_acttext = CreateMenuact(newenemie.data.commands, {x=100, y=270})
            Audio.PlaySound("snd_menu_1.wav")
            ui.Selectedenemie = battle.enemies[ui.enemieindex] --记录选中的怪物
            STATE("ACTMENU")
        elseif ui.newState == "fight" then
            Audio.PlaySound("snd_menu_1.wav")
            ui.ClearTexts(ui.enemie_text)
            Player.sprite.hide = true
            ui.Selectedenemie = battle.enemies[ui.enemieindex]
            ATTACKING.init()
            STATE("ATTACKING")
        end
    end
end

return ENEMYSELECT