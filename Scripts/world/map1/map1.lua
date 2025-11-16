local map1 = {}

local body = love.physics.newBody(overworld.world, 320, 300, "static")
local shape = love.physics.newRectangleShape(640, 10)
local fixture = love.physics.newFixture(body, shape)

local intobattle = Sprites.New("px.png", {480, 100}, 1, {b = 0, g = 0})
intobattle:SetScale(30, 30)
local music = Audio.PlayMusic("field_of_hopes.ogg", true)

function map1.load()
end

function map1.update(dt)
    local isinto = collision.AABB(Player.sprite, intobattle)
    if isinto then
        scenes.into("battle", {BATTLE = "poseur"})
        music:stop()
    end
end

function map1.draw()
end

return map1