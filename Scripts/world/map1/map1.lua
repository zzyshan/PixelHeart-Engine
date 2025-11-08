local map1 = {}

local body = love.physics.newBody(overworld.world, 320, 300, "static")
local shape = love.physics.newRectangleShape(640, 10)
local fixture = love.physics.newFixture(body, shape)

function map1.load()
end

function map1.update(dt)
end

function map1.draw()
end

return map1