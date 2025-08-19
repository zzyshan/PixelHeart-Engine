local Sprites = {
    Cache = {},
    Shaders = {}
}

local function Findindex(sprite, table)
    local index
    for _, obj in ipairs(table) do
        if obj == sprite then
            index = _
        end
    end
    return index
end

-------- 方法 --------------
local Image_function = {
    Set = function(sprite, Spr)
        local path = "Sprites/"..Spr
        if sprite.spr ~= path then
            sprite.spr = path
            if not Sprites.Cache[Spr] then
                Sprites.Preload({Spr})
            end
            sprite.obj = Sprites.Cache[Spr]    
        end
    end,
    
    MoveTo = function(sprite, x, y)
        sprite.x = x
        sprite.y = y
    end,
    
    Move = function(sprite, xspeed, yspeed)
        sprite.x = sprite.x + xspeed
        sprite.y = sprite.y + yspeed
    end,
    
    SetScale = function(sprite, xscale, yscale)
        sprite.scale.x = xscale
        sprite.scale.y = yscale
    end,
    
    getWidth = function(sprite)
        return sprite.obj:getWidth() * (sprite.scale.x or 1)
    end,
    
    getHeight = function(sprite)
        return sprite.obj:getHeight() * (sprite.scale.y or 1)
    end,
    
    SetPivot = function(sprite, xpivot, ypivot)
        sprite.pivot.x = math.min(math.abs(xpivot), 1)
        sprite.pivot.y = math.min(math.abs(ypivot), 1)
    end,
    
    SetColor = function(sprite, r, g, b)
        sprite.color.r = r
        sprite.color.g = g
        sprite.color.b = b
    end,
    
    SetAlpha = function(sprite, a)
        sprite.alpha = a
    end,
    
    SetSkew = function(sprite, xSkew, ySkew)
        sprite.Skew.x = xSkew
        sprite.Skew.y = ySkew
    end,
    
    Hide = function(sprite, is)
        sprite.hide = is or false
    end,
    
    SetAnimation = function(sprite, anim, animspeed)
        sprite.anim.animtime = 1
        sprite.anim.animindex = 1
        sprite.anim.animtable = anim or {}
        sprite.anim.animspeed = animspeed or 1
    end,
    
    StopAnimation = function(sprite)
        sprite.anim.animtable = {}
        sprite.anim.animtime = 1
        sprite.anim.animindex = 1
        sprite.anim.animspeed = 0
    end,
    
    SetStencils = function(sprite, stencils)
        sprite.stencils.use = true
        sprite.stencils.masks = stencils or {}
        if (#sprite.stencils.masks == 0) then
            sprite.stencils.use = false
        end
    end,
    
    allTop = function(sprite, is)
        local index
        local Location
        local manual, Top = layers.objects.manual, layers.objects.allTop
        for _, obj in ipairs(manual) do
            if obj == sprite then
                Location = "manual"
            else
                Location = "allTop"
            end
        end
        if Location == "manual" then
            if is then
                index = Findindex(sprite, manual)
                table.move(manual, index, index, #Top + 1, Top)
                table.remove(manual, index)
            end
        elseif Location == "allTop" then
            if not is then
                index = Findindex(sprite, Top)
                table.move(Top, index, index, #manual + 1, manual)
                table.remove(Top, index)
            end
        end
    end,
    
    SetShader = function(sprite, shader, uniforms)
        if type(shader) == "string" then
            -- 从文件加载Shader
            sprite.shader = love.graphics.newShader("Scripts/Shaders/" .. shader)
        else
            -- 直接使用Shader对象
            sprite.shader = shader
        end
        
        sprite.shaderUniforms = uniforms or {}
        
        sprite.shaderEnabled = true
    end,
    -- 移除Shader
    RemoveShader = function(sprite)
        sprite.shader = nil
        sprite.shaderUniforms = {}
        sprite.shaderEnabled = false
    end,
    -- 设置Shader参数
    SetShaderUniforms = function(sprite, uniforms)
        for name, value in pairs(uniforms) do
            sprite.shader.Uniforms[name] = value
        end
    end,
    -- 启用/禁用Shader
    EnableShader = function(sprite, enable)
        sprite.shaderEnabled = enable
    end,
    -- 添加动态参数更新器
    AddShaderParamUpdater = function(sprite, name, updater)
        if not sprite.shader.Updaters then
            sprite.shader.Updaters = {}
        end
        sprite.shader.Updaters[name] = updater
    end,
    -- 移除参数更新器
    RemoveShaderParamUpdater = function(sprite, name)
        if sprite.shader.Updaters then
            sprite.shader.Updaters[name] = nil
        end
    end,
    Remove = function(sprite)
        sprite.remove = true
        for i = #layers.objects.manual, 1, -1 do
            if layers.objects.manual[i] == sprite then
                table.remove(layers.objects.manual, i)
                break
            end
        end
    end
}

----------- end -----------------

Image_function.__index=Image_function

--创建sprite
function Sprites.New(Spr, position, depth, settings)
    local spr = "Sprites/" .. Spr
    local setting = settings or {}
    
    if not Sprites.Cache[Spr] then
        Sprites.Preload({Spr})
    end
    
    local obj = Sprites.Cache[Spr] or love.graphics.newImage(spr)
    local sprite = setmetatable({
        spr = spr,
        obj = obj,
        x = position[1] or 320,
        y = position[2] or 240,
        angle = setting.angle or 0,
        alpha = setting.alpha or 1,
        scale = {x = setting.xscale or 1, y = setting.yscale or 1},
        color = {
            r = setting.r or 1,
            g = setting.g or 1,
            b = setting.b or 1
        },
        Skew = {x = setting.xSkew or 0, y = setting.xSkew or 0},
        pivot = {x = setting.xpivot or 0.5, y = setting.ypivot or 0.5},
        xspeed = setting.xspeed,
        yspeed = setting.xspeed,
        remove = false,
        hide = false,
        depth = depth or 1,
        anim = {
            animtable = nil,
            animtime = nil,
            animindex = nil,
            animspeed = nil,
            animmode = "loop"
        },
        shader = {
            obj = nil,-- 使用的Shader对象
            Uniforms = {},--Shader参数表
            Enabled = false--是否启用Shader
        },
        stencils = {
            use = false,
            masks = {}
        },
        Createtime = love.timer.getTime(),
        type = "sprite"
    },Image_function)
    
    --------- update和draw方法 ------------
    function sprite:update(dt)
        if self.remove then return end
        
        local anim = self.anim
        if anim.animtable and next(anim.animtable) then
            anim.animtime = anim.animtime + dt
            
            if anim.animtime >= anim.animspeed then
                anim.animindex = anim.animindex + 1
                
                if anim.animindex > #anim.animtable then
                    if anim.animmode == "loop" then
                        anim.animindex = 1
                    elseif anim.animmode == "oneshot" then
                        self:StopAnimation()
                    elseif anim.animmode == "oneshotempty" then
                        self:Remove()
                    end
                end
                
                if anim.animindex <= #anim.animtable then
                    self:Set(anim.animtable[anim.animindex])
                    anim.animtime = 0
                end
            end
        end
        
        self.x = self.x + (self.xspeed or 0) * dt
        self.y = self.y + (self.yspeed or 0) * dt
        
        -- 更新动态参数
        if self.shader.Updaters then
            for name, updater in pairs(self.shader.Updaters) do
                self.shader.Uniforms[name] = updater(dt)
            end
        end
    end
    
    function sprite:draw()        
        -- Shader 处理
        local shader = self.shader
        if shader.obj and shader.Enabled then
            if shader.obj then
                love.graphics.setShader(shader.obj)
                for name, value in pairs(shader.Uniforms) do
                    shader.obj:send(name, value)
                end
            end
        end
        
        if (self.stencils.use) then
            love.graphics.clear(false, false, true, 0)
            masks.draw(self.stencils.masks)
            love.graphics.setStencilTest("greater", 0)
        end
        
        -- 绘制逻辑
        if not self.hide then
            love.graphics.setColor(
                self.color.r or 1,
                self.color.g or 1,
                self.color.b or 1,
                self.alpha or 1
            )
            
            love.graphics.draw(
                self.obj,
                self.x, self.y,
                math.rad(self.angle or 0),
                self.scale.x,
                self.scale.y,
                self.obj:getWidth() * (self.pivot.x or 0.5),
                self.obj:getHeight() * (self.pivot.y or 0.5),
                self.Skew.x, self.Skew.y
            )
        end
        
        masks.reset()
        love.graphics.setShader()
        love.graphics.setColor(1, 1, 1, 1)
    end
    --------- end ----------------**--*---
    
    table.insert(layers.objects.manual,sprite)
    return sprite
end

function Sprites.allupdate(dt)
    for _, sprite in ipairs(layers.objects.manual) do
        if not sprite.remove and sprite.type == "sprite" then
            sprite:update(dt)
        end
    end
    
    if #layers.objects.allTop <= 1 then return end
    for _, sprite in ipairs(layers.objects.allTop) do
        if not sprite.remove and sprite.type == "sprite" then
            sprite:update(dt)
        end
    end
end

--预加载图片
function Sprites.Preload(spritePaths)
    for _, path in ipairs(spritePaths) do
        Sprites.Cache[path] = love.graphics.newImage("Sprites/"..path)
        Sprites.Cache[path]:setFilter("nearest", "nearest")
    end
end

function Sprites.Unload(spritePaths)
    for _, path in ipairs(spritePaths) do
        if Sprites.Cache[path] then
            Sprites.Cache[path]:release()
            Sprites.Cache[path] = nil
        end
    end
end

-- 预加载Shader
function Sprites.LoadShader(name, vsPath, fsPath)
    local vs, fs
    local path = "Scripts/Shaders/"
    
    if vsPath then
        vs = love.filesystem.read(path .. vsPath)
    end
    
    if fsPath then
        fs = love.filesystem.read(path .. fsPath)
    end
    
    Sprites.Shaders[name] = love.graphics.newShader(vs, fs)
    return Sprites.Shaders[name]
end

-- 获取Shader
function Sprites.GetShader(name)
    return Sprites.Shaders[name]
end

-- 清除所有Shader
function Sprites.ClearShaders()
    for _, shader in pairs(Sprites.Shaders) do
        shader:release()
    end
    Sprites.Shaders = {}
end

function Sprites.clear()
    for i = #layers.objects.manual, 1, -1 do
        local obj = layers.objects.manual[i]
        if not obj.remove and obj.type == "sprite" then
            obj:Remove()
        end
    end
end

function Sprites.bulletclear()
    for i = #layers.objects.manual, 1, -1 do
        local obj = layers.objects.manual[i]
        if not obj.remove and obj.type == "sprite" and obj.isbullet then
            obj:Remove()
        end
    end
end

return Sprites