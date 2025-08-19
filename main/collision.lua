local collision = {}

-- 辅助函数：计算对象的实际边界（考虑轴点）
local function getObjectBounds(obj)
    -- 获取尺寸
    local w = obj.Width or (obj.getWidth and obj:getWidth()) or 0
    local h = obj.Height or (obj.getHeight and obj:getHeight()) or 0
    
    -- 获取轴点（默认为中心点）
    local pivotX = obj.pivot and obj.pivot.x or 0.5
    local pivotY = obj.pivot and obj.pivot.y or 0.5
    
    -- 计算左上角位置
    local left = obj.x - w * pivotX
    local top = obj.y - h * pivotY
    
    return {
        left = left,
        top = top,
        right = left + w,
        bottom = top + h,
        width = w,
        height = h,
        centerX = obj.x,
        centerY = obj.y
    }
end

-- 辅助函数：计算旋转后的顶点（考虑轴点）
local function computeRotatedVertices(obj)
    local bounds = getObjectBounds(obj)
    local angle = math.rad(obj.angle or 0)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    
    -- 计算旋转中心（对象位置）
    local centerX, centerY = obj.x, obj.y
    
    -- 四个顶点（相对于轴点）
    local vertices = {
        {x = bounds.left, y = bounds.top},    -- 左上
        {x = bounds.right, y = bounds.top},   -- 右上
        {x = bounds.right, y = bounds.bottom},-- 右下
        {x = bounds.left, y = bounds.bottom}  -- 左下
    }
    
    -- 旋转顶点
    for _, vertex in ipairs(vertices) do
        local dx = vertex.x - centerX
        local dy = vertex.y - centerY
        vertex.x = centerX + dx * cos - dy * sin
        vertex.y = centerY + dx * sin + dy * cos
    end
    
    return vertices
end

-- 辅助函数：计算投影范围
local function project(vertices, axisX, axisY)
    local min = math.huge
    local max = -math.huge
    
    for _, v in ipairs(vertices) do
        local proj = v.x * axisX + v.y * axisY
        min = math.min(min, proj)
        max = math.max(max, proj)
    end
    
    return min, max
end

-- 完美适配任意轴点的AABB碰撞检测
function collision.AABB(obj1, obj2)
    local b1 = getObjectBounds(obj1)
    local b2 = getObjectBounds(obj2)
    
    return b1.left < b2.right and
           b1.right > b2.left and
           b1.top < b2.bottom and
           b1.bottom > b2.top
end

-- 分离轴碰撞检测（支持任意轴点）
function collision.SAT(obj1, obj2)
    -- 圆形-圆形碰撞
    if obj1.radius and obj2.radius then
        local dx = obj1.x - obj2.x
        local dy = obj1.y - obj2.y
        local distanceSq = dx*dx + dy*dy
        local minDistance = obj1.radius + obj2.radius
        return distanceSq <= minDistance*minDistance
    end
    
    -- 圆形-矩形碰撞
    if obj1.radius and not obj2.radius then
        return collision.circleRect(obj1, obj2)
    end
    if obj2.radius and not obj1.radius then
        return collision.circleRect(obj2, obj1)
    end
    
    -- 矩形-矩形碰撞（OBB）
    return collision.OBB(obj1, obj2)
end

-- 圆形与旋转矩形碰撞检测（支持任意轴点）
function collision.circleRect(circle, rect)
    -- 获取矩形边界
    local bounds = getObjectBounds(rect)
    local angle = math.rad(rect.angle or 0)
    
    -- 将圆心转换到矩形局部坐标系
    local dx = circle.x - rect.x
    local dy = circle.y - rect.y
    local localX = dx * math.cos(-angle) - dy * math.sin(-angle)
    local localY = dx * math.sin(-angle) + dy * math.cos(-angle)
    
    -- 计算矩形在局部坐标系的边界
    local halfWidth = bounds.width / 2
    local halfHeight = bounds.height / 2
    
    -- 计算最近点
    local closestX = math.max(-halfWidth, math.min(localX, halfWidth))
    local closestY = math.max(-halfHeight, math.min(localY, halfHeight))
    
    -- 计算距离
    local distX = localX - closestX
    local distY = localY - closestY
    return distX*distX + distY*distY <= circle.radius*circle.radius
end

-- OBB碰撞检测（支持任意轴点）
function collision.OBB(obj1, obj2)
    -- 快速AABB预检测
    if not collision.AABB(obj1, obj2) then
        return false
    end
    
    -- 计算顶点
    local verts1 = computeRotatedVertices(obj1)
    local verts2 = computeRotatedVertices(obj2)
    
    -- 分离轴：两个矩形的边法线
    local axes = {}
    
    -- 添加obj1的边法线
    for i = 1, #verts1 do
        local j = i % #verts1 + 1
        local edgeX = verts1[j].x - verts1[i].x
        local edgeY = verts1[j].y - verts1[i].y
        local length = math.sqrt(edgeX*edgeX + edgeY*edgeY)
        if length > 0 then
            edgeX, edgeY = edgeX/length, edgeY/length
            table.insert(axes, {x = -edgeY, y = edgeX}) -- 法向量
        end
    end
    
    -- 添加obj2的边法线
    for i = 1, #verts2 do
        local j = i % #verts2 + 1
        local edgeX = verts2[j].x - verts2[i].x
        local edgeY = verts2[j].y - verts2[i].y
        local length = math.sqrt(edgeX*edgeX + edgeY*edgeY)
        if length > 0 then
            edgeX, edgeY = edgeX/length, edgeY/length
            table.insert(axes, {x = -edgeY, y = edgeX}) -- 法向量
        end
    end
    
    -- 检查所有分离轴
    for _, axis in ipairs(axes) do
        local min1, max1 = project(verts1, axis.x, axis.y)
        local min2, max2 = project(verts2, axis.x, axis.y)
        
        -- 存在分离轴，无碰撞
        if max1 < min2 or max2 < min1 then
            return false
        end
    end
    
    return true
end

-- 点与旋转矩形碰撞检测（支持任意轴点）
function collision.pointRect(px, py, rect)
    local bounds = getObjectBounds(rect)
    local angle = math.rad(rect.angle or 0)
    
    -- 将点转换到矩形局部坐标系
    local dx = px - rect.x
    local dy = py - rect.y
    local localX = dx * math.cos(-angle) - dy * math.sin(-angle)
    local localY = dx * math.sin(-angle) + dy * math.cos(-angle)
    
    -- 计算矩形在局部坐标系的边界
    local halfWidth = bounds.width / 2
    local halfHeight = bounds.height / 2
    
    -- 检查是否在矩形范围内
    return math.abs(localX) <= halfWidth and math.abs(localY) <= halfHeight
end

-- 点与圆形碰撞检测
function collision.pointCircle(px, py, circle)
    local dx = px - circle.x
    local dy = py - circle.y
    return dx*dx + dy*dy <= circle.radius*circle.radius
end

-- 获取对象的边界框（调试用）
function collision.getDebugBounds(obj)
    return getObjectBounds(obj)
end

return collision