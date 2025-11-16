local Overworld_init = {}

overworld = require("Scripts/world/" .. (scenes.var.WORLD or save.GetVariable("room", 1)) .. "/init")

overworld.path = "Scripts/world/" .. (scenes.var.WORLD or save.GetVariable("room", 1)) .. "/"
overworld.world = love.physics.newWorld(0, 0, true)
overworld.newmap = require(overworld.path .. overworld.map)

function Overworld_init.load()
    scenes.Settype("Overworld")
    save.load(1)
    Player.init(overworld.startmark, {direction = overworld.direction})
    
    --local pb = Sprites.New("OVER WORLD 640 480.png", {255, 195})
end

function Overworld_init.update(dt)
    overworld.world:update(dt)
    if overworld.newmap.update then
        overworld.newmap.update(dt)
    end
end

function Overworld_init.draw()
end

function Overworld_init.over()
    Sprites.clear()
    typer.clear()
end

return Overworld_init