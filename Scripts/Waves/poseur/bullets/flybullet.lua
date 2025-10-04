local flybullet = {
    bullets = {}
}

function flybullet.New(position, flyduration, dwelltime, mask)
    local bullet = Sprites.New("froggit/Attacks/spr_flybullet_0.png", position, 2.5)
    bullet:SetAnimation({"froggit/Attacks/spr_flybullet_0.png", "froggit/Attacks/spr_flybullet_1.png"}, 0.5)
    bullet.flyduration = flyduration
    bullet.flytime = 0
    bullet.flyangle = nil
    bullet.dwelltime = dwelltime
    bullet.isfly = true
    bullet.isbullet = true
    bullet:SetStencils(mask)
    
    table.insert(flybullet.bullets, bullet)
    return bullet
end

function flybullet.update(dt)
    for _, bullet in ipairs(flybullet.bullets) do
        if bullet.isfly then
            if bullet.flytime < bullet.flyduration then
                bullet.flytime = bullet.flytime + dt
                if not bullet.flyangle then
                    bullet.flyangle = mathlib.angle(bullet.x, bullet.y, Player.sprite.x, Player.sprite.y)
                end
                local sin, cos = mathlib.direction(bullet.flyangle)
                bullet:Move(sin*2, cos*2)
            else
                bullet.isfly = false
                bullet.flytime = 0
            end
        else
            bullet.flytime = bullet.flytime + dt
            
            if bullet.flytime >= bullet.dwelltime then
                bullet.isfly = true
                bullet.flytime = 0
                bullet.flyangle = nil
            end
        end
    end
end

return flybullet