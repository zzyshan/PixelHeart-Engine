local inventory = save.GetVariable("player.inventory", 1) -- 物品栏数据文件

local spawnmenu = false
local timeoffset = 0
local menu = {
    texts = {},
    menutable = {"物品", "状态", "电话"},
    page = 0
}

-- 主要更新函数
function menu.update()
    if Player.canmove then
        if Keyboard.getState("c") == 1 then
            Audio.PlaySound("snd_menu_0.wav")
            Player.canmove = false
            spawnmenu = true
            menu.page = 1
            
            if (Player.sprite.y >= 240) then
                menu.main = image.CreateImage("overworld/Menu/menu_up.png", {120, 300}, 3)
                menu.heart = image.CreateImage("overworld/Menu/ut-heart.png", {90, 275}, 4, {r = 1, g = 0, b = 0})
                menu.texts.name = typer.CreateText({"[instant]" .. Player.Name}, {75, 400}, "Determination.ttf", nil, nil, 4)
                menu.detail = typer.CreateText({"[novoice][instant]LV " .. Player.Lv .. "\nHP " .. Player.Hp .. "/" .. Player.maxhp .. "\nG " .. Player.gold}, {70, 370}, "Crypt Of Tomorrow.ttf", nil, nil, 4)
                for i = 1, #menu.menutable do
                    local option = menu.menutable[i]
                    menu.texts[option] = typer.CreateText({"[instant]" .. option}, {125, 275 + 20 * i}, "Determination.ttf", nil, nil, 4)
                end
            else       
                menu.main = image.CreateImage("overworld/Menu/menu_up.png", {120, 180}, 3)
                menu.heart = image.CreateImage("overworld/Menu/ut-heart.png", {90, 275}, 4, {r = 1, g = 0, b = 0})
                
                menu.texts.name = typer.CreateText({"[instant]" .. Player.Name}, {75, 125}, "Determination.ttf", nil, nil, 4)
                menu.detail = typer.CreateText({"[novoice][instant]LV " .. Player.Lv .. "\nHP " .. Player.Hp .. "/" .. Player.maxhp .. "\nG " .. Player.gold}, {70, 75}, "Crypt Of Tomorrow.ttf", nil, nil, 4)
                for i = 1, #menu.menutable do
                    local option = menu.menutable[i]
                    menu.texts[option] = typer.CreateText({"[instant]" .. option}, {125, 275 + 20 * i}, "Determination.ttf", nil, nil, 4)
                end
            end
        end
    end
end

return menu