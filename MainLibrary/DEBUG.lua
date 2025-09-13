local DEBUG = {
    switch = true
}

function DEBUG.draw()
    if DEBUG.switch then
        love.graphics.print(tostring(love.timer.getFPS()), 10, 100)
        if Player.soul.mode.var then
        love.graphics.print("currentspeed:" .. tostring(Player.soul.mode.var.currentspeed), 10, 180)
        love.graphics.print("jumping:" .. tostring(Player.soul.mode.var.jumping), 10, 200)
        love.graphics.print("canjump:" .. tostring(Player.soul.mode.var.canjump), 10, 220)
        end
        love.graphics.print("soultable:" .. tostring(#Player.soul), 90, 220)
        Player.DEBUG()
        layers.DEBUG()
        Perf.draw()
    end
end

function DEBUG.isOpen()
    if DEBUG.switch then
        DEBUG.switch = false
    else
        DEBUG.switch = true
    end
end

return DEBUG