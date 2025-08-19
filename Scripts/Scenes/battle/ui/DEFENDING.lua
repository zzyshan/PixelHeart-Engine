local DEFENDING = {}

function DEFENDING.update(ui)
    battle.wave = require("Scripts/Waves/" .. scenes.BATTLE .. "/" .. battle.nextwave)
    if battle.wave then
        if not battle.wave.END then
            battle.wave.update(dt)
        else
            battle.wave.END = false
            package.loaded["Scripts/Waves/" .. scenes.BATTLE .. "/" .. battle.nextwave] = nil
            battle.waveindex = battle.waveindex + 1
            if battle.waveindex > #battle.nextwaves then
                battle.waveindex = 1
            end
            battle.nextwave = battle.nextwaves[battle.waveindex]
            battle.DefenseEnding()
            STATE("ACTIONSELECT")
        end
    end
    
    for _, bullet in ipairs(layers.objects.manual) do
        if not bullet.remove and bullet.isbullet then
            if collision.SAT(bullet, {
                x = Player.sprite.x,
                y = Player.sprite.y,
                angle = Player.sprite.angle,
                Width = Player.battle.box.Width,
                Height = Player.battle.box.Height
            }) and not Player.hurting then
                OnHit(bullet)
            end
        end
    end
end

return DEFENDING