local owpath = "overworld/Character/"
local path = "Scripts/Libraries/Player/"
local Player = {
    canmove = true,
    ismove = false,
    speed = 180
}

function Player.init(position, var)
    local var = var or {}
    Player.Name = Player.Name or save.GetVariable("player.name", 1) or "Player"
    Player.Hp = Player.Hp or save.GetVariable("player.hp", 1) or 20
    Player.maxhp = Player.maxhp or save.GetVariable("player.maxhp", 1) or 20
    Player.Lv = Player.Lv or save.GetVariable("player.lv", 1) or 1
    Player.gold = Player.gold or save.GetVariable("player.gold", 1) or 0
    Player.inventory = Player.inventory or save.GetVariable("player.inventory", 1) or {}
    
    if scenes.Gettype() == "Overworld" then
        Player.ow = require(path .. "ow/ow")
        -- 初始化overworld状态
        Player.overworld = {
            direction = var.direction or "down",
            anim = 0,
            animTimer = 0,
            animSpeed = 0.1,
            MainDirection = nil
        }
        
        if not global.GetVar("Player_ow_position") then
            global.SetVar("Player_ow_position", {320, 240})
        end
        
        local Player_ow = Player.overworld
        Player.sprite = Sprites.New("Overworld/Character/" .. Player_ow.direction.."_0.png", position or global.GetVar("Player_ow_position"), 2)
        Player.sprite:SetColor(1, 1, 1)
        
        Player_ow.body = love.physics.newBody(overworld.world, Player.sprite.x, Player.sprite.y, "dynamic")
        Player_ow.shape = love.physics.newRectangleShape(38, 20)
        Player_ow.fixture = love.physics.newFixture(Player_ow.body, Player_ow.shape)
        Player_ow.body:setFixedRotation(true)
        Player_ow.fixture:setRestitution(0)
        Player_ow.fixture:setFriction(0.1)
        Player_ow.fixture:setUserData({type = "Player"})
        
    elseif scenes.Gettype() == "battle" then
        Player.soul = require(path .. "soul/soul_init")
        
        Player.sprite = Sprites.New("ui/Player.png", position or {320, 240}, 3)
        local color = Player.soul.mode.color or {1, 1, 1}
        Player.sprite:SetColor(unpack(color))
    end
end

function Player.Hurt(damage, time, isplaysound)
    if Player.Hp - damage > 0 then
        Player.Hp = Player.Hp - damage
        Player.hurtingtime = time or 1
        Player.hurting = true
    else
        Player.Hp = 0
        Player.hurting = true
    end
    
    local sound = isplaysound or true
    if sound then
        Audio.PlaySound("snd_phurt.wav")
    end
end

function Player.update(dt)
    if scenes.Gettype() == "Overworld" and Player.ow then
        Player.ow.update(dt)
    elseif scenes.Gettype() == "battle" and Player.soul then
        Player.soul.update(dt)
    end
    
    if Player.hurting then
        Player.hurtingtime = Player.hurtingtime - dt
        if Player.hurtingtime <= 0 then
            Player.hurting = false
            Player.hurtingtime = 0
        end
    end
end

function Player.save()
    if scenes.Gettype() == "Overworld" then
        global.SetVar("Player_ow_position", {Player.sprite.x, Player.sprite.y})
    end
end

function Player.DEBUG()
    if scenes.Gettype() == "battle" then
        local soul = Player.soul
        love.graphics.rectangle("line", 
            Player.sprite.x - soul.box_w/2,
            Player.sprite.y - soul.box_h/2, 
            soul.box_w, 
            soul.box_h)
    end
end

return Player