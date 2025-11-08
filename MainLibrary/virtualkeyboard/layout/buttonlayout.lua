local BL = {
    buttons = {}
}

local function PlaceButton(spr, position, id, scale)
    local button = Sprites.New(spr, position, 100)
    button.id = id
    button.BLtype = "button"
    button:SetAlpha(0.8)
    button:SetScale(scale[1] or 4.5, scale[2] or 4.5)
    button.radius = button:getWidth()/2  -- 存储半径
    button:allTop(true)
    table.insert(BL.buttons, button)
end

local function PlaceArrow(spr, position, id)
    local arrow = Sprites.New(spr, position, 100)
    arrow.id = id
    arrow.BLtype = "arrow"
    arrow:SetAlpha(0.8)
    arrow:SetScale(4,4)
    arrow.radius = arrow:getWidth()/2  -- 存储半径
    arrow:allTop(true)
    table.insert(BL.buttons, arrow)
end

------------创建按钮----------------
PlaceArrow("virtualkeyboard/buttons/arrow-down.png", {620,300}, "down")
PlaceArrow("virtualkeyboard/buttons/arrow-up.png", {620,190}, "up")
PlaceArrow("virtualkeyboard/buttons/arrow-left.png", {120,280}, "left")
PlaceArrow("virtualkeyboard/buttons/arrow-right.png", {260,280}, "right")

PlaceButton("virtualkeyboard/buttons/button-z.png", {540,90}, "z", {3,3})
PlaceButton("virtualkeyboard/buttons/button-x.png", {630,90}, "x", {3,3})
PlaceButton("virtualkeyboard/buttons/button-c.png", {720,90}, "c", {3,3})
------------创建按钮----------------

function BL.draw()
    love.graphics.setColor(1, 1, 1)
    for _, button in ipairs(BL.buttons) do
        -- 绘制碰撞区域（红色圆圈）
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.circle("line", button.x, button.y, button.radius)
        
        -- 显示按钮状态和坐标信息
        love.graphics.setColor(1, 1, 1)
        local status = button.id .. ": " .. (button.istouch and "ON" or "OFF")
        local posInfo = string.format("(%.0f,%.0f) R=%.0f", button.x, button.y, button.radius)
        love.graphics.print(status, button.x - 30, button.y - 40)
        love.graphics.print(posInfo, button.x - 30, button.y - 20)
    end
    
    -- 绘制所有触摸点（蓝色圆圈）
    local touches = Keyboard.getAllTouches() or {}
    love.graphics.setColor(0, 0, 1, 0.7)
    for _, touch in pairs(touches) do
        if touch.state ~= -1 then  -- 忽略已释放的触摸
            love.graphics.circle("fill", touch.x, touch.y, 10)
            love.graphics.print(tostring(touch.id), touch.x + 15, touch.y - 5)
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function BL.update(dt)
    local touches = Keyboard.getAllTouches()
    
    -- 重置触摸状态（先保留当前触摸ID）
    for _, button in ipairs(BL.buttons) do
        button.istouch = false
    end

    -- 处理新触摸
    for touchId, touch in pairs(touches) do
        -- 跳过释放状态的触摸
        if touch.state ~= -1 then
            local closestArrow, minDist = nil, math.huge
            
            -- 找出距离最近的按钮
            for _, button in ipairs(BL.buttons) do
                local dist = mathlib.distance(touch.x, touch.y, button.x, button.y)
                if dist <= button.radius and dist < minDist then
                    closestArrow = button
                    minDist = dist
                end
            end
            
            -- 分配触摸到最近的按钮
            if closestArrow then
                if Keyboard.getState(closestArrow.id) == 0 then
                    closestArrow.touchid = touchId
                    Keyboard.SetVirtualKey(closestArrow.id, true)
                    closestArrow:Set("virtualkeyboard/buttons/"..closestArrow.BLtype.."-" .. closestArrow.id .. "1.png")
                    closestArrow.istouch = true
                end
            end
        end
    end

    -- 检查触摸释放
    for _, button in ipairs(BL.buttons) do
        if button.touchid then
            local touch = touches[button.touchid]
            if not touch or touch.state == -1 then
                Keyboard.SetVirtualKey(button.id, false)
                button:Set("virtualkeyboard/buttons/"..button.BLtype.."-" .. button.id .. ".png")
                button.touchid = nil
            else
                -- 即使触摸存在，也要检查是否还在按钮区域内
                local dist = mathlib.distance(touch.x, touch.y, button.x, button.y)
                if dist > button.radius then
                    Keyboard.SetVirtualKey(button.id, false)
                    button:Set("virtualkeyboard/buttons/"..button.BLtype.."-" .. button.id .. ".png")
                    button.touchid = nil
                end
            end
        end
    end
end

function BL.clean()
    for i = #BL.buttons, 1, -1 do
        local button = BL.buttons[i]
        button:Remove()
    end
end

return BL