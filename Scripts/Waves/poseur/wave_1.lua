local wave_1 = {}

time = 0
bullet = Sprites.New("bullet.png", {320, 100}, 3)
mask = masks.New("rectangle", {320, 250}, 155, 130, 0, 1)
bullet:SetStencils({mask})
bullet2 = Sprites.New("bullet.png", {220, 320}, 3)
bullet.isbullet = true
bullet2.isbullet = true
function wave_1.update(dt)
    mask:Follow(battle.main_arena.black)
    time = time + 1
    if time == 500 then
        wave_1.END = true
        Sprites.bulletclear()
    end
    bullet.y = 300 + 100 * math.sin(time / 30)
end

return wave_1