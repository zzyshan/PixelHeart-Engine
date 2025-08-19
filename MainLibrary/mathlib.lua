local mathlib = {}

-- ====================
-- 常量定义 (直接作为属性)
-- ====================
mathlib.PI = 3.141592653589793
mathlib.TAU = 6.283185307179586  -- 2π
mathlib.E = 2.718281828459045
mathlib.PHI = 1.618033988749895  -- 黄金比例
mathlib.SQRT2 = 1.4142135623730951
mathlib.SQRT3 = 1.7320508075688772
mathlib.DEG2RAD = 0.017453292519943295  -- π/180
mathlib.RAD2DEG = 57.29577951308232  -- 180/π
mathlib.INF = math.huge
mathlib.EPSILON = 1e-10  -- 浮点数精度容差

-- ====================
-- 基础运算函数
-- ====================

-- 限制数值在指定范围内
function mathlib.clamp(value, min, max)
    return value < min and min or (value > max and max or value)
end

-- 线性映射
function mathlib.map(value, in_min, in_max, out_min, out_max)
    return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

-- 判断两个浮点数是否近似相等
function mathlib.approx(a, b, epsilon)
    epsilon = epsilon or mathlib.EPSILON
    return math.abs(a - b) < epsilon
end

-- 最大公约数
function mathlib.gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return math.abs(a)
end

-- 最小公倍数
function mathlib.lcm(a, b)
    return math.abs(a * b) / mathlib.gcd(a, b)
end

-- ====================
-- 几何函数
-- ====================

-- 计算两点间距离
function mathlib.distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

--两点距离的平方
function mathlib.distanceSq(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return dx*dx + dy*dy
end

-- 点是否在矩形内
function mathlib.pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- 点是否在圆内
function mathlib.pointInCircle(px, py, cx, cy, radius)
    return (px - cx)^2 + (py - cy)^2 <= radius^2
end

-- 计算角度（弧度）
function mathlib.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

-- ====================
-- 三角函数
-- ====================

-- 角度转弧度
function mathlib.toRadians(degrees)
    return degrees * mathlib.DEG2RAD
end

-- 弧度转角度
function mathlib.toDegrees(radians)
    return radians * mathlib.RAD2DEG
end

-- 方向向量
function mathlib.direction(angle)
    return math.cos(angle), math.sin(angle)
end

-- ====================
-- 向量操作 (保持为子模块，因为使用频率高)
-- ====================
mathlib.vec2 = {}

-- 创建新向量
function mathlib.vec2.new(x, y)
    return {x = x or 0, y = y or 0}
end

-- 向量加法
function mathlib.vec2.add(v1, v2)
    return {x = v1.x + v2.x, y = v1.y + v2.y}
end

-- 向量减法
function mathlib.vec2.sub(v1, v2)
    return {x = v1.x - v2.x, y = v1.y - v2.y}
end

-- 向量乘法 (标量)
function mathlib.vec2.mul(v, scalar)
    return {x = v.x * scalar, y = v.y * scalar}
end

-- 向量标准化
function mathlib.vec2.normalize(v)
    local len = math.sqrt(v.x * v.x + v.y * v.y)
    if len > 0 then
        return {x = v.x / len, y = v.y / len}
    end
    return {x = 0, y = 0}
end

-- ====================
-- 插值函数
-- ====================

-- 线性插值
function mathlib.lerp(a, b, t)
    return a + (b - a) * t
end


-- 平滑插值
function mathlib.smoothstep(min, max, value)
    local x = math.max(0, math.min(1, (value - min) / (max - min)))
    return x * x * (3 - 2 * x)
end

-- ====================
-- 动画与插值
-- ====================

-- 平滑过渡到目标值
function mathlib.smooth(value, target, speed)
    if value > target then
        return math.max(value - speed, target)
    elseif value < target then
        return math.min(value + speed, target)
    end
    return value
end

-- 比例平滑（指数衰减）
function mathlib.smoothDamp(current, target, smoothingFactor, dt)
    dt = dt or 1  -- 默认不使用时间缩放
    return current + (target - current) * smoothingFactor * dt
end

-- 带最大速度限制的平滑
function mathlib.smoothClamped(value, target, speed, maxDelta)
    maxDelta = maxDelta or math.huge
    local delta = target - value
    if math.abs(delta) > maxDelta then
        delta = math.sign(delta) * maxDelta
    end
    return mathlib.smooth(value, value + delta, speed)
end

-- ====================
-- 随机函数
-- ====================

-- 在范围内生成随机整数
function mathlib.randomInt(min, max)
    return math.random(min, max)
end

-- 在范围内生成随机浮点数
function mathlib.randomFloat(min, max)
    return min + math.random() * (max - min)
end

-- 从数组中随机选择元素
function mathlib.randomChoice(tbl)
    return tbl[math.random(1, #tbl)]
end

-- ====================
-- 实用工具
-- ====================

-- 颜色转换：HSV 到 RGB
function mathlib.hsvToRgb(h, s, v)
    h = h % 360
    if s <= 0 then return v, v, v end
    
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    
    local r, g, b
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    
    return r + m, g + m, b + m
end

-- 判断是否为素数
function mathlib.isPrime(n)
    if n <= 1 then return false end
    if n == 2 then return true end
    if n % 2 == 0 then return false end
    
    local limit = math.sqrt(n)
    for i = 3, limit, 2 do
        if n % i == 0 then return false end
    end
    return true
end

return mathlib