local DEBUG = {
    switch = false
}

function DEBUG.draw()
    if DEBUG.switch then
        love.graphics.print(tostring(love.timer.getFPS()), 10, 100)
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