local butterflybullet = {
    bullets = {}
}

function butterflybullet.New(position, mask)
    local bullet = Sprites.New("whimsun/Attacks/spr_butterflybullet_0.png", position, 2.5)
    bullet:SetAnimation({"whimsun/Attacks/spr_butterflybullet_0.png", "whimsun/Attacks/spr_butterflybullet_1.png"}, 0.25)
    bullet.isbullet = true
    bullet:SetStencils(mask)
    
    return bullet
end

function butterflybullet.NewCircle(position, radius, num, mask)
    local Circle = {}
    Circle.x, Circle.y = unpack(position)
    Circle.radius = radius
    Circle.angle = 0
    Circle.bullets = {}
    for i = 1, num do
        local angle = (360 / num) * i
        local X, Y = mathlib.direction(angle)
        X, Y = Circle.x + X * Circle.radius, Circle.y + Y * Circle.radius
        local bullet = butterflybullet.New({X, Y}, mask)
        local FaceAngle = math.deg(mathlib.angle(bullet.x, bullet.y, Circle.x, Circle.y)) + 90
        bullet.angle = FaceAngle
        
        table.insert(Circle.bullets, bullet)
    end
    
    table.insert(butterflybullet.bullets, Circle)
    return Circle
end

function butterflybullet.update()
    for _, Circle in ipairs(butterflybullet.bullets) do
        for i = 1, #Circle.bullets do
            local bullet = Circle.bullets[i]
            local angle = (360 / #Circle.bullets) * (i - 1) + Circle.angle
            local X, Y = mathlib.direction(angle)
            X, Y = Circle.x + X * Circle.radius, Circle.y + Y * Circle.radius
            bullet:MoveTo(X, Y)
            local FaceAngle = math.deg(mathlib.angle(bullet.x, bullet.y, Circle.x, Circle.y)) + 90
            bullet.angle = FaceAngle
        end
    end
end

return butterflybullet