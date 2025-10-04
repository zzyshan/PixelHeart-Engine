local WIN = {}

function WIN.update(ui)
    Camera.NewCamera:Setcovercolor(0, 0, 0)
    Camera.NewCamera:Setcoveralpha(1, 0.05)
    if Camera.NewCamera.cover.sprite.alpha == 1 then
        scenes.into(unpack(battle.nextscene))
        Camera.NewCamera:Setcoveralpha(0, 1)
    end
end

return WIN