local menu = {
    State = {"ITEM", "STAT", "CELL"},
    Stateindex = 1,
    isopen = false,
    
    box = {},
    box_text = {}
}

local Camera = Camera.NewCamera
local box, text = menu.box, menu.box_text

function menu.information()
    
end

function menu.Info(box)
    local menux, menuy = box.x - box:getWidth() * 0.5, box.y - box:getHeight() * 0.5
        
    text.name = typer.Print(Player.Name, {menux + 15, menuy + 10}, 3, {char_spacing = -2})
    text.lv = typer.Print("lv " .. Player.Lv, {menux + 16, menuy + 45}, 3, {font = "Crypt Of Tomorrow.ttf", size = 18})
    text.hp = typer.Print("hp " .. Player.Hp .. "/" .. Player.maxhp, {menux + 16, menuy + 65}, 3, {font = "Crypt Of Tomorrow.ttf", size = 18})
    text.G = typer.Print("G[offsetx:20]" .. Player.gold, {menux + 16, menuy + 85}, 3, {font = "Crypt Of Tomorrow.ttf", size = 18})
    
    local Interval = 0
    for _, char in pairs(menu.State) do
        text[char] = typer.Print(char, {menux + 48, menuy + 140 + Interval}, 3, {char_spacing = -2, size = 28})
        Interval = Interval + 35
    end
end

function menu.show()
    Player.canmove = false
    if Player.sprite.y <= Camera.y + 320 then
        box.menu_up = Sprites.New("Overworld/Menu/menu_up.png", {90, 180}, 3)
        
        menu.Info(box.menu_up)
    end
    
    menu.isopen = true
end

function menu:update()
    if not self.isopen then return end
end

function menu.clean()
    box = {}
    char = {}
end

return menu