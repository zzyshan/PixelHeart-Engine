local wave_1 = {}

time = 0

bullet = Sprites.New("bullet.png", {320, 100}, 3)
mask = masks.New("rectangle", {320, 250}, 155, 130, 0, 1)
bullet:SetStencils({mask})
bullet2 = Sprites.New("bullet.png", {220, 320}, 3)
bullet2.isbullet = true
bullet.isbullet = true
function wave_1.update(dt)
    mask:Follow(battle.main_arena.black)
    time = time + 1
    battle.main_arena.angle = 30 * math.sin(time/50)
    if tt then
    tt.y = 320 + 100 * math.sin(time/50)
    end
    if time == 10 then
        --Player.soul:Setsoul("blue")
    end
    if time == 400 then
        --Player.soul.BlueSlam("right", -90)
    end
    if time == 800 then
        Player.soul:Setsoul("red")
        tt = Arenas.new({320,320}, 135, 135, 0, "rectangle", "plus")
    end
    if time == 120000 then
        wave_1.END = true
        Sprites.bulletclear()
    end
    bullet.y = 300 + 100 * math.sin(time / 30)
end

return wave_1