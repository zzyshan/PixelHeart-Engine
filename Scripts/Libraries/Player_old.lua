local path = "overworld/Character/"
local Player = {
    canmove = true,
    ismove = false,
    speed = 180
}

function Player.init()
    Player.Name = save.GetVariable("player.name", 1) or "Player"
    Player.Hp = save.GetVariable("player.hp", 1) or 20
    Player.maxhp = save.GetVariable("player.maxhp", 1) or 20
    Player.Lv = save.GetVariable("player.lv", 1) or 1
    Player.gold = save.GetVariable("player.gold", 1) or 0
    Player.inventory = save.GetVariable("player.inventory", 1) or {}
    
    if scenes.Gettype() == "Overworld" then
        -- 初始化overworld状态
        Player.overworld = {
            direction = "down",
            anim = 0,
            animTimer = 0,
            animSpeed = 0.1,
            lastDirection = nil,
            isblock = {
                up = false, down = false,
                left = false, right = false
            },
            lastAnim = nil
        }
    elseif scenes.Gettype() == "battle" then
        Player.battle = {}
    end
end

function Player.load(x, y)
    if scenes.Gettype() == "Overworld" then
        local Player_ow = Player.overworld
        Player.sprite = Sprites.New(path..Player_ow.direction.."_0.png", {x, y}, 2)
        Player_ow.lastDirection = Player_ow.direction
        Player_ow.lastAnim = Player_ow.anim
    elseif scenes.Gettype() == "battle" then
        Player.sprite = Sprites.New("ui/Player.png", {x, y}, 3)
        Player.sprite:SetColor(1, 0, 0)
    end
end

function Player.place(landmark)
    if scenes.Gettype() ~= "Overworld" then return end
    if landmark and landmark.x and landmark.y then
        Player.sprite.x = landmark.x
        Player.sprite.y = landmark.y
    else
        -- 提供默认位置
        Player.sprite.x = 320
        Player.sprite.y = 240
        print("Warning: Invalid landmark provided, using default position")
    end
end

function Player.Hurt(damage, time, isplaysound)
    if Player.Hp - damage > 0 then
        Player.Hp = Player.Hp - damage
        Player.hurtingtime = time or 1
        Player.hurting = true
    else
        Player.Hp = 0
    end
    
    local sound = isplaysound or true
    if sound then
        Audio.PlaySound("snd_phurt.wav")
    end
end

local function updatebattle(dt)
    if Player.sprite and Player.battle then
        Player.battle.box = {
            Width = 4,
            Height = 4
        }
    end
    
    if Keyboard.getState("x") > 0 then
        Player.speed = 90
    else
        Player.speed = 180
    end
    
    if Keyboard.getState("up", "w") > 0 and Player.canmove then
        Player.sprite:Move(0, -(Player.speed * dt))
        Player.ismove = true
    end
    if Keyboard.getState("down", "s") > 0 and Player.canmove then
        Player.sprite:Move(0, (Player.speed * dt))
        Player.ismove = true
    end
    if Keyboard.getState("left", "a") > 0 and Player.canmove then
        Player.sprite:Move(-(Player.speed * dt), 0)
        Player.ismove = true
    end
    if Keyboard.getState("right", "d") > 0 and Player.canmove then
        Player.sprite:Move((Player.speed * dt), 0)
        Player.ismove = true
    end
end

local function updateoverworld(dt)
    local Player_ow = Player.overworld
    if (Player_ow.direction ~= Player_ow.lastDirection or Player_ow.anim ~= Player_ow.lastAnim) then
        Player.sprite:Set(path..Player_ow.direction.."_"..Player_ow.anim..".png")
        Player_ow.lastDirection = Player_ow.direction
        Player_ow.lastAnim = Player_ow.anim
    end
    local moveX, moveY = 0, 0
    local isMoving = false
    
    -- 输入处理（带碰撞检测）
    if Keyboard.getState("up", "w") > 0 and Player.canmove then
        moveY = -1
        Player_ow.direction = "up"
        isMoving = true
    elseif Keyboard.getState("down", "s") > 0 and Player.canmove then
        moveY = 1
        Player_ow.direction = "down"
        isMoving = true
    end
    
    if Keyboard.getState("left", "a") > 0 and Player.canmove then
        moveX = -1
        Player_ow.direction = "left"
        isMoving = true
    elseif Keyboard.getState("right", "d") > 0 and Player.canmove then
        moveX = 1
        Player_ow.direction = "right"
        isMoving = true
    end
    
    -- 移动和动画
    if isMoving and Player.canmove then
        -- 标准化对角线移动
        if moveX ~= 0 and moveY ~= 0 then
            moveX, moveY = moveX * 0.707, moveY * 0.707  -- 1/sqrt(2)
        end
        
        Player.sprite.x = Player.sprite.x + moveX * Player.speed * dt
        Player.sprite.y = Player.sprite.y + moveY * Player.speed * dt
        
        -- 更新动画（除非碰到障碍物）
        if true then
            Player_ow.animTimer = Player_ow.animTimer + dt
            if Player_ow.animTimer >= Player_ow.animSpeed then
                Player_ow.anim = (Player_ow.anim + 1) % 4
                Player_ow.animTimer = 0
            end
        else
            Player_ow.anim = 0
        end
    else
        Player_ow.anim = 0  -- 静止时回到第一帧
    end
end

function Player.update(dt)
    if scenes.Gettype() == "Overworld" then
        updateoverworld(dt)
    elseif scenes.Gettype() == "battle" then
        updatebattle(dt)
    end
    
    if Player.hurting then
        Player.hurtingtime = Player.hurtingtime - dt
        if Player.hurtingtime <= 0 then
            Player.hurting = false
            Player.hurtingtime = 0
        end
    end
end

function Player.DEBUG()
    local box = Player.battle.box
    love.graphics.rectangle("line", 
        Player.sprite.x - box.Width/2,
        Player.sprite.y - box.Height/2, 
        box.Width, 
        box.Height)
end

return Player