local Keyboard = {
    keys = {},       -- 存储所有键盘按键状态
    mouse = {       -- 鼠标状态
        state = 0,
        pressed = false,
        previous = false,
        isSet = false
    },
    touch = {
        touches = {}, -- 存储所有触摸点
        anyTouch = false,-- 是否有任意触摸点按下
        touchCount = 0,-- 当前触摸点数量
        gameWidth = 640,
        gameHeight = 480,
        scale = 1,
        offsetX = 0,
        offsetY = 0
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
    Keyboard.keys[def.id] = {
        state = 0,
        pressed = false,
        previous = false,
        isSet = false
    }
end

-- 获取按键状态
function Keyboard.getState(key)
    for _, keys in ipairs({key}) do
        local keyObj = Keyboard.keys[keys]
        return keyObj.state
    end
end

-- 设置按键状态（手动覆盖）
function Keyboard.setState(key, state)
    local keyObj = Keyboard.keys[key]
    if keyObj then
        keyObj.isSet = true
        keyObj.time = love.timer.getTime()
        keyObj.state = state
    end
end

-- 恢复自动检测状态
function Keyboard.restore(key)
    local keyObj = Keyboard.keys[key]
    if keyObj then
        keyObj.isSet = false
    end
end

-- 获取鼠标状态
function Keyboard.getMouseState()
    return Keyboard.mouse.state
end

-- 获取触摸点数量
function Keyboard.getTouchCount()
    return Keyboard.touch.touchCount
end

-- 检查是否有触摸
function Keyboard.isTouching()
    return Keyboard.touch.anyTouch
end

-- 获取特定触摸点信息
function Keyboard.getTouch(id)
    return Keyboard.touch.touches[id]
end

-- 获取所有触摸点
function Keyboard.getAllTouches()
    return Keyboard.touch.touches
end

-- 更新窗口尺寸信息
function Keyboard.updateWindowSize(windowWidth, windowHeight)
    local touch = Keyboard.touch
    touch.scale = math.min(windowWidth / touch.gameWidth, windowHeight / touch.gameHeight)
    touch.offsetX = math.floor((windowWidth - touch.gameWidth * touch.scale) / 2)
    touch.offsetY = math.floor((windowHeight - touch.gameHeight * touch.scale) / 2)
end

-- 转换触摸坐标到游戏坐标系
function Keyboard.transformTouch(x, y)
    local touch = Keyboard.touch
    -- 1. 减去黑边偏移
    x = x - touch.offsetX
    y = y - touch.offsetY
    -- 2. 除以缩放比例
    x = x / touch.scale
    y = y / touch.scale
    return x, y
end

-- 更新输入状态
function Keyboard.update(dt)
    -- 更新键盘状态
    for id, key in pairs(Keyboard.keys) do
        if not key.isSet then
            key.pressed = love.keyboard.isDown(id)
            
            -- 状态转换逻辑
            if key.pressed == key.previous then
                key.state = key.pressed and 2 or 0
            else
                key.state = key.pressed and 1 or -1
                key.previous = key.pressed
            end
        else
            if key.time then
                local delay = 0.5
                if love.timer.getTime() > key.time + delay then
                    Keyboard.restore(id)
                end
            end
        end
    end
    
    -- 更新鼠标状态
    local mouse = Keyboard.mouse
    if not mouse.isSet then
        if mouse.pressed == mouse.previous then
            mouse.state = mouse.pressed and 2 or 0
        else
            mouse.state = mouse.pressed and 1 or -1
            mouse.previous = mouse.pressed
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    Keyboard.mouse.pressed = (button == 1)
end

function love.mousereleased(x, y, button, istouch, presses)
    Keyboard.mouse.pressed = not (button == 1)
end

-- 触摸事件回调
-- 触摸按下
function love.touchpressed(id, x, y, dx, dy, pressure)
    local touch = Keyboard.touch
    local tx, ty = Keyboard.transformTouch(x, y)
    
    touch.touches[id] = {
        id = id,
        x = tx,  -- 存储转换后的坐标
        y = ty,
        rawX = x, -- 原始坐标
        rawY = y,
        startX = tx,
        startY = ty,
        pressure = pressure,
        state = 1
    }

    touch.touchCount = touch.touchCount + 1
    touch.anyTouch = touch.touchCount > 0
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if Keyboard.touch.touches[id] then
        local tx, ty = Keyboard.transformTouch(x, y)
        Keyboard.touch.touches[id].x = tx
        Keyboard.touch.touches[id].y = ty
        Keyboard.touch.touches[id].rawX = x
        Keyboard.touch.touches[id].rawY = y
        Keyboard.touch.touches[id].state = 2
        Keyboard.touch.touches[id].pressure = pressure
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local touch = Keyboard.touch
    local tx, ty = Keyboard.transformTouch(x, y)
    
    if touch.touches[id] then
        touch.touches[id].x = tx
        touch.touches[id].y = ty
        touch.touches[id].rawX = x
        touch.touches[id].rawY = y
        touch.touches[id].state = -1
    end
    
    touch.touches[id] = nil
    touch.touchCount = math.max(0, touch.touchCount - 1)
    touch.anyTouch = touch.touchCount > 0
end

return Keyboard