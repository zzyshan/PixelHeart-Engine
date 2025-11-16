local typers = {
    func = {},
    Print_func = {}
}

local mt = { __index = typers.func }
local mt2 = { __index = typers.Print_func }

-- 状态常量
local STATE_IDLE = 0
local STATE_TYPING = 1
local STATE_WAITING = 2
local STATE_PAGE_END = 3
local STATE_FINISHED = 4

-- 字体缓存
local fontCache = {}

-- UTF-8字符长度计算
local function utf8CharLength(b)
    if not b then return 0 end
    return b > 239 and 4 or b > 223 and 3 or b > 127 and 2 or 1
end

-- 获取字符增量
local function getCharDelta(currentText, index)
    local b = string.byte(currentText, index)
    return utf8CharLength(b)
end

-- 获取字符
local function getChar(currentText, index)
    local b = string.byte(currentText, index)
    local delta = utf8CharLength(b)
    return currentText:sub(index, index + delta - 1), delta
end

-- 解析颜色值
local function parseColor(colorStr)
    local parts = {}
    for part in colorStr:gmatch("[^,]+") do
        table.insert(parts, tonumber(part))
    end
    return parts
end

-- 加载字体
local function loadFont(name, size)
    if not fontCache[name .. size] then
        local fontPath = "Sprites/Fonts/" .. name
        if love.filesystem.getInfo(fontPath) then
            fontCache[name .. size] = love.graphics.newFont(fontPath, size)
            fontCache[name .. size]:setFilter("nearest", "nearest")
        end
    end
end

function typers.CreateBubble(position, w, h, depth)
    local startX, endX = position[1] - w / 2, position[1] + w / 2
    local startY, endY = position[2] - h / 2, position[2] + h / 2
    local Bubble = {}
    
    Bubble.main_w = Sprites.New("px.png", position, depth, {xscale = w, yscale = h - 40})
    Bubble.main_h = Sprites.New("px.png", position, depth, {xscale = w - 40, yscale = h})
    Bubble.corner_lu = Sprites.New("Bubble/spr_bubblecorner.png", {startX, startY}, depth)
    Bubble.corner_ld = Sprites.New("Bubble/spr_bubblecorner.png", {startX, endY}, depth)
    Bubble.corner_ru = Sprites.New("Bubble/spr_bubblecorner.png", {endX, startY}, depth)
    Bubble.corner_rd = Sprites.New("Bubble/spr_bubblecorner.png", {endX, endY}, depth)
    Bubble.tail = Sprites.New("Bubble/spr_bubbletail.png", {startX, position[2]}, depth)
    
    Bubble.corner_ld.angle = 270
    Bubble.corner_ru.angle = 90
    Bubble.corner_rd.angle = 180
    
    Bubble.corner_lu:SetPivot(0, 0)
    Bubble.corner_ld:SetPivot(0, 0)
    Bubble.corner_ru:SetPivot(0, 0)
    Bubble.corner_rd:SetPivot(0, 0)
    Bubble.tail:SetPivot(0.5, 1)
    
    return Bubble
end

-- 创建打字机
function typers.New(text, position, depth, settings)
    local settings = settings or {}
    local self = setmetatable({}, mt)
    
    -- 基本属性
    self.text = type(text) == "table" and text or {text}
    self.page = 1
    self.x = {position[1] or 320}
    self.y = {position[2] or 240}
    self.char_x, self.char_y = settings.char_x or 0, settings.char_y or 0
    self.xchar_spacing, self.ychar_spacing = settings.xchar_spacing or 2, settings.ychar_spacing or 2
    self.size = settings.size or 28
    self.color = {r = settings.r or 1, g = settings.g or 1, b = settings.b or 1}
    self.alpha = settings.alpha or 1
    self.font = settings.font or "Determination.ttf"
    self.depth = depth or 0
    self.angle = {settings.angle or 0}
    self.voice = type(settings.voice) == "table" and settings.voice or {settings.voice}
    self.char = {}
    self.speed = settings.speed or 0.05
    self.sleep = settings.sleep or 0.05
    self.time = self.speed
    self.index = 1
    self.qie = 1
    self.T_STATE = STATE_TYPING
    self.type = "typer"
    self.effect = {name = nil, effectstrength = nil}
    self.offset = {}
    self.Createtime = love.timer.getTime()
    
    -- 控制属性
    self.noGlobal = nil
    self.mode = nil
    self.control = nil
    self.instant = false
    self.canskip = true
    self.remove = false
    self.hide = false
    
    loadFont(self.font, self.size)
    
    table.insert(layers.objects.manual, self)
    return self
