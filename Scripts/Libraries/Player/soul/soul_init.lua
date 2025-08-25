local soul = {
    mode = require("Scripts/Libraries/Player/soul/red"),
    box_w = 4,
    box_h = 4
}

function soul.update(dt)
    soul.mode.update(dt)
end

function soul.setMode(mode)
    soul.mode = require("Scripts/Libraries/Player/soul/" .. mode)
end

return soul