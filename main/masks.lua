-- 尝试换了一下写库的风格(虽然大抵还是一样),有借鉴end
local masks = {
    obj = {}
}

local mt = { __index = masks }

function masks.New(shape, position, w, h, r, value)
    local mask = setmetatable({
        shape = shape,
        x = position[1],
        y = position[2],
        w = w,
        h = h,
        angle = r or 0,  -- 确保有默认值
        value = value or 1,
        isactive = true
    }, mt)
    table.insert(masks.obj, mask)
    return mask
end

---------- mask方法 --------------
function masks:Move(xspeed, yspeed)
    self.x = self.x + xspeed
    self.y = self.y + yspeed
end

function masks:MoveTo(position)
    self.x = position[1]
    self.y = position[2]
end

function masks:Resize(w, h)
    self.w = w
    self.h = h
end

function masks:Remove()
    self.isactive = false
    for i = #masks.obj, 1, -1 do
        if masks.obj[i] == self then
            table.remove(masks.obj, i)
            break
        end
    end
end

function masks:Follow(target)
    self.x = target.x
    self.y = target.y
    self.angle = target.angle or 0
    self.w = target:getWidth()
    self.h = target:getHeight()
end

function masks:Setactive(bool)
    self.isactive = bool
end
---------- 结束 --------------

function masks.setTest(comparemode, value)
    love.graphics.setStencilTest(comparemode or "greater", value or 1)
end

function masks.reset()
    love.graphics.setStencilTest()
end

function masks.draw(tableaux)
    love.graphics.stencil(function()
        for _, mask in ipairs(tableaux) do
            if mask.isactive then
                love.graphics.push()
                -- 切换坐标轴的位置和角度,使得mask到相应的位置
                love.graphics.translate(mask.x, mask.y)
                love.graphics.rotate(mask.angle)
                
                if mask.shape == "rectangle" then
                    love.graphics.rectangle("fill", -mask.w/2, -mask.h/2, mask.w, mask.h)
                elseif (mask.shape == "circle") then
                    love.graphics.ellipse("fill", 0, 0, mask.w, mask.h)
                end
                
                love.graphics.pop()
            end
        end
    end, "increment", 1)
end

return masks