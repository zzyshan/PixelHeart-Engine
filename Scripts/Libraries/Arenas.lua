local Arenas = {
    arenas = {}
}

local function check_amount()
    local amount = 0
    for _, Arena in ipairs(Arenas.arenas) do
        if (Arenas.containing) then
            amount = amount + 1
        end
    end
    return amount
end

--这个函数是直接从end那里搬过来
local function check_nearest()
    local distance = math.huge
    local nearest

    for i = 1, #Arenas.arenas do
        local shell = Arenas.arenas[i]
        if (shell.isactive and shell.mode == "plus") then
            if (shell.shape == "rectangle") then
                local dx, dy = Player.sprite.x - shell.black.x, Player.sprite.y - shell.black.y
                local a = math.rad(shell.black.angle)
                local sin, cos = math.sin(a), math.cos(a)
                local w, h = shell.width, shell.height
                local vx, vy = 0, 0

                vx = mathlib.clamp(dx * cos + dy * sin, -w / 2 + 8, w / 2 - 8)
                vy = mathlib.clamp(dy * cos - dx * sin, -h / 2 + 8, h / 2 - 8)

                local dist = math.sqrt(math.pow(vx - (dx * cos + dy * sin), 2) + math.pow(vy - (dy * cos - dx * sin), 2))
                if (dist < distance) then
                    distance = dist
                    nearest = shell
                end
            elseif (shell.shape == "circle") then
                local dx, dy = Player.sprite.x - shell.black.x, Player.sprite.y - shell.black.y
                local a = math.rad(shell.black.angle)
                local sin, cos = math.sin(a), math.cos(a)
                local w, h = shell.width, shell.height
                local a, b = w / 2 - 8, h / 2 - 8
                local rx, ry = dx * cos + dy * sin, dy * cos - dx * sin
                local vx, vy = 0, 0

                local relangle = mathlib.angle(shell.black.x, shell.black.y, Player.sprite.x, Player.sprite.y, 0)
                local nsin, ncos = math.cos(math.rad(relangle)), math.sin(math.rad(relangle))
                vx = mathlib.clamp(rx, -a * ncos, a * ncos)
                vy = mathlib.clamp(ry, -b * nsin, b * nsin)
                local dist = math.sqrt(math.pow(vx - rx, 2) + math.pow(vy - ry, 2))
                if (dist < distance) then
                    distance = dist
                    nearest = shell
                end
            end
        end
    end

    return nearest
end

local Arena_function = {
    update = function(Arena, dt)
        Arena.white.angle = mathlib.smooth(Arena.white.angle,Arena.angle, Arena.speed or 15)
        Arena.black.angle = mathlib.smooth(Arena.black.angle,Arena.angle, Arena.speed or 15)
        Arena.white.scale.x = mathlib.smooth(Arena.white.scale.x, Arena.width + 10, Arena.speed or 15)
        Arena.white.scale.y = mathlib.smooth(Arena.white.scale.y, Arena.height + 10, Arena.speed or 15)
        Arena.black.scale.x = mathlib.smooth(Arena.black.scale.x, Arena.width, Arena.speed or 15)
        Arena.black.scale.y = mathlib.smooth(Arena.black.scale.y, Arena.height, Arena.speed or 15)
        Arena.white:MoveTo(mathlib.smooth(Arena.white.x, Arena.x, Arena.speed or 15), mathlib.smooth(Arena.white.y, Arena.y, Arena.speed or 15))
        Arena.black:MoveTo(mathlib.smooth(Arena.black.x, Arena.x, Arena.speed or 15), mathlib.smooth(Arena.black.y, Arena.y, Arena.speed or 15))
        
        if not Arena.isactive then return end
        if Arena.mode == "plus" then
            if Arena.shape == "rectangle" then
                local black = Arena.black
                local r = math.rad(Arena.angle)
                local w, h = Arena.width, Arena.height
                local sin, cos = math.sin(r), math.cos(r)
                local X = (Player.sprite.x - black.x) * cos + (Player.sprite.y - black.y) * sin
                local Y = (Player.sprite.y - black.y) * cos - (Player.sprite.x - black.x) * sin
                
                if X >= -w / 2 + 8 and X <= w / 2 -8 and
                  Y >= h / 2 - 8 and Y <= -h / 2 + 8 then
                    Arena.containing = true
                else
                    Arena.containing = false
                end
                
                if check_amount() <= 1 and check_nearest() == Arena then
                    local Player = Player.sprite
                    -- right
                    while ((Player.x - black.x) * cos + (Player.y - black.y) * sin > w / 2 - 8) do
                        Player:Move(-cos, -sin)
                    end
                    -- left
                    while ((Player.x - black.x) * cos + (Player.y - black.y) * sin < -w / 2 + 8) do
                        Player:Move(cos, sin)
                    end
                    -- up
                    while ((Player.y - black.y) * cos + (Player.x - black.x) * -sin < -h / 2 + 8) do
                        Player:Move(-sin, cos)
                    end
                    -- down
                    while ((Player.y - black.y) * cos + (Player.x - black.x) * -sin > h / 2 - 8) do
                         Player:Move(sin, -cos)
                    end
                end
            end
        end
    end,
    Resize = function(Arena, width, height, speed)
        local w = (width >= 16) and width or 16
        local h = (height >= 16) and height or 16
        Arena.speed = speed
        Arena.width = w
        Arena.height = h
    end,
    MoveTo = function(Arena, x, y, speed)
        Arena.speed = speed
        Arena.x = x
        Arena.y = y
    end,
    MoveToAndResize = function(Arena, x, y, width, height, speed)
        Arena:MoveTo(x, y)
        Arena:Resize(width, height)
    end,
    RotateTo = function(Arena, angle, speed)
        Arena.speed = speed
        Arena.angle = angle
    end,
    Remove = function(Arena)
        for i = #Arenas.arenas, 1, -1 do
            if (Arenas.arenas[i] == Arena) then
                Arenas.arenas = Arenas.arenas[i]
                Arena.isactive = false
                Arena.iscolliding = false
                Arena.white:Remove()
                Arena.black:Remove()
                table.remove(Arenas.arenas, i)
            end
        end
    end
    
}

Arena_function.__index = Arena_function

function Arenas.new(position, w, h, r, shape, mode)
    Arena = setmetatable({
        isactive = true,
        iscolliding = true,
        containing = true,
        shape = shape or "rectangle",
        mode = mode or "plus",
        x = position[1],
        y = position[2],
        width = w,
        height = h,
        angle = r,
        speed = nil
    }, Arena_function)
    Arena.white = Sprites.New("Shapes/" .. shape .. ".png", position, 1.5)
    Arena.white:SetScale((w + 10), (h + 10))
    Arena.white.angle = r
    Arena.black = Sprites.New("Shapes/" .. shape .. ".png", position, 2)
    Arena.black:SetScale(w, h)
    Arena.black.angle = r
    Arena.black:SetColor(0, 0, 0)
    
    table.insert(Arenas.arenas, Arena)
    return Arena
end

function Arenas.update(dt)
    for _, arena in ipairs(Arenas.arenas) do
        if arena then
            arena:update(dt)
        end
    end
end

return Arenas