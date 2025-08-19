local RUNAWAY = {}

function RUNAWAY.update(ui)
    Player.sprite.x = mathlib.smooth(Player.sprite.x, -20, 2)
    if Player.sprite.x <= -20 then
        ui.runtime = ui.runtime + 1
    end
    if ui.runtime == 1 then
        Camera.NewCamera:Setblackalpha(1, 0.05)
    end
    
    if ui.runtime >= 21 then
        scenes.into(unpack(battle.nextscene))
        Camera.NewCamera:Setblackalpha(0, 1)
    end
end

return RUNAWAY