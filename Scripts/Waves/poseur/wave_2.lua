local wave_2 = {}

time = 0
battle.main_arena:Resize(130, 155)
function wave_2.update(dt)
    time = time + 1
    battle.main_arena.angle = 180 * math.sin(time/30)
    if time == 500 then
        wave_2.END = true
    end
end

return wave_2