end

-- 全局更新
function typers.allupdate(dt)
    for _, tpr in ipairs(layers.objects.manual) do
        if not tpr.remove and not tpr.noGlobal then
            tpr:update(dt)
        end
    end
    
    if #layers.objects.allTop <= 1 then return end
    for _, tpr in ipairs(layers.objects.allTop) do
        if not tpr.remove and not tpr.noGlobal then
            tpr:update(dt)
        end
    end
end

-- 全局输入处理
function typers.allPressed()
    for i = #layers.objects.manual, 1, -1 do
        local obj = layers.objects.manual[i]
        if not obj.remove and not obj.noGlobal and obj.Pressed and obj.type == "typer" then
            obj:Pressed()
        end
    end
end

-- 预加载字体
function typers.PreloadFont(fontPaths)
    for _, font in ipairs(fontPaths) do
        local fontPath = "Sprites/Fonts/" .. font.name
        local fontname = font.name .. font.size
        if love.filesystem.getInfo(fontPath) then
            fontCache[font.name] = love.graphics.newFont(fontPath, font.size)
            fontCache[font.name]:setFilter("nearest", "nearest")
        else
            print("WARNING: Preload font not found: "..fontPath)
        end
    end
end

-- 卸载字体
function typers.UnloadFont(fontpath)
    for _, font in ipairs(fontpath) do
        if fontCache[font] then
            fontCache[font]:release()
            fontCache[font] = nil
        end
    end
end

-- 清除所有打字机
function typers.clear()
    for i = #layers.objects.manual, 1, -1 do
        local tpr = layers.objects.manual[i]
        if not tpr.remove and (tpr.type == "typer" or tpr.type == "typer_Print") then
            tpr:Remove()
        end
    end
end

-- 更新打字机
function typers.func:update(dt)
    -- 确保属性是表
    if type(self.x) ~= "table" then self.x = {self.x} end
    if type(self.y) ~= "table" then self.y = {self.y} end
    if type(self.angle) ~= "table" then self.angle = {self.angle} end

    if self.remove or self.T_STATE == STATE_FINISHED then return end
    
    if self.T_STATE == STATE_TYPING then
        if self.instant then
            self:processInstantMode()
        else
            self:processNormalMode(dt)
        end
    end
end

-- 处理即时模式
function typers.func:processInstantMode()
    while self.T_STATE ~= STATE_FINISHED and self.instant do
        if self.T_STATE == STATE_PAGE_END then
            self.instant = false
            break
        end
        
        self:ProcessNextChar()

        -- 处理跳过计数
        if self.skipUnitsRemaining and self.skipUnitsRemaining > 0 then
            self.skipUnitsRemaining = self.skipUnitsRemaining - 1
            if self.skipUnitsRemaining <= 0 then
                self.skipUnitsRemaining = nil
                self.instant = false
                self.canskip = true
            end
        end

        -- 检查是否到达文本末尾
        local currentText = self.text[self.page]
        if self.index > #currentText then
            self.T_STATE = STATE_PAGE_END
            self.instant = false
            break
        end
    end
end

-- 处理普通模式
function typers.func:processNormalMode(dt)
    if self.T_STATE ~= STATE_PAGE_END then
        self.time = self.time + dt
        while self.time >= self.speed do
            self.speed = self.sleep
            self.time = 0
            self:ProcessNextChar()
            if self.T_STATE == STATE_PAGE_END or self.T_STATE == STATE_FINISHED then
                break
            end
        end
    end
end

