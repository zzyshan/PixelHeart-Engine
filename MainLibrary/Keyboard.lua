local keyboard = {
    keys = {},       -- 存储所有键盘按键状态
    mouse = {       -- 鼠标状态
        state = 0,
        pressed = false,
        previous = false
    },
    touch = {
        touches = {}, -- 存储所有触摸点
        anyTouch = false,-- 是否有任意触摸点按下
        touchCount = 0-- 当前触摸点数量
    }
}

-- 预定义所有支持的按键
local keyDefinitions = {
    -- 符号键
    {id="!"}, {id="@"}, {id="#"}, {id="$"}, {id="%"}, {id="^"},
    {id="&"}, {id="*"}, {id="("}, {id=")"}, {id="-"}, {id="_"},
    {id="="}, {id="+"}, {id="["}, {id="]"},
    {id=";"}, {id=":"}, {id="'"}, {id="\""}, {id="\\"},
    {id=","}, {id="<"}, {id="."}, {id=">"}, {id="/"}, {id="?"},
    {id="`"},
    
    -- 控制键
    {id="tab"}, {id="capslock"}, {id="lshift"}, {id="rshift"},
    {id="lctrl"}, {id="rctrl"}, {id="lalt"}, {id="ralt"},
    {id="escape"}, {id="space"}, {id="return"}, {id="backspace"},
    {id="up"}, {id="down"}, {id="left"}, {id="right"},
    {id="home"}, {id="end"}, {id="pageup"}, {id="pagedown"},
    {id="insert"}, {id="delete"}, {id="numlock"}
}

for i=1,12 do
    table.insert(keyDefinitions,{id="f"..i})-- 功能键
end

for i=0,9 do
    table.insert(keyDefinitions,{id=tostring(i)})-- 数字键
end

for i=97,122 do
    table.insert(keyDefinitions,{id=string.char(i)})-- 字母键
end

-- 初始化所有按键状态
for _, def in ipairs(keyDefinitions) do
    keyboard.keys[def.id] = {
        state = 0,
        pressed = false,
        previous = false
    }
end

-- 获取按键状态
function keyboard.getState(key)
    local keyObj = keyboard.keys[key]
    return keyObj.state
end

function keyboard.isDown(keys)
    for _, key in ipairs({keys}) do
        local keyObj = keyboard.keys[key]
        if keyObj.state > 0 then
            return true
        end
    end
    
    return false
end

---------- 按键的虚拟化处理 ---------
keyboard._keyboardisDown = love.keyboard.isDown

-- 虚拟按键
keyboard.virtualkeys = {}

function love.keyboard.isDown(key)
    -- 优先处理虚拟按键
    if keyboard.virtualkeys[key] then
        return true
    end
    
    return keyboard._keyboardisDown(key)
end

function keyboard.SetVirtualKey(key, state)
    keyboard.virtualkeys[key] = state
end
---------- end ------------------

-- 获取鼠标状态
function keyboard.getMouseState()
    return keyboard.mouse.state
end

-- 获取触摸点数量
function keyboard.getTouchCount()
    return keyboard.touch.touchCount
end

-- 检查是否有触摸
function keyboard.isTouching()
    return keyboard.touch.anyTouch
end

-- 获取特定触摸点信息
function keyboard.getTouch(id)
    return keyboard.touch.touches[id]
end

-- 获取所有触摸点
function keyboard.getAllTouches()
    return keyboard.touch.touches
end

-- 更新输入状态
function keyboard.update(dt)
    -- 更新键盘状态
    for id, key in pairs(keyboard.keys) do
        key.pressed = love.keyboard.isDown(id)
        
        -- 状态转换逻辑
        if key.pressed == key.previous then
            key.state = key.pressed and 2 or 0
        else
            key.state = key.pressed and 1 or -1
            key.previous = key.pressed
        end
    end
    
    -- 更新鼠标状态
    local mouse = keyboard.mouse
    if mouse.pressed == mouse.previous then
        mouse.state = mouse.pressed and 2 or 0
    else
        mouse.state = mouse.pressed and 1 or -1
        mouse.previous = mouse.pressed
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    keyboard.mouse.pressed = (button == 1)
end

function love.mousereleased(x, y, button, istouch, presses)
    keyboard.mouse.pressed = not (button == 1)
end

-- 触摸事件回调
-- 触摸按下
function love.touchpressed(id, x, y, dx, dy, pressure)
    local touch = keyboard.touch
    
    touch.touches[id] = {
        id = id,
        x = x,
        y = y,
        startX = tx,
        startY = ty,
        pressure = pressure,
        state = 1
    }

    touch.touchCount = touch.touchCount + 1
    touch.anyTouch = touch.touchCount > 0
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if keyboard.touch.touches[id] then
        keyboard.touch.touches[id].x = x
        keyboard.touch.touches[id].y = y
        keyboard.touch.touches[id].state = 2
        keyboard.touch.touches[id].pressure = pressure
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local touch = keyboard.touch
    
    if touch.touches[id] then
        touch.touches[id].x = x
        touch.touches[id].y = y
        touch.touches[id].state = -1
    end
    
    touch.touches[id] = nil
    touch.touchCount = math.max(0, touch.touchCount - 1)
    touch.anyTouch = touch.touchCount > 0
end

return keyboard