local Camera = {
    cameras = {},
    NewCamera = nil
}

local camera_function = {
    update = function(camera, dt)
        -- 更新相机震动
        if camera.shake.timer > 0 then
            camera.shake.timer = camera.shake.timer - dt
        end
        
        camera.cover.sprite.alpha = mathlib.smooth(camera.cover.sprite.alpha, camera.cover.newalpha, camera.cover.speed)
        camera.cover.sprite:MoveTo(320 + camera.x, 240 + camera.y)
    end,
    Move = function(camera, xspeed, yspeed)
        camera.x = camera.x + xspeed
        camera.y = camera.y + yspeed
    end,
    SetPosition = function(camera, position)
        camera.x = position[1]
        camera.y = position[2]
    end,
    SetScale = function(camera, xscale, yscale)
        camera.scale.x = xscale
        camera.scale.y = yscale
    end,
    SetRotation = function(camera, rot)
        camera.rotation = rot
    end,
    --设置边界
    SetBounds = function(camera, x, y, w, h)
        camera.bounds = {x = x, y = y, w = w, h = h}
    end,
    Setcoveralpha = function(camera, alpha, speed)
        camera.cover.newalpha = alpha
        camera.cover.speed = speed
    end,
    Setcovercolor = function(camera, r, g, b)
        camera.cover.sprite:SetColor(r, g, b)
    end,
    SetShake = function(camera, power, duration)
        camera.shake.power = power
        camera.shake.timer = duration
    end,
    -- 应用相机变换
    apply = function(camera)
        -- 应用相机震动
        local offsetx, offsety = 0, 0
        if camera.shake.timer > 0 then
            offsetx = camera.shake.power * math.random(-1, 1)
            offsety = camera.shake.power * math.random(-1, 1)
        end
        love.graphics.push()
    
        -- 应用基本变换
        love.graphics.translate(camera.centerX, camera.centerY)
        love.graphics.rotate(math.rad(camera.rotation))
        love.graphics.scale(camera.scale.x, camera.scale.y)
        love.graphics.translate(-camera.x + offsetx - camera.centerX, -camera.y + offsety - camera.centerY)
    end,
    -- 结束相机变换
    detach = function(camera)
        love.graphics.pop()
    end,
    Remove = function(camera)
        camera.remove = true
        for i = #Camera.cameras, 1, -1 do
            if Camera.cameras[i] == camera then
                Camera.cameras[i] = nil
                table.remove(Camera.cameras, i)
                break
            end
        end
    end
}
camera_function.__index = camera_function
function Camera.new()
    local camera = setmetatable({}, camera_function)
    camera.x = 0
    camera.y = 0
    camera.centerX = love.graphics.getWidth() / 2
    camera.centerY = love.graphics.getHeight() / 2
    camera.scale = {x = 1, y = 1}
    camera.rotation = 0
    camera.bounds = {x = 0, y = 0, w = 640, h = 480}
    camera.shake = {power = 0, timer = 0}
    camera.smoothness = 0.1
    camera.cover = {sprite = Sprites.New("px.png", {}, 1145, {xscale = 1145, yscale = 1145, r = 0, b = 0, g = 0}), speed = 0.05, newalpha = 0}
    camera.cover.sprite.alpha = 0
    camera.remove = false
    table.insert(Camera.cameras, camera)
    return camera
end

function Camera.update(dt)
    for _, camera in ipairs(Camera.cameras) do
        if not camera.remove then
            camera:update(dt)
        end
    end
end

function Camera.SetCamera(camera)
    if camera then
        Camera.NewCamera = camera
        print("en.Camera set up")
    else
        print("en.Camera doesn't exist?")
    end
end

return Camera