-- 处理下一个字符
function typers.func:ProcessNextChar()
    local currentText = self.text[self.page]
    
    -- 检查是否到达文本末尾
    if self.index > #currentText then
        self.T_STATE = STATE_PAGE_END
        return
    end
    if self.page > #self.text then
        self.T_STATE = STATE_FINISHED
        return
    end

    local letter, delta = getChar(currentText, self.index)
    local font = fontCache[self.font .. self.size]
    local intervalX, intervalY = font:getWidth(letter), font:getHeight(letter)

    -- 处理特殊字符
    if letter == "\n" then
        self:handleNewline(intervalY)
        return
    elseif letter == " " then
        self:handleSpace(intervalX)
        return
    elseif letter == "[" then
        self:handleTag(currentText)
        return
    end

    -- 处理跳过模式
    if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
        self:handleSkipMode(currentText, delta, intervalX)
        return
    end

    -- 添加普通字符
    self:addChar(letter)
    
    -- 检查是否到达文本末尾
    if self.index > #currentText then
        self.T_STATE = STATE_PAGE_END
    end
end

-- 处理换行
function typers.func:handleNewline(intervalY)
    self.char_x = 0
    self.char_y = self.char_y + intervalY + self.ychar_spacing
    self.index = self.index + 1 -- 换行符只占一个字节
    
    -- 处理跳过模式
    if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
        self.unitsToSkip = self.unitsToSkip - 1
        if self.unitsToSkip <= 0 then
            self.unitsToSkip = nil
            self.instant = false
            self.canskip = true
        end
    end
end

-- 处理空格
function typers.func:handleSpace(intervalX)
    self.index = self.index + 1
    self.char_x = self.char_x + intervalX
    
    -- 处理跳过模式
    if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
        self.unitsToSkip = self.unitsToSkip - 1
        if self.unitsToSkip <= 0 then
            self.unitsToSkip = nil
            self.instant = false
            self.canskip = true
        end
    end
end

-- 处理标签
function typers.func:handleTag(currentText)
    local tagStart = self.index
    local tagEnd = currentText:find("]", tagStart)
    local stopaddindex
    if not tagEnd then
        self.index = self.index + 1
        return
    end
    
    local tagContent = currentText:sub(tagStart + 1, tagEnd - 1)
    local _, _, head, body = tagContent:find("^([%w/_]+):?(.*)$")
    
    if head then
        local attached = body ~= ""
        stopaddindex = self:processTag(head, body, attached)
    end

    if stopaddindex then return end
    self.index = tagEnd + 1
end

-- 处理跳过模式
function typers.func:handleSkipMode(currentText, delta, intervalX)
    self.index = self.index + delta
    self.char_x = self.char_x + intervalX + self.xchar_spacing

    self.unitsToSkip = self.unitsToSkip - 1
    if self.unitsToSkip <= 0 then
        self.unitsToSkip = nil
        self.instant = false
        self.canskip = true
    end
    
    -- 检查是否到达文本末尾
    if self.index > #currentText then
        self.T_STATE = STATE_PAGE_END
    end
end

-- 标签处理方法
function typers.func:processTag(head, body, attached)
    head = head:lower()  -- 统一转换为小写
    
    if attached then
        -- 处理带参数的标签
        if head == "color" then
            local color = parseColor(body)
            self:SetColor(color[1], color[2], color[3], false)
        elseif head == "alpha" then
            self:SetAlpha(tonumber(body))
        elseif head == "font" then
            self:SetFont(body)
        elseif head == "char_spacing" then
            self:SetxCharSpacing(tonumber(body))
        elseif head == "line_spacing" then
            self:SetyCharSpacing(tonumber(body))
        elseif head == "wait" then
            self.time = 0
            self.speed = tonumber(body)
        elseif head == "skip" then
            self:skip(tonumber(body))
        elseif head == "font_size" then
            self:SetScale(tonumber(body))
        elseif head == "speed" then
            self.sleep = tonumber(body)
        elseif head == "offsetx" then
            self.offset = self.offset or {}
            self.offset.x = tonumber(body)
        elseif head == "offsety" then
            self.offset = self.offset or {}
            self.offset.y = tonumber(body)
        elseif head == "position" then
            local x, y = body:match("([^,]+),([^,]+)")
            self.qie = self.qie + 1
            self.angle[self.qie] = 0
            self.char_x = 0
            self.char_y = 0
            self.x[self.qie] = tonumber(x)
            self.y[self.qie] = tonumber(y)
        elseif head == "set_x" then
            self.qie = self.qie + 1
            self.angle[self.qie] = 0
            self.char_x = 0
            self.x[self.qie] = tonumber(body)
            self.y[self.qie] = self.y[self.qie - 1]
        elseif head == "set_y" then
            self.qie = self.qie + 1
            self.angle[self.qie] = 0
            self.char_y = 0
            self.x[self.qie] = self.x[self.qie - 1]
            self.y[self.qie] = tonumber(body)
        elseif head == "move_x" then
            self.qie = self.qie + 1
            self.angle[self.qie] = 0
            self.char_x = 0
            self.char_y = 0
            self.x[self.qie] = self.x[self.qie - 1] + tonumber(body)
            self.y[self.qie] = self.y[self.qie - 1]
        elseif head == "move_y" then
            self.qie = self.qie + 1
            self.angle[self.qie] = 0
            self.char_x = 0
            self.char_y = 0
            self.x[self.qie] = self.x[self.qie - 1]
            self.y[self.qie] = self.y[self.qie - 1] + tonumber(body)
        elseif head == "mode" then
            self.mode = body
        elseif head == "effect" then
            local effect, strength = body:match("^%s*([%w_]+)%s*,?%s*(%d*%.?%d*)%s*$")
            if not effect then
                effect = body:match("^%s*([%w_]+)%s*$")
            end
            
            if effect then
                self.effect.name = effect
                self.effect.effectstrength = tonumber(strength) or 1
            else
                print("WARNING: Invalid effect tag format:", body)
            end
        elseif head == "voice" then
            self.voice = {}
            for voice in body:gmatch("[^,]+") do
                voice = voice:match("^%s*(.-)%s*$")
                if voice ~= "" then
                    table.insert(self.voice, voice)
                end
            end
            -- call: [call:funcname:params1,params2...]
        elseif head == "call" then
            local funcname, params = body:match("^([%w_]+)%s*:%s*(.*)$")
            if not funcname then
                print("WARNING: Invalid func tag format:", body)
                return
            end

            local func = _G[funcname]
            if type(func) ~= "function" then
                print("WARNING: Function not found:", funcname)
                return
            end

            local paramstable = {}
            for param in params:gmatch("[^,]+") do
                param = param:match("^%s*(.-)%s*$")
                if param == "true" then
                    table.insert(paramstable, true)
                elseif param == "false" then
                    table.insert(paramstable, false)
                elseif param == "nil" then
                    table.insert(paramstable, nil)
                else
                    local num = tonumber(param)
                    table.insert(paramstable, num or param)
                end
            end

            local success, err = pcall(function()
                func(unpack(paramstable))
            end)
            if not success then
                print("WARNING: Error executing function", funcname, ":", err)
            end
        end
    else 
        -- 处理无参数标签
        if head == "noskip" then
            self.canskip = false
        elseif head == "nextpage" then
            if self.page < #self.text then
                self.page = self.page + 1
                self:Reset()
                return true
            else
                self:Remove()
            end
        elseif head == "skip" then
            self:skip()
        elseif head == "/mode" then
            self.mode = nil
        elseif head == "effect_off" then
            self.effect.name = "none"
            self.effect.effectstrength = 1
        elseif head == "/color" then
            self:SetColor(1, 1, 1)
        elseif head == "/alpha" then
            self:SetAlpha(1)
        else
            return 
        end
    end
end

-- 添加字符
function typers.func:addChar(char)
    if not self.instant and char ~= " " and #self.voice > 0 then
        Audio.PlaySound("Voices/"..self.voice[math.random(#self.voice)], false, 1)
    end
    
    -- 创建字符对象
    local font = fontCache[self.font .. self.size]
    font:setFilter("nearest", "nearest")
    local intervalX = font:getWidth(char)
    
    local character = {
        qie = self.qie,
        offsetx = self.offset.x or 0,
        offsety = self.offset.y or 0,
        x = {self.x[self.qie] + self.char_x, self.char_x},
        y = {self.y[self.qie] + self.char_y, self.char_y},
        color = {
            r = self.color.r,
            g = self.color.g,
            b = self.color.b,
            a = self.alpha
        },
        angle = self.angle[self.qie],
        nointext = nil,
        effect = {
            name = self.effect.name,
            effectstrength = self.effect.effectstrength,
            offsetx = 0,
            offsety = 0,
            time = 0
        },
        obj = love.graphics.newText(font, char)
    }
    
    table.insert(self.char, character)
    self.char_x = self.char_x + intervalX + self.xchar_spacing
    self.index = self.index + getCharDelta(self.text[self.page], self.index)
end

-- 绘制
function typers.func:draw()
    for _, char in ipairs(self.char) do
        if not self.remove and not self.hide then
            love.graphics.push()
            
            if not char.nointext then
                char.x[1] = self.x[char.qie] + char.x[2]
                char.y[1] = self.y[char.qie] + char.y[2]
                char.angle = self.angle[char.qie]
            end
            
            self:applyEffect(char)
            
            -- 绘制字符
            love.graphics.setColor(
                char.color.r,
                char.color.g,
                char.color.b,
                char.color.a
            )
            love.graphics.draw(
                char.obj,
                char.x[1] + char.effect.offsetx + char.offsetx,
                char.y[1] + char.effect.offsety + char.offsety,
                math.rad(char.angle)
            )
            
            love.graphics.pop()
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- 应用效果
function typers.func:applyEffect(char)
    if char.effect.name == "shake" then
        char.effect.offsetx = char.effect.effectstrength * math.random(-1, 1)
        char.effect.offsety = char.effect.effectstrength * math.random(-1, 1)
    elseif char.effect.name == "rotate" then
        local cos, sin = math.cos(char.effect.time * 5), math.sin(char.effect.time * 5)
        char.effect.time = char.effect.time + dt
        char.effect.offsetx = char.effect.effectstrength * cos
        char.effect.offsety = char.effect.effectstrength * sin
    end
end

-- 输入处理
function typers.func:Pressed()
    if self.mode ~= "manual" then return end
    
    local inputPressed = false
    if self.control == "key" or (not self.control) then
        if input.getKeyState("x") == 1 then
            inputPressed = "x"
        elseif input.getKeyState("z") == 1 then
            inputPressed = "z"
        end
    elseif self.control == "mouse" then
        inputPressed = input.getMouseState()
    elseif self.control == "touch" then
        inputPressed = input.isTouching()
    end

    if inputPressed ~= "z" and inputPressed then
        if self.canskip and not self.instant then
            self:skip()
        end
    end

    if inputPressed == "z" and inputPressed then
        if self.T_STATE == STATE_PAGE_END then
            self.page = self.page + 1
            self:Reset()
            if self.page > #self.text then
                self.T_STATE = STATE_FINISHED
                self:Remove()
            end
        end
    end
end

-- 设置颜色
function typers.func:SetColor(r, g, b, all)
    if all then
        for _, char in ipairs(self.char) do
            char.color.r = r
            char.color.g = g
            char.color.b = b
        end
    end
    self.color.r = r
    self.color.g = g
    self.color.b = b
end

-- 设置透明度
function typers.func:SetAlpha(a)
    self.alpha = a
end

-- 设置字体
function typers.func:SetFont(font)
    if not font then return end
    local fontPath = "Sprites/Fonts/"..font
    local fontname = font .. self.size
    if not fontCache[fontname] and love.filesystem.getInfo(fontPath) then
        fontCache[fontname] = love.graphics.newFont(fontPath, self.size)
        fontCache[fontname]:setFilter("nearest", "nearest")
    end
    self.font = font
end

-- 设置大小
function typers.func:SetScale(size)
    self.size = size
    
    loadFont(self.font, self.size)
end

-- 设置音效
function typers.func:SetVoice(voice)
    self.voice = type(voice) == "table" and voice or {voice}
end

-- 设置X间距
function typers.func:SetxCharSpacing(spacing)
    self.xchar_spacing = spacing
end

-- 设置Y间距
function typers.func:SetyCharSpacing(spacing)
    self.ychar_spacing = spacing
end

-- 重置状态
function typers.func:Reset()
    self.char = {}
    self.char_x = 0
    self.char_y = 0
    self.alpha = 1
    self:SetColor(1, 1, 1)
    self.time = self.sleep
    self.speed = self.sleep
    self.index = 1
    self.qie = 1
    self.T_STATE = STATE_TYPING
    self.instant = false
    self.canskip = true
    self.angle = {0}
end

-- 跳过
function typers.func:skip(number)
    if self.T_STATE == STATE_PAGE_END or self.T_STATE == STATE_FINISHED then
        return
    end

    if type(number) == "number" and number > 0 then
        self.skipUnitsRemaining = number
        self.instant = true
        self.canskip = false
    else
        self.instant = true
        self.canskip = false
    end
end

-- 下一页
function typers.func:NextPage()
    if self.page < #self.text then
        self.page = self.page + 1
        self:Reset()
    end
end

-- 设置文本
function typers.func:SetText(text, skip)
    self.text = type(text) == "table" and text or {text}
    self:Reset()
    self.page = 1
    if skip then
        self:skip()
    end
end

function typers.func:Bubble(w, h, direction, position)
    local startX, startY, endX, endY, position
    self.Bubble = typers.CreateBubble({self.x[1] + w / 2 - 10, self.y[1] + h / 2 - 10}, w, h, self.depth - 0.001)
    
    if not direction then
        return 
    else
        startX, endX = self.Bubble.main_w.x - self.Bubble.main_w:getWidth() / 2, self.Bubble.main_w.x + self.Bubble.main_w:getWidth() / 2
        startY, endY = self.Bubble.main_h.y - self.Bubble.main_h:getHeight() / 2, self.Bubble.main_h.y + self.Bubble.main_h:getHeight() / 2
        position = position or 0.5
    end
    
    if direction == "left" then
        self.Bubble.tail.angle = 0
        self.Bubble.tail:MoveTo(startX, startY + position * self.Bubble.main_h:getHeight())
    elseif direction == "right" then
        self.Bubble.tail.angle = 180
        self.Bubble.tail:MoveTo(endX, startY + position * self.Bubble.main_h:getHeight())
    elseif direction == "up" then
        self.Bubble.tail.angle = 90
        self.Bubble.tail:MoveTo(startX + position * self.Bubble.main_w:getWidth(), startY)
    elseif direction == "down" then
        self.Bubble.tail.angle = -90
        self.Bubble.tail:MoveTo(startX + position * self.Bubble.main_w:getWidth(), endY)
    end
end

function typers.func:HideBubble(is)
    if not rawget(self, "Bubble") then return end
    if is then
        for _, sprite in pairs(self.Bubble) do
            sprite.alpha = 0
        end
    else
        for _, sprite in pairs(self.Bubble) do
            sprite.alpha = 1
        end
    end
end

-- 隐藏/显示
function typers.func:Hide(is)
    self.hide = is and true or false
end

-- 删除
function typers.func:Remove()
    self.remove = true
    if self.box then
        self.box:Remove()
        self.box = nil
    end
    if rawget(self, "Bubble") then
        for _, sprite in pairs(self.Bubble) do
            sprite:Remove()
        end
        self.Bubble = nil
    end
    if self.over then
        self.over()
    end
    
    for i = #layers.objects.manual, 1, -1 do
        if layers.objects.manual[i] == self then
            table.remove(layers.objects.manual, i)
            break
        end
    end
end

--------- typer Print ------------

function typers.Print(text, position, depth, settings)
    local settings = settings or {}
    local text = text
    local self = setmetatable({}, mt2)
    
    -- 基本属性
    if type(text) ~= "srting" then 
        text = tostring(text) 
    end
    self.text = text
    self.x = position[1] or 320
    self.y = position[2] or 240
    self.size = settings.size or 24
    self.color = {r = settings.r or 1, g = settings.g or 1, b = settings.b or 1}
    self.alpha = settings.alpha or 1
    self.angle = 0
    self.font = settings.font or "Determination.ttf"
    self.depth = depth or 0
    self.char = {}
    self.type = "typer_Print"
    self.offset = {x = 0, y = 0}
    self.char_spacing = settings.char_spacing or 0
    self.Createtime = love.timer.getTime()
    
    -- 控制属性
    self.remove = false
    self.hide = false
    
    loadFont(self.font, self.size)
    self:parseText()
    
    table.insert(layers.objects.manual, self)
    return self
end

function typers.Print_func:parseText()
    local i = 1
    local Newoffset = self.offset
    local Newchar_spacing = self.char_spacing
    local Newcolor = self.color
    local Newfont = self.font
    local Newangle = self.angle
    local Newsize = self.size
    
    while i <= #self.text do
        local tagStart, tagEnd = self.text:find("%[(.-)%]", i)
        
        if i == tagStart then
            local tagContent = self.text:sub(tagStart + 1, tagEnd - 1)
            local head, body = tagContent:match("^([%w/_]+):?(.*)$")
            local attached = body ~= ""
            
            if attached then
                if head == "color" then
                    local color = parseColor(body)
                    Newcolor = {color[1], color[2], color[3]}
                elseif head == "font" then
                    local size = tonumber(body)
                    loadFont(body, Newsize)
                    Newfont = body
                elseif head == "char_spacing" then
                    Newchar_spacing = tonumber(body)
                elseif head == "offsetx" then
                    Newoffset.x = tonumber(body)
                elseif head == "offsety" then
                    Newoffset.y = tonumber(body)
                elseif head == "size" then
                    Newsize = tonumber(body)
                    loadFont(Newfont, tonumber(body))
                end
            else
                if head == "/color" then
                    Newcolor = self.color
                elseif head == "/font" then
                    Newfont = self.font
                end
            end
            
            i = tagEnd + 1
        else
            local textEnd = tagStart and tagStart - 1 or #self.text
            while i <= textEnd do
                local byte = self.text:byte(i)
                local length = utf8CharLength(byte)
                local char = self.text:sub(i, i + length - 1)
                
                local font = fontCache[Newfont .. Newsize]
                font:setFilter("nearest", "nearest")
                local intervalX = font:getWidth(char)
                
                local character = {
                    offsetx = Newoffset.x,
                    offsety = Newoffset.y,
                    color = {
                        r = Newcolor.r,
                        g = Newcolor.g,
                        b = Newcolor.b,
                        a = Newcolor.alpha
                    },
                    font = Newfont,
                    angle = Newangle,
                    size = Newsize,
                    char = char,
                    obj = love.graphics.newText(font, char)
                }
                
                table.insert(self.char, character)
                i = i + length
            end
        end
    end
end

function typers.Print_func:Reparse()
    self.char = {}
    self:parseText()
end

function typers.Print_func:SetScale(size)
    self.size = size
    
    loadFont(self.font, self.size)
end

function typers.Print_func:GetLettersSize()
    local width, maxheight = 0, 0
    
    for _, char in ipairs(self.char) do
        local font = fontCache[char.font .. char.size]
        width = width + font:getWidth(char.char) + self.char_spacing
        maxheight = math.max(maxheight, font:getHeight(char.char))
    end
    return width, maxheight
end

function typers.Print_func:update(dt)
end

function typers.Print_func:draw()
    local X = self.x
    for _, char in ipairs(self.char) do
        if not self.remove and not self.hide then
            love.graphics.push()
            
            char.angle = self.angle
            local font = fontCache[char.font .. char.size]
            font:setFilter("nearest", "nearest")
            local intervalX = font:getWidth(char.char)
            
            -- 绘制字符
            love.graphics.setColor(
                char.color.r,
                char.color.g,
                char.color.b,
                char.color.a
            )
            love.graphics.draw(
                char.obj,
                X + char.offsetx,
                self.y + char.offsety,
                math.rad(char.angle)
            )
            
            X = X + intervalX + self.char_spacing
            love.graphics.pop()
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function typers.Print_func:Remove()
    self.remove = true

    if self.over then
        self.over()
    end
    
    for i = #layers.objects.manual, 1, -1 do
        if layers.objects.manual[i] == self then
            table.remove(layers.objects.manual, i)
            break
        end
    end
end

---------- end ----------------

return typers