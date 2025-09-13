local red = {
    color = {1, 0, 0}
}

function red.update(dt)
    if Keyboard.getState("x") > 0 then
        Player.speed = 90
    else
        Player.speed = 180
    end
    
    if Player.canmove then
        if Keyboard.getState("up", "w") > 0 and Player.canmove then
            Player.sprite:Move(0, -(Player.speed * dt))
            Player.ismove = true
        end
        if Keyboard.getState("down", "s") > 0 and Player.canmove then
            Player.sprite:Move(0, (Player.speed * dt))
            Player.ismove = true
        end
        if Keyboard.getState("left", "a") > 0 and Player.canmove then
            Player.sprite:Move(-(Player.speed * dt), 0)
            Player.ismove = true
        end
        if Keyboard.getState("right", "d") > 0 and Player.canmove then
            Player.sprite:Move((Player.speed * dt), 0)
            Player.ismove = true
        end
    end
end

return red