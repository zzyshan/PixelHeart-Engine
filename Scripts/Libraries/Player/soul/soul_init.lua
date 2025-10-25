local soul = {
    mode = require("Scripts/Libraries/Player/soul/red"),
    box_w = 4,
    box_h = 4
}

function soul.update(dt)
    soul.mode.update(dt)
end

function soul:Setsoul(mode)
    if self.mode and self.mode_name then
        package.loaded[self.mode_name] = nil
    end
    
    self.mode = require("Scripts/Libraries/Player/soul/" .. mode)
    self.mode_name = "Scripts/Libraries/Player/soul/" .. mode
    
    if Player.soul.mode.func then
        -- 创建一个专用的元表
        local meta = {
            __index = function(t, k)
                -- 首先检查模式中是否有这个函数
                if rawget(self.mode, k) then
                    return self.mode[k]
                end
                
                return nil
            end
        }
        
        setmetatable(Player.soul, meta)
    else
        setmetatable(Player.soul, {})
    end
    
    local color = self.mode.color or {1, 1, 1}
    Player.sprite:SetColor(unpack(color))
end

return soul