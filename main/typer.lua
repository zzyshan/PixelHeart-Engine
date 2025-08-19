local typers = {}

local mt = { __index = typers }

-- 状态常量
local STATE_IDLE = 0 -- 空闲状态
local STATE_TYPING = 1 -- 打字状态
local STATE_WAITING = 2 -- 等待状态
local STATE_PAGE_END = 3 -- 一页结束状态
local STATE_FINISHED = 4 -- 全部完全状态

-- 字体缓存
local fontCache = {}

--------- 临时函数 -----------

-- UTF-8字符长度计算
local function utf8CharLength(b)
    if not b then return 0 end
    return b > 239 and 4 or b > 223 and 3 or b > 127 and 2 or 1
end

-- 获得delta
local function getdelta(currentText, index)
    local b = string.byte(currentText, index)
    return utf8CharLength(b)
end

-- 获得letter
local function getletter(currentText, index)
    local b = string.byte(currentText, index)
    local delta = utf8CharLength(b)
    local letter = currentText:sub(index, index + delta - 1)
    return letter
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

--------- end --------------
-- 创建打字机
function typers.New(text, position, depth, settings)
    local settings = settings or {}
    local self = setmetatable({}, mt)
    
    self.text = type(text) == "table" and text or {text}
    self.page = 1
    self.x, self.y = {position[1] or 320}, {position[2] or 240}
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
    self.speed = settings.speed or 20
    self.sleep = settings.sleep or 20
    self.time = self.speed
    self.index = 1
    self.qie = 1
    self.T_STATE = STATE_TYPING
    self.type = "typer"
    self.effect = {
        name = nil,
        effectstrength = nil
    }
    self.offset = {}
    self.Createtime = love.timer.getTime()
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
            fontCache[font] = love.graphics.newFont(fontPath, 24)  -- 默认大小
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

function typers.clear()
    for i = #layers.objects.manual, 1, -1 do
        local tpr = layers.objects.manual[i]
        if not tpr.remove and tpr.type == "typer" then
            tpr:Remove()
        end
    end
end

-------- typer方法 ---------+
function typers:update(dt)
    -- 确保 x, y, angle 是表
    if type(self.x) ~= "table" then self.x = {self.x} end
    if type(self.y) ~= "table" then self.y = {self.y} end
    if type(self.angle) ~= "table" then self.angle = {self.angle} end

    if self.remove then return end
    if self.T_STATE == STATE_FINISHED then return end
    
    if not self.remove and self.T_STATE == STATE_TYPING then
        if self.instant then
            while self.T_STATE ~= STATE_FINISHED and self.instant do
                if self.T_STATE == STATE_PAGE_END then
                     self.instant = false
                     break
                end
                self:printNextChar()

                if self.skipUnitsRemaining and self.skipUnitsRemaining > 0 then
                    self.skipUnitsRemaining = self.skipUnitsRemaining - 1
                    if self.skipUnitsRemaining <= 0 then
                        self.skipUnitsRemaining = nil -- 清除计数器
                        self.instant = false
                        self.canskip = true
                    end
                end

                local currentText = self.text[self.page]
                if self.index > #currentText then
                    self.T_STATE = STATE_PAGE_END
                    self.instant = false -- 确保在页面结束时也退出 instant
                    break
                end
            end
        else
            if self.T_STATE ~= STATE_PAGE_END then
                 self.time = self.time + dt
                 local charDelay = 1 / self.speed
                 while self.time >= charDelay do
                     self.time = 0
                     self:printNextChar()
                     if self.T_STATE == STATE_PAGE_END or self.T_STATE == STATE_FINISHED then
                         break
                     end
                 end
            end
        end
    end
end

-- 处理下个字符
function typers:printNextChar()
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

    local letter = getletter(currentText, self.index)
    local intervalX, intervalY = fontCache[self.font]:getWidth(letter), fontCache[self.font]:getHeight(letter)

    while letter == "\n" do
        self.char_x = 0
        self.char_y = self.char_y + intervalY + self.ychar_spacing
        self.index = self.index + getdelta(currentText, self.index)
        letter = getletter(currentText, self.index)

        if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
             self.unitsToSkip = self.unitsToSkip - 1
             if self.unitsToSkip <= 0 then
                 self.unitsToSkip = nil -- 清除计数器
                 self.instant = false
                 self.canskip = true
                 return 
             end
        end
    end

    -- 处理空格
    while letter == " " do
        self.index = self.index + 1
        self.char_x = self.char_x + intervalX
        letter = getletter(currentText, self.index)

        if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
             self.unitsToSkip = self.unitsToSkip - 1
             if self.unitsToSkip <= 0 then
                 self.unitsToSkip = nil
                 self.instant = false
                 self.canskip = true
                 return
             end
        end
    end

    -- 处理标签
    while letter == "[" do
        local tagStart = self.index
        local tagEnd = currentText:find("]", tagStart)
        if not tagEnd then
            break
        end
        local tagContent = currentText:sub(tagStart + 1, tagEnd - 1) -- 去掉 []
        local _, _, head, body = tagContent:find("^([%w_]+):?(.*)$")
        if head then
            local attached = body ~= ""
            self:processTag(head, body, attached)
        end

        self.index = tagEnd + 1
        -- 获取下一个字符
        if self.index <= #currentText then
            letter = getletter(currentText, self.index)
        else
            break
        end

        if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
             self.unitsToSkip = self.unitsToSkip - 1
             if self.unitsToSkip <= 0 then
                 self.unitsToSkip = nil
                 self.instant = false
                 self.canskip = true
                 return
             end
        end
    end

    if self.instant and self.unitsToSkip and self.unitsToSkip > 0 then
        -- 跳过这个字符（不调用 addchar）
        self.index = self.index + getdelta(currentText, self.index)
        self.char_x = self.char_x + intervalX + self.xchar_spacing -- 更新位置

        self.unitsToSkip = self.unitsToSkip - 1
        if self.unitsToSkip <= 0 then
            self.unitsToSkip = nil
            self.instant = false
            self.canskip = true
            -- 检查是否到达文本末尾
            if self.index > #currentText then
                self.T_STATE = STATE_PAGE_END
            end
            return 
        end
        -- 检查是否到达文本末尾
        if self.index > #currentText then
            self.T_STATE = STATE_PAGE_END
        end
        return 
    end

    -- 如果不是在带数量跳过模式，则正常添加字符
    self:addchar(letter)

    if self.index > #currentText then
        self.T_STATE = STATE_PAGE_END
    end
end

-- 标签处理方法
function typers:processTag(head, body, attached)
    if attached then
        head = head:lower()  -- 统一转换为小写
        
        -- 标签参数处理逻辑
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
            self.sleep = tonumber(body)
        elseif head == "skip" then
            self:skip(tonumber(body))
        elseif head == "font_size" then
            self:SetScale(tonumber(body))
        elseif head == "speed" then
            self.speed = tonumber(body)
        elseif head == "offsetx" then
            self.offset = self.offset or {}
            self.offset.x = tonumber(body)
        elseif head == "offsety" then
            self.offset = self.offset or {}
            self.offset.y = tonumber(body)
        elseif head == "position" then
            local x = body:sub(1,body:find(",") - 1)
            local y = body:sub(#x + 2, -1)
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
            
            -- 如果匹配失败，尝试只获取效果名称
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
                voice = voice:match("^%s*(.-)%s*$") -- 去除前后空格
                if voice ~= "" then
                    table.insert(self.voice, voice)
                end
            end
        elseif head == "call" then
            -- 参数解析
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

            -- 参数解析
            local paramstable = {}
            for param in params:gmatch("[^,]+") do
                param = param:match("^%s*(.-)%s*$")  -- 去除前后空格

                -- 类型转换
                if param == "true" then
                    table.insert(paramstable, true)
                elseif param == "false" then
                    table.insert(paramstable, false)
                elseif param == "nil" then
                    table.insert(paramstable, nil)
                else
                    local num = tonumber(param)
                    table.insert(paramstable, num or param)  -- 数字或字符串
                end
            end

             -- 调用函数
            local success, err = pcall(function()
                func(unpack(paramstable))
            end)
            if not success then
                print("WARNING: Error executing function", funcname, ":", err)
            end
        end
    else 
        -- 处理特殊标签
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
function typers:addchar(char)
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
    self.index = self.index + getdelta(self.text[self.page], self.index)
end

function typers:draw()
    for _, char in ipairs(self.char) do
        if not self.remove and not self.hide then
            if char.intext then
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
                char.x[1] + char.effect.offsetx + char.offset.x,
                char.y[1] + char.effect.offsety + char.offset.y,
                math.rad(char.angle)
            )
        end
    end

    love.graphics.setColor(1, 1, 1, 1)  -- 重置颜色
end

-- 应用效果
function typers:applyEffect(char)
    -- 处理字符效果
    if char.effect.name == "shake" then
        char.effect.offsetx = char.effect.effectstrength * math.random(-1, 1)
        char.effect.offsety = char.effect.effectstrength * math.random(-1, 1)
    elseif char.effect.name == "rotate" then
        char.effect.time = char.effect.time + dt
        char.effect.offsetx = char.effect.effectstrength * math.cos(char.effect.time * 5)
        char.effect.offsety = char.effect.effectstrength * math.sin(char.effect.time * 5)
    end
end

-------- end --------------+

-------- 小方法 -----------++
-- 输入
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

    if type(inputPressed) == "boolean" and inputPressed then
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
    elseif type(inputPressed) == "string" and inputPressed then
        if inputPressed == "x" and self.canskip and not self.instant then
            self:skip()
        end

        if inputPressed == "z" and self.T_STATE == STATE_PAGE_END then
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

-- Y间距
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
    self.index = 1
    self.qie = 1
    self.T_STATE = STATE_TYPING
    self.instant = false
    self.canskip = true
    self.angle = {0}
end

-- 跳过
function typers:skip(number)
    -- 检查是否已经结束，避免无效操作
    if self.T_STATE == STATE_PAGE_END or self.T_STATE == STATE_FINISHED then
        return
    end

    if type(number) == "number" and number > 0 then
        -- 设置跳过单元数
        self.skipUnitsRemaining = number -- 记录需要快速处理的char
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

function typers:SetText(text, skip)
    self.text = type(text) == "table" and text or {text}
    self:Reset()
    self.page = 1
    if skip then
        self:skip()
    end
end

-- 是否隐藏
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
-------- end -------------++

return typers