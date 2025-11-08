local red = {
    color = {1, 0, 0}
}

function red.update(dt)
    if Keyboard.isDown("x") then
        Player.speed = 90
    else
        Player.speed = 180
    end
    
    if Player.canmove then
        if Keyboard.isDown("up", "w") then
            Player.sprite:Move(0, -(Player.speed * dt))
            Player.ismove = true
        end
        if Keyboard.isDown("down", "s") then
            Player.sprite:Move(0, (Player.speed * dt))
            Player.ismove = true
        end
        if Keyboard.isDown("left", "a") then
            Player.sprite:Move(-(Player.speed * dt), 0)
            Player.ismove = true
        end
        if Keyboard.isDown("right", "d") then
            Player.sprite:Move((Player.speed * dt), 0)
            Player.ismove = true
        end
    end
end

return red