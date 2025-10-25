local Perf = {
    frames = {},
    currentFrame = 1,
    maxFrames = 60
}

function Perf.update(dt)
    local stats = love.graphics.getStats()
    Perf.frames[Perf.currentFrame] = {
        fps = 1/dt,
        drawcalls = stats.drawcalls,
        textures = stats.textures,
        memory = collectgarbage("count")
    }
    Perf.currentFrame = (Perf.currentFrame % Perf.maxFrames) + 1
end

function Perf.draw()
    love.graphics.setColor(1,1,1)
    for i = 1, math.min(#Perf.frames, Perf.maxFrames) do
        local idx = (Perf.currentFrame - 1 - i) % Perf.maxFrames + 1
        local f = Perf.frames[idx]
        if f then
            local h = 100
            local w = 3
            love.graphics.rectangle("fill", i*w, h - f.fps, w-1, f.fps)
            love.graphics.rectangle("fill", i*w, h + 50 - f.drawcalls/2, w-1, f.drawcalls/2)
        end
    end
end

return Perf