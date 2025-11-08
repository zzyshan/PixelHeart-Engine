local blue = {
    color = {0, 0, 1},
    name = "bluesoul",
    var = {
        gravity = 0.15,
        glide = 1,
        maxspeed = 5,
        currentspeed = 0,
        canjump = false,
        jumping = true,
        direction = "down",
        platforms = {},
        iscolliding = false,
        
        slamhp = 0,
        slamtime = 0
    }
}

function blue.update(dt)
    if Keyboard.isDown("x") then
        Player.speed = 90
    else
        Player.speed = 180
    end
    
    if Player.canmove then
        local speed_dt = Player.speed * dt
        local cos, sin = math.cos(Player.sprite.angle), math.sin(Player.sprite.angle)
        local var = blue.var
        
        if var.direction == "down" then
            if Keyboard.isDown("left") then
                Player.sprite:Move(-speed_dt * cos, -speed_dt * sin)
            end
            if Keyboard.isDown("right") then
                Player.sprite:Move(speed_dt * cos, speed_dt * sin)
            end
            if var.canjump or var.iscolliding then
                if (math.abs(var.currentspeed) < 10) then var.currentspeed = 0 end
            end
            
            if Keyboard.isDown("up") and var.canjump then
                var.currentspeed = var.maxspeed
                var.canjump = false
                var.jumping = true
            end
            
            if var.jumping then
                if Keyboard.isDown("up") then
                    var.currentspeed = var.currentspeed - var.gravity
                else
                    if (var.currentspeed > var.glide) then
                        var.currentspeed = var.glide
                    end
                    var.jumping = false
                end
            else
                var.currentspeed = var.currentspeed - var.gravity
            end
            
            Player.sprite:Move(var.currentspeed * sin, -var.currentspeed * cos)
        elseif var.direction == "up" then
            if Keyboard.isDown("left") then
                Player.sprite:Move(speed_dt * cos, speed_dt * sin)
            end
            if Keyboard.isDown("right") then
                Player.sprite:Move(- speed_dt * cos, - speed_dt * sin)
            end
            if var.canjump or var.iscolliding then
                if (math.abs(var.currentspeed) < 10) then var.currentspeed = 0 end
            end
            
            if Keyboard.isDown("down") and var.canjump then
                var.currentspeed = var.maxspeed
                var.canjump = false
                var.jumping = true
            end
            
            if var.jumping then
                if Keyboard.isDown("down") then
                    var.currentspeed = var.currentspeed - var.gravity
                else
                    if (var.currentspeed > var.glide) then
                        var.currentspeed = var.glide
                    end
                    var.jumping = false
                end
            else
                var.currentspeed = var.currentspeed - var.gravity
            end
            
            Player.sprite:Move(var.currentspeed * sin, -var.currentspeed * cos)
        elseif var.direction == "left" then
            if Keyboard.isDown("up") then
                Player.sprite:Move(- speed_dt * cos, - speed_dt * sin)
            end
            if Keyboard.isDown("down") then
                Player.sprite:Move(speed_dt * cos, speed_dt * sin)
            end
            if var.canjump or var.iscolliding then
                if (math.abs(var.currentspeed) < 10) then var.currentspeed = 0 end
            end
            
            if Keyboard.isDown("right") and var.canjump then
                var.currentspeed = var.maxspeed
                var.canjump = false
                var.jumping = true
            end
            
            if var.jumping then
                if Keyboard.isDown("right") then
                    var.currentspeed = var.currentspeed - var.gravity
                else
                    if (var.currentspeed > var.glide) then
                        var.currentspeed = var.glide
                    end
                    var.jumping = false
                end
            else
                var.currentspeed = var.currentspeed - var.gravity
            end
            
            Player.sprite:Move(var.currentspeed * sin, -var.currentspeed * cos)
        elseif var.direction == "right" then
            if Keyboard.isDown("up") then
                Player.sprite:Move(speed_dt * cos, speed_dt * sin)
            end
            if Keyboard.isDown("down") then
                Player.sprite:Move(- speed_dt * cos, - speed_dt * sin)
            end
            if var.canjump or var.iscolliding then
                if (math.abs(var.currentspeed) < 10) then var.currentspeed = 0 end
            end
            
            if Keyboard.isDown("left") and var.canjump then
                var.currentspeed = var.maxspeed
                var.canjump = false
                var.jumping = true
            end
            
            if var.jumping then
                if Keyboard.isDown("left") then
                    var.currentspeed = var.currentspeed - var.gravity
                else
                    if (var.currentspeed > var.glide) then
                        var.currentspeed = var.glide
                    end
                    var.jumping = false
                end
            else
                var.currentspeed = var.currentspeed - var.gravity
            end
            
            Player.sprite:Move(var.currentspeed * sin, -var.currentspeed * cos)
        end
    end
end

function blue.BlueSlam(direction, angle, hp, invtime)
    local vars = blue.var
    vars.slamming = true
    vars.canjump = false
    vars.direction = direction or "down"
    Player.sprite.angle = angle
    vars.currentspd = -15
    vars.slamhp = hp or 0
    vars.slaminvtime = invtime or 0
end

return blue