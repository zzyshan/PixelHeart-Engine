local WIN = {}

function WIN.update(ui)
    Camera.NewCamera:Setblackalpha(1, 0.05)
    if Camera.NewCamera.black.sprite.alpha == 1 then
        scenes.into(unpack(battle.nextscene))
        Camera.NewCamera:Setblackalpha(0, 1)
    end
end

return WIN