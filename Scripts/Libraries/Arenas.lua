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

function Arena_function:update(dt)
    self.white.angle = mathlib.smooth(self.white.angle,self.angle, self.speed or 15)
    self.black.angle = mathlib.smooth(self.black.angle,self.angle, self.speed or 15)
    self.white.scale.x = mathlib.smooth(self.white.scale.x, self.width + 10, self.speed or 15)
    self.white.scale.y = mathlib.smooth(self.white.scale.y, self.height + 10, self.speed or 15)
    self.black.scale.x = mathlib.smooth(self.black.scale.x, self.width, self.speed or 15)
    self.black.scale.y = mathlib.smooth(self.black.scale.y, self.height, self.speed or 15)
    self.white:MoveTo(mathlib.smooth(self.white.x, self.x, self.speed or 15), mathlib.smooth(self.white.y, self.y, self.speed or 15))
    self.black:MoveTo(mathlib.smooth(self.black.x, self.x, self.speed or 15), mathlib.smooth(self.black.y, self.y, self.speed or 15))
    
    if not self.isactive then return end
    if self.mode == "plus" then
        if self.shape == "rectangle" then
            local black = self.black
            local r = math.rad(self.angle)
            local w, h = self.width, self.height
            local sin, cos = math.sin(r), math.cos(r)
            local dx = (Player.sprite.x - black.x)
            local dy = (Player.sprite.y - black.y)
            
            if dx * cos + dy * sin >= -w / 2 + 8 and dx * cos + dy * sin <= w / 2 -8 and
              dy * cos - dx * sin >= h / 2 - 8 and dy * cos - dx * sin <= -h / 2 + 8 then
                self.containing = true
            else
                self.containing = false
            end
            
            if check_amount() <= 1 and check_nearest() == self then
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
            
            local Player_soul = Player.soul.mode
            local Player_cos, Player_sin = math.cos(math.rad(Player.sprite.angle)), math.sin(math.rad(Player.sprite.angle))
            local targetX = Player.sprite.x - (1 * Player_sin)
            local targetY = Player.sprite.y + (1 * Player_cos)
            
            dx = targetX - black.x
            dy = targetY - black.y
            
            if (dx * cos + dy * sin >= -w / 2 + 8 and dx * cos + dy * sin <= w / 2 - 8 and
                        dx * -sin + dy * cos >= -h / 2 + 8 and dx * -sin + dy * cos <= h / 2 - 8
                    ) then
                if Player_soul.name == "bluesoul" then
                    Player_soul.var.canjump = false
                end
            else
                if Player_soul.name == "bluesoul" then
                    Player_soul.var.canjump = true
                end
            end
        end
    end
end

function Arenas.update(dt)
    for _, arena in ipairs(Arenas.arenas) do
        if arena then
            arena:update(dt)
        end
    end
end

return Arenas