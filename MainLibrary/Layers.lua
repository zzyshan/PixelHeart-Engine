local layers = {
    objects = {
        manual = {},
        allTop = {}
    }
}

function layers.sort()
    if #layers.objects.manual <= 1 then return end
   
    table.sort(layers.objects.manual, function(a, b)
        if a.depth == b.depth then
            return a.Createtime < b.Createtime
        else
            return a.depth < b.depth
        end
    end)

    for _, obj in ipairs(layers.objects.manual) do
        if not obj.remove then
            obj:draw()
        end
    end
end

-- 未完成功能,无法使用
function layers.sortTop()
    if #layers.objects.allTop <= 1 then return end
   
    table.sort(layers.objects.allTop, function(a, b)
        if a.depth == b.depth then
            return a.Createtime < b.Createtime
        else
            return a.depth < b.depth
        end
    end)

    for _, obj in ipairs(layers.objects.allTop) do
        if not obj.remove then
            obj:draw()
        end
    end
end

function layers.DEBUG()
    love.graphics.setColor(1, 0, 1)
    for _, bullet in ipairs(layers.objects.manual) do
        if not bullet.remove and bullet.isbullet then
            love.graphics.rectangle("line", 
            bullet.x - bullet:getWidth()*(bullet.pivot.x or 0.5),
            bullet.y - bullet:getHeight()*(bullet.pivot.x or 0.5), 
            bullet:getWidth(), 
            bullet:getHeight())
        end
    end
    
    for _, bullet in ipairs(layers.objects.allTop) do
        if not bullet.remove and bullet.isbullet then
            love.graphics.rectangle("line", 
            bullet.x - bullet:getWidth()*(bullet.pivot.x or 0.5),
            bullet.y - bullet:getHeight()*(bullet.pivot.x or 0.5), 
            bullet:getWidth(), 
            bullet:getHeight())
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function layers.clear()
    layers.objects.manual = {}
end

return layers