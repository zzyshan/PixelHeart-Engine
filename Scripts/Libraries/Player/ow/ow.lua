local ow = {
    menu = require("Scripts/Libraries/Player/ow/menu")
}

local Correspondingkey = {
    up = "down",
    down = "up",
    left = "right",
    right = "left"
}

local function findMainDirection(direction)
    local py_rot = Player.overworld.direction
    local Correspondkey = Correspondingkey[direction]
    local Correspondpy_rot = Correspondingkey[py_rot]
    if direction == py_rot then --如果方向等于人物朝向
        if input.isKeyDown(Correspondkey) then
            return py_rot
        else
            Player.ismove = true
            return py_rot
        end
    else
        if input.isKeyDown(py_rot) then
            if not input.isKeyDown(Correspondpy_rot) then
                return py_rot
            else
                if input.isKeyDown(Correspondkey) then
                    return py_rot
                else
                    Player.ismove = true
                    Player.overworld.direction = direction
                    return direction
                end
            end
        else
            if input.isKeyDown(Correspondkey) then
                return py_rot
            else
                Player.ismove = true
                Player.overworld.direction = direction
                return direction
            end
        end
    end
end

function ow.update(dt)
    ow.menu:update()
    
    if Player.canmove then
        local py_ow = Player.overworld
        
        if input.isKeyDown("up") then
            py_ow.MainDirection = findMainDirection("up") or py_ow.MainDirection
        end
        if input.isKeyDown("down") then
            py_ow.MainDirection = findMainDirection("down") or py_ow.MainDirection
        end
        if input.isKeyDown("left") then
            py_ow.MainDirection = findMainDirection("left") or py_ow.MainDirection
        end
        if input.isKeyDown("right") then
            py_ow.MainDirection = findMainDirection("right") or py_ow.MainDirection
        end
        
        if input.isKeyDown("c") then
            ow.menu.show()
        end
        
        local VelocityX, VelocityY = 0, 0
        if Player.ismove then
            if input.isKeyDown("up", "w") then
                VelocityY = -Player.speed
            end
            if input.isKeyDown("down", "s") then
                VelocityY = Player.speed
            end
            if input.isKeyDown("left", "a") then
                VelocityX = -Player.speed
            end
            if input.isKeyDown("right", "d") then
                VelocityX = Player.speed
            end
            
            py_ow.animTimer = py_ow.animTimer + dt
            
            if py_ow.animTimer >= py_ow.animSpeed then
                if py_ow.anim < 3 then
                    py_ow.anim = py_ow.anim + 1
                else
                    py_ow.anim = 0
                end
                
                Player.sprite:Set("Overworld/Character/" .. py_ow.MainDirection .."_" .. py_ow.anim .. ".png")
                py_ow.animTimer = 0
            end
            
            if not input.isKeyDown("up") and not input.isKeyDown("down") and not input.isKeyDown("left") and not input.isKeyDown("right") then
                Player.ismove = false
                py_ow.anim = 0
                py_ow.animTimer = 0
                py_ow.direction = py_ow.MainDirection
                py_ow.MainDirection = nil
                Player.sprite:Set("Overworld/Character/" .. py_ow.direction .."_" .. py_ow.anim .. ".png")
            end
        end
        
        if py_ow.body then
            Player.sprite:MoveTo(
                py_ow.body:getX(),
                py_ow.body:getY() - 20
            )
            py_ow.body:setLinearVelocity(VelocityX, VelocityY)
        end
    end
end

return ow