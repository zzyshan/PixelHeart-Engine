local ANIMING = {}

function ANIMING.update(dt, ui)
    local anim_path = battle.path .. "/anim/" .. battle.nextanim
    battle.anim = require(anim_path)
    if battle.anim then
        if not battle.anim.END then
            battle.anim.update(dt, ui)
        else
            battle.anim.END = false
            package.loaded[anim_path] = nil
            battle.nextanim = nil
            battle.anim = nil
        end
    end
end

return ANIMING