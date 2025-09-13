local typers = {}

local mt = { __index = typers }

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
    if not fontCache[name] then
        local fontPath = "Sprites/Fonts/" .. name
        if love.filesystem.getInfo(fontPath) then
            fontCache[name] = love.graphics.newFont(fontPath, size)
            fontCache[name]:setFilter("nearest", "nearest")
        end
    end
end

-- 创建打字机
function typers.New(text, position, depth, settings)
    settings = settings or {}
    local self = setmetatable({}, mt)
    
    -- 基本属性
    self.text = type(text) == "table" and text or {text}
    self.page = 1
    self.x = {position[1] or 320}
    self.y = {position[2] or 240}
    self.char_x, self.char_y = settings.char_x or 0, settings.char_y or 0
    self.xchar_spacing, self.ychar_spacing = settings.xchar_spacing or 2, settings.ychar_spacing or 2
    self.size = settings.size or 24
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
        if not obj.remove and not obj.noGlobal and obj.type == "typer" then
            obj:Pressed()
        end
    end
end

-- 预加载字体
function typers.PreloadFont(fontPaths)
    for _, font in ipairs(fontPaths) do
        local fontPath = "Sprites/Fonts/"..font
        if love.filesystem.getInfo(fontPath) then
            fontCache[font] = love.graphics.newFont(fontPath, 24)
            fontCache[font]:setFilter("nearest", "nearest")
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
        if not tpr.remove and tpr.type == "typer" then
            tpr:Remove()
        end
    end
end

-- 更新打字机
function typers:update(dt)
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
function typers:processInstantMode()
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
function typers:processNormalMode(dt)
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
function typers:ProcessNextChar()
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
    local font = fontCache[self.font]
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
function typers:handleNewline(intervalY)
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
function typers:handleSpace(intervalX)
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
function typers:handleTag(currentText)
    local tagStart = self.index
    local tagEnd = currentText:find("]", tagStart)
    if not tagEnd then
        self.index = self.index + 1
        return
    end
    
    local tagContent = currentText:sub(tagStart + 1, tagEnd - 1)
    local _, _, head, body = tagContent:find("^([%w_]+):?(.*)$")
    
    if head then
        local attached = body ~= ""
        self:processTag(head, body, attached)
    end

    self.index = tagEnd + 1
end

-- 处理跳过模式
function typers:handleSkipMode(currentText, delta, intervalX)
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
function typers:processTag(head, body, attached)
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
            else
                if self.over then
                    self.over()
                end
                self:Remove()
            end
        elseif head == "skip" then
            self:skip()
        elseif head == "effect_off" then
            self.effect.name = "none"
            self.effect.effectstrength = 1
        elseif head == "/color" then
            self:SetColor(1, 1, 1)
        elseif head == "/alpha" then
            self:SetAlpha(1)
        end
    end
end

-- 添加字符
function typers:addChar(char)
    if not self.instant and char ~= " " and #self.voice > 0 then
        Audio.PlaySound("Voices/"..self.voice[math.random(#self.voice)], false, 1)
    end
    
    -- 创建字符对象
    local font = fontCache[self.font]
    font:setFilter("nearest", "nearest")
    local intervalX = font:getWidth(char)
    
    local character = {
        qie = self.qie,
        offset = {
            x = self.offset.x or 0,
            y = self.offset.y or 0
        },
        x = {self.x[self.qie] + self.char_x, self.char_x},
        y = {self.y[self.qie] + self.char_y, self.char_y},
        color = {
            r = self.color.r,
            g = self.color.g,
            b = self.color.b,
            a = self.alpha
        },
        font = {self.font, char},
        angle = self.angle[self.qie],
        intext = true,
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
function typers:draw()
    for _, char in ipairs(self.char) do
        if not self.remove and not self.hide and char.intext then
            char.x[1] = self.x[char.qie] + char.x[2]
            char.y[1] = self.y[char.qie] + char.y[2]
            char.angle = self.angle[char.qie]
            
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
                char.x[1] + char.effect.offsetx + char.offset.x,
                char.y[1] + char.effect.offsety + char.offset.y,
                math.rad(char.angle)
            )
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- 应用效果
function typers:applyEffect(char)
    if char.effect.name == "shake" then
        char.effect.offsetx = char.effect.effectstrength * math.random(-1, 1)
        char.effect.offsety = char.effect.effectstrength * math.random(-1, 1)
    elseif char.effect.name == "rotate" then
        char.effect.time = char.effect.time + dt
        char.effect.offsetx = char.effect.effectstrength * math.cos(char.effect.time * 5)
        char.effect.offsety = char.effect.effectstrength * math.sin(char.effect.time * 5)
    end
end

-- 输入处理
function typers:Pressed()
    if self.mode ~= "manual" then return end
    
    local inputPressed = false
    if self.control == "key" or (not self.control) then
        if Keyboard.getState("x") == 1 then
            inputPressed = "x"
        elseif Keyboard.getState("z") == 1 then
            inputPressed = "z"
        end
    elseif self.control == "mouse" then
        inputPressed = GetmouseState() == 1
    elseif self.control == "touch" then
        inputPressed = GettouchState() == 1
    end

    if inputPressed then
        if self.canskip and not self.instant then
            self:skip()
        end

        if self.T_STATE == STATE_PAGE_END then
            self.page = self.page + 1
            self:Reset()
            if self.page > #self.text then
                self.T_STATE = STATE_FINISHED
                if self.over then
                    self.over()
                end
                self:Remove()
            end
        end
    end
end

-- 获取打字机宽度和最大高度(只限一行,问题很多,目前不建议使用)
function typers:GetLettersSize()
    local width, maxheight = 0, 0
    
    for _, char in ipairs(self.char) do
        local font = fontCache[char.font[1]]
        width = width + font:getWidth(char.font[2]) + self.xchar_spacing
        maxheight = math.max(maxheight, font:getHeight(char.font[2]))
    end
    return width, maxheight
end

-- 设置颜色
function typers:SetColor(r, g, b, all)
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
function typers:SetAlpha(a)
    self.alpha = a
end

-- 设置字体
function typers:SetFont(font)
    if not font then return end
    local fontPath = "Sprites/Fonts/"..font
    if not fontCache[font] and love.filesystem.getInfo(fontPath) then
        fontCache[font] = love.graphics.newFont(fontPath, self.scale)
        fontCache[font]:setFilter("nearest", "nearest")
    end
    self.font = font
end

-- 设置大小
function typers:SetScale(size)
    self.size = size
    fontCache[self.font] = love.graphics.newFont("Sprites/Fonts/" .. self.font, self.size)
    fontCache[self.font]:setFilter("nearest", "nearest")
end

-- 设置音效
function typers:SetVoice(voice)
    self.voice = type(voice) == "table" and voice or {voice}
end

-- 设置X间距
function typers:SetxCharSpacing(spacing)
    self.xchar_spacing = spacing
end

-- 设置Y间距
function typers:SetyCharSpacing(spacing)
    self.ychar_spacing = spacing
end

-- 重置状态
function typers:Reset()
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
function typers:skip(number)
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
function typers:NextPage()
    if self.page < #self.text then
        self.page = self.page + 1
        self:Reset()
    end
end

-- 设置文本
function typers:SetText(text, skip)
    self.text = type(text) == "table" and text or {text}
    self:Reset()
    self.page = 1
    if skip then
        self:skip()
    end
end

-- 隐藏/显示
function typers:Hide(is)
    self.hide = is and true or false
end

-- 删除
function typers:Remove()
    self.remove = true
    if self.box then
        self.box:Remove()
        self.box = nil
    end
    for i = #layers.objects.manual, 1, -1 do
        if layers.objects.manual[i] == self then
            table.remove(layers.objects.manual, i)
            break
        end
    end
end

return typers