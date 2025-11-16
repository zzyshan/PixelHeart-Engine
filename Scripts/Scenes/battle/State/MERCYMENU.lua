local MERCYMENU = {
    text = {},
    mercyindex = 1
}

function MERCYMENU.init()
    MERCYMENU.iscanenemie = false
    local sparetext = typer.Print("[size:28]* Spare", {100, 270}, 3)
    sparetext.state = "spare"
    table.insert(MERCYMENU.text, sparetext)
    if battle.canflee then
        local fleetext = typer.Print("[size:28]* Flee", {100, 302}, 3)
        fleetext.state = "flee"
        table.insert(MERCYMENU.text, fleetext)
    end
    for _, enemie in ipairs(battle.enemies) do
        if enemie.data.canspare then
            MERCYMENU.text[1].color.b = 0
            MERCYMENU.text[1]:Reparse()
            MERCYMENU.iscanenemie = true
            break
        end
    end
end

function MERCYMENU.update(ui)
    local MM = MERCYMENU 
    local newmercy = MERCYMENU.text[MM.mercyindex]
    
    Player.sprite.x = newmercy.x - 25
    Player.sprite.y = newmercy.y + 15
    
    if input.getKeyState("up") == 1 and #MERCYMENU.text > 1 then
        if MM.mercyindex > 1 then
            MM.mercyindex = MM.mercyindex - 1
            Audio.PlaySound("snd_menu_0.wav")
        else
            MM.mercyindex = #MM.text
            Audio.PlaySound("snd_menu_0.wav")
        end
    elseif input.getKeyState("down") == 1 and #MERCYMENU.text > 1 then
        if MM.mercyindex < #MM.text then
            MM.mercyindex = MM.mercyindex + 1
            Audio.PlaySound("snd_menu_0.wav")
        else
            MM.mercyindex = 1
            Audio.PlaySound("snd_menu_0.wav")
        end
    end
    
    if input.getKeyState("z") == 1 then
        if newmercy.state == "spare" then
            if MM.iscanenemie then
                for i = #battle.enemies, 1, -1 do
                    local enemie = battle.enemies[i].data
                    if enemie.canspare then
                        for _, sprite in pairs(enemie.sprites or {}) do
                            sprite.alpha = 0.5
                            sprite:StopAnimation()
                        end
                        table.remove(battle.enemies, i)
                        battle.spareenemie = battle.spareenemie + 1
                    end
                end
                if battle.allenemy - battle.spareenemie > 0 then
                    ui.ClearTexts(MM.text)
                    STATE("DEFENDING")
                    battle.HandleSpare()
                else
                    Player.sprite.hide = true
                    ui.ClearTexts(MM.text)
                    STATE("NONE")
                    local tab = battle.wintext or {"[char_spacing:0]* YOU WEN!\n* You earned " .. battle.allexp .. " XP and " .. battle.allgold .. " gold."}
                    tab[#tab + 1] = "[skip][nextpage]"
                    local t = typer.New(tab, {60, 270}, 3, {voice = "uifont.wav"})
                    t.mode = "manual"
                    t.over = function()
                        STATE("WIN")
                    end
                end
                Audio.PlaySound("SeaTea.wav")
            else
                ui.ClearTexts(MM.text)
                STATE("ACTIONSELECT")
            end
        elseif newmercy.state == "flee" then
            Audio.PlaySound("snd_flee.wav")
            ui.ClearTexts(MERCYMENU.text)
            if math.random() < (battle.Escapeprobability or 0.5) then
                ui.runtime = 0
                Player.sprite:SetAnimation({"ui/spr_heartgtfo_0.png", "ui/spr_heartgtfo_1.png"}, 0.15)
                local runtext = typer.New("[skip]* Run away...", {100, 270}, 3, {voice = "uifont.wav"})
                runtext:SetScale(28)
                STATE("RUNAWAY")
            end
        end
    end
    
    if input.getKeyState("x") == 1 then
        ui.ClearTexts(MERCYMENU.text)
        STATE("ACTIONSELECT")
    end
end

return MERCYMENU