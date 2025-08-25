local ACTMENU = {}

function ACTMENU.update(ui)
    local SE = ui.Selectedenemie
    local actionCount = #SE.commands  -- 获取行动选项数量
    
    -- 确保有行动选项
    if #ui.enemie_acttext > 0 then
        -- 初始化行动索引（如果还没有）
        if not SE.actindex then
            SE.actindex = 1
        end
        
        -- 获取当前选中的行动
        local newact = SE.commands[SE.actindex]
        
        Player.sprite.x = ui.enemie_acttext[SE.actindex].x[1] - 25
        Player.sprite.y = ui.enemie_acttext[SE.actindex].y[1] + 15
        
        -- 列和行
        local col, row = 2, math.ceil(actionCount / 2)
        local OE = actionCount % 2 -- 判断奇偶,0为偶数,1为奇数
        if not (SE.newcol or SE.newrow) then
            SE.newcol, SE.newrow = 1, 1
        end         
        
        if actionCount > 1 then
            if Keyboard.getState("up") == 1 then
                if SE.newcol ~= col then
                    if SE.newrow > 1 then
                        SE.newrow = SE.newrow - 1
                    else
                        SE.newrow = row
                    end 
                    Audio.PlaySound("snd_menu_0.wav")
                else
                    if OE == 0 then
                        if SE.newrow > 1 then
                            SE.newrow = SE.newrow - 1
                        else
                            SE.newrow = row
                        end 
                        Audio.PlaySound("snd_menu_0.wav")
                    end
                end
            end
            
            if Keyboard.getState("down") == 1 then
                if SE.newcol ~= col then
                    if SE.newrow < row then
                        SE.newrow = SE.newrow + 1
                    else
                        SE.newrow = 1
                    end 
                    Audio.PlaySound("snd_menu_0.wav")
                else
                    if OE == 0 then
                        if SE.newrow < row then
                            SE.newrow = SE.newrow + 1
                        else
                            SE.newrow = 1
                        end 
                        Audio.PlaySound("snd_menu_0.wav")
                    end
                end
            end
            
            if Keyboard.getState("left") == 1 then                
                if SE.newrow ~= row then
                    if SE.newcol > 1 then
                        SE.newcol = SE.newcol - 1
                    else
                        SE.newcol = col
                    end 
                    Audio.PlaySound("snd_menu_0.wav")
                else
                    if OE == 0 then
                        if SE.newcol > 1 then
                            SE.newcol = SE.newcol - 1
                        else
                            SE.newcol = col
                        end
                        Audio.PlaySound("snd_menu_0.wav")
                    end
                end
            end
            
            if Keyboard.getState("right") == 1 then        
                if SE.newrow ~= row then
                    if SE.newcol < col then
                        SE.newcol = SE.newcol + 1
                    else
                        SE.newcol = 1
                    end 
                    Audio.PlaySound("snd_menu_0.wav")
                else
                    if OE == 0 then
                        if SE.newcol < col then
                            SE.newcol = SE.newcol + 1
                        else
                            SE.newcol = 1
                        end
                        Audio.PlaySound("snd_menu_0.wav")
                    end
                end
            end
            
            SE.actindex = (SE.newrow - 1) * 2 + SE.newcol
        end
        -- 确认键（Z键）：选择当前行动
        if Keyboard.getState("z") == 1 then
            ui.Selectedenemie = nil
            local selectedAction = SE.commands[SE.actindex]
            Audio.PlaySound("snd_menu_1.wav")
            Player.sprite.hide = true
            
            -- 执行选择的行动
            battle.HandleActions(SE.name, newact, SE)
            
            -- 删除文本
            ui.ClearTexts(ui.enemie_text)
            ui.ClearTexts(ui.enemie_acttext)
            
            -- 对话
            STATE("DIALOGRESULT")
            
        -- 取消键（X键）：返回敌人选择
        elseif Keyboard.getState("x") == 1 then  
            -- 清除行动菜单文本
            for i = #ui.enemie_acttext, 1, -1 do
                ui.enemie_acttext[i]:Remove()
            end
            ui.enemie_acttext = {}
            
            for i = #ui.enemie_text, 1, -1 do
                ui.enemie_text[i].hide = false
            end
            
            -- 返回敌人选择菜单
            STATE("ENEMYSELECT")
        end
    end
end

return ACTMENU