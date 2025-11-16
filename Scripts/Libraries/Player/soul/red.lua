local red = {
    color = {1, 0, 0}
}

function red.update(dt)
    if input.isKeyDown("x") then
        Player.speed = 90
    else
        Player.speed = 180
    end
    
    if Player.canmove then
        if input.isKeyDown("up", "w") then
            Player.sprite:Move(0, -(Player.speed * dt))
            Player.ismove = true
        end
        if input.isKeyDown("down", "s") then
            Player.sprite:Move(0, (Player.speed * dt))
            Player.ismove = true
        end
        if input.isKeyDown("left", "a") then
            Player.sprite:Move(-(Player.speed * dt), 0)
            Player.ismove = true
        end
        if input.isKeyDown("right", "d") then
            Player.sprite:Move((Player.speed * dt), 0)
            Player.ismove = true
        end
    end
end

return red