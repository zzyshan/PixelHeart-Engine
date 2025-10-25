local wave_2 = {}

time = 0
battle.main_arena:Resize(130, 155)
local www = typer.New({"[char_spacing:0][color:0,0,0][font_size:18]* Do you tall me\nwhere that is ?"}, {120, 100}, 2)
www:Bubble(180, 90)
function wave_2.update(dt)
    time = time + 1
    battle.main_arena.angle = 180 * math.sin(time/30)
    if time == 200 then
        wave_2.END = true
        www:Remove()
    end
end

return wave_2