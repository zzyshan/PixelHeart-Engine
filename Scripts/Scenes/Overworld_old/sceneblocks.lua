local sbs = {
    blocks = {},    -- 碰撞块
    triggers = {},  -- 触发器
    landmarks = {}, -- 地标
    objects = {},   -- 游戏对象
    sprites = {},   -- 临时精灵
    belts = {},     -- 传送带
    page = 0,       -- 当前页面状态
    choosing = 0,   -- 选择菜单选项
}

local Player
local oneframe = false
local zKeyCooldown = 0 -- Z键冷却时间

-------- 辅助函数 ----------------
-- 获取玩家碰撞箱
local function getPlayerCollider(player)
    -- 玩家碰撞箱参数
    local spriteW, spriteH = player.sprite:getwidth(), player.sprite:getheight()
    
    -- 碰撞箱参数（可根据需要调整）
    local pColW = spriteW * 0.7    -- 宽度为精灵的70%
    local pColH = spriteH * 0.4     -- 高度为精灵的40%
    local pColYOffset = spriteH * 0.3  -- 碰撞箱下移30%
    
    return {
        x = player.sprite.x,
        y = player.sprite.y + pColYOffset,
        w = pColW,
        h = pColH
    }
end

local function checkCollision(player, block)
    local pCol = getPlayerCollider(player)
    
    -- 方块参数
    local bw, bh = block:getwidth(), block:getheight()
    local bx, by = block.x, block.y
    local angle = math.rad(block.angle or 0)
    
    -- 转换到局部坐标系（以block为中心）
    local cos, sin = math.cos(angle), math.sin(angle)
    local localX = (pCol.x - bx) * cos + (pCol.y - by) * sin
    local localY = -(pCol.x - bx) * sin + (pCol.y - by) * cos
    
    -- 检测碰撞
    if math.abs(localX) < (pCol.w + bw)/2 and math.abs(localY) < (pCol.h + bh)/2 then
        -- 计算重叠量
        local overlapX = (pCol.w + bw)/2 - math.abs(localX)
        local overlapY = (pCol.h + bh)/2 - math.abs(localY)
        
        -- 优先处理较小的重叠量（更自然的碰撞响应）
        if overlapY < overlapX then
            -- Y方向碰撞（上下）
            local correctionY = overlapY * (localY > 0 and 1 or -1)
            player.sprite.x = player.sprite.x - correctionY * sin
            player.sprite.y = player.sprite.y + correctionY * cos
            return "vertical"
        else
            -- X方向碰撞（左右）
            local correctionX = overlapX * (localX > 0 and 1 or -1)
            player.sprite.x = player.sprite.x + correctionX * cos
            player.sprite.y = player.sprite.y + correctionX * sin
            return "horizontal"
        end
    end
    return nil
end

-- 检测玩家与触发器的碰撞
local function checkTrigger(player, trigger)
    local pCol = getPlayerCollider(player)
    local tw, th = trigger:getwidth(), trigger:getheight()
    local angle = math.rad(trigger.angle or 0)
    local cos, sin = math.cos(angle), math.sin(angle)
    
    -- 转换到局部坐标系
    local localX = (pCol.x - trigger.x) * cos + (pCol.y - trigger.y) * sin
    local localY = -(pCol.x - trigger.x) * sin + (pCol.y - trigger.y) * cos
    
    return math.abs(localX) < (tw + pCol.w)/2 and math.abs(localY) < (th + pCol.h)/2
end
-------- 主要函数 ----------------
-- 创建碰撞块
function sbs.Block(x, y, w, h, r, ishide)
    local block = image.CreateImage("px.png", {x, y})
    block:SetScale(w, h)
    block.angle = r or 0
    block:SetColor(0, 1, 1)
    block.alpha = 0.5
    block.hide = ishide == nil or ishide
    table.insert(sbs.blocks, block)
    return block
end

-- 创建触发器
function sbs.Trigger(x, y, w, h, r, attached, ishide)
    local trigger = image.CreateImage("px.png", {x, y})
    trigger:SetScale(w, h)
    trigger.angle = r or 0
    trigger:SetColor(0.5, 0, 1) -- 默认紫色
    trigger.alpha = 0.5
    trigger.hide = ishide == nil or ishide
    trigger.attached = attached
    trigger.contain = false
    trigger.activated = false
    trigger.TIMES = 0
    trigger.cutloop = false
    trigger.dialog = attached[2]
    trigger.state = false -- 拉杆状态（默认关闭）

    -- 设置类型特定属性
    if attached[1] == "lever" then
        trigger:SetColor(1, 0.5, 0) -- 拉杆设为橙色
    end

    -- 触发器方法
    trigger.GetTimes = function() return trigger.TIMES end
    trigger.SetText = function(texts)
        if attached[1] == "dialog" or attached[1] == "dialog-z" then
            trigger.dialog = texts
        else
            error("Attempt to set text of non-dialog trigger", 2)
        end
    end
    trigger.Toggle = function()
        trigger.state = not trigger.state
        if trigger.attached.callback then
            trigger.attached.callback(trigger.state)
        end
        return true
    end

    table.insert(sbs.triggers, trigger)
    return trigger
end

-- 创建地标
function sbs.Landmark(x, y, ishide)
    local landmark = image.CreateImage("px.png", {x, y})
    landmark:SetColor(1, 0, 0)
    landmark.angle = 45
    landmark:SetScale(16, 16)
    landmark.alpha = 0.5
    landmark.hide = ishide == nil or ishide
    table.insert(sbs.landmarks, landmark)
    return landmark
end

-- 创建存档点
function sbs.SavePoint(x, y, dialog, place, landmarkIndex)
    local saveObj = image.CreateImage("overworld/Objects/sp_0.png", {x, y}, 2)
    saveObj:SetAnimation({
        "overworld/Objects/sp_0.png",
        "overworld/Objects/sp_1.png"
    }, 0.5)

    -- 添加碰撞块和触发器
    sbs.Block(x, y, 40, 20, 0)
    local trigger = sbs.Trigger(x, y, 42, 22, 0, {"savepoint"})
    
    -- 设置存档点属性
    trigger.dialog = dialog or "在存档点休息一下？"
    trigger.place = place or "存档点"
    trigger.landmarkIndex = landmarkIndex or 1
    
    table.insert(sbs.objects, saveObj)
    return trigger
end

-- 更新场景
function sbs.update(dt)
    if not Player or not Player.sprite then return end
    
    -- 更新Z键冷却时间
    if zKeyCooldown > 0 then zKeyCooldown = zKeyCooldown - dt end
    
    -- 方块碰撞检测
    for _, block in ipairs(sbs.blocks) do
        if block and block.x then checkCollision(Player, block) end
    end
    
    -- 触发器检测
    for _, trigger in ipairs(sbs.triggers) do
        if trigger and trigger.x then
            local event = trigger.attached[1]
            trigger.contain = checkTrigger(Player, trigger)
            
            -- 更新激活状态
            trigger.activated = trigger.contain
            if not trigger.contain then trigger.cutloop = false end
            
            -- 处理激活的触发器
            if trigger.activated then
                if event == "warp" then
                    -- 传送逻辑
                    local rm = trigger.attached[2] -- 房间
                    local lm = trigger.attached[3] -- 地标
                    save.SetVariable("landmark", lm)
                    Overworld_into(rm)
                
                elseif event == "dialog" then
                    -- 普通对话框
                    if not trigger.cutloop then
                        if sbs.page == 2 and sbs.text.endof then
                            -- 结束对话框
                            sbs.text:Remove()
                            Player.canmove = true
                            trigger.TIMES = trigger.TIMES + 1
                            trigger.cutloop = true
                            sbs.page = 0
                            oneframe = true
                        elseif sbs.page == 1 then
                            -- 创建对话框
                            local positionY =  (Player.sprite.y >= 240) and 100 or 380
                            sbs.text = typer.Dialog(trigger.dialog, {320, positionY}, "Determination.ttf", "uifont.wav")
                            sbs.page = 2
                        elseif sbs.page == 0 and not oneframe then
                            -- 开始对话框
                            Player.canmove = false
                            sbs.page = 1
                        end
                    end
                
                elseif event == "dialog-z" then
                    -- 按Z键继续的对话框
                    if sbs.page == 2 and sbs.text.endof and Keyboard.getState("z") == 1 and zKeyCooldown <= 0 then
                        -- 结束对话框
                        sbs.text:Remove()
                        Player.canmove = true
                        trigger.TIMES = trigger.TIMES + 1
                        sbs.page = 0
                        oneframe = true
                        zKeyCooldown = 0.3
                    elseif sbs.page == 1 then
                        -- 创建对话框
                        local positionY =  (Player.sprite.y >= 240) and 100 or 380
                        sbs.text = typer.Dialog(trigger.dialog, {320, positionY}, "Determination.ttf", "uifont.wav")
                        sbs.page = 2
                    elseif Keyboard.getState("z") == 1 and sbs.page == 0 and not oneframe and zKeyCooldown <= 0 then
                        -- 开始对话框
                        Player.canmove = false
                        sbs.page = 1
                        zKeyCooldown = 0.3
                    end
                
                elseif event == "lever" then
                    -- 拉杆交互
                    if Keyboard.getState("z") == 1 and zKeyCooldown <= 0 then
                        trigger:Toggle()
                        zKeyCooldown = 0.3
                        trigger:SetColor(trigger.state and 0.5 or 1, 0.5, 0)
                    end
                
                elseif event == "savepoint" then
                    -- 存档点处理
                    if sbs.page == 4 then
                        sbs.text:Remove()
                        sbs.save:Remove()
                        sbs.board:Remove()
                        if sbs.return_ then
                            sbs.return_:Remove()
                        end
                        if sbs.player then
                            sbs.player:Remove()
                        end
                        Player.canmove = true
                        trigger.TIMES = trigger.TIMES + 1
                        sbs.page = 0
                        oneframe = true
                        zKeyCooldown = 0.3
                    end
                    if sbs.page == 0 and zKeyCooldown <= 0 then
                        if Keyboard.getState("z") == 1 then
                            local positionY =  (Player.sprite.y >= 240) and 100 or 380
                            sbs.text = typer.Dialog(trigger.dialog, {320, positionY}, "Determination.ttf", "uifont.wav")
                            sbs.text.over = function()
                                sbs.text:Remove()
                                sbs.page = 2
                                sbs.board = image.CreateImage("overworld/Menu/save.png", {320, 240},4)
                                sbs.text = typer.CreateText({"[instant]" .. save.GetVariable("player.name", 1) .. "[movetoX:280]LV " .. save.GetVariable("player.lv", 1) .. "[movetoX:440]" .. save.GetVariable("meta.playTime", 1) .. "[movetoY:230][movetoX:130]" .. trigger.place}, {130, 175}, "Determination.ttf", {}, {}, 5)
                                sbs.save = typer.CreateText({"[instant]保存"}, {200, 275}, "Determination.ttf", {}, {}, 5)
                                sbs.return_ = typer.CreateText({"[instant]返回"}, {380, 275}, "Determination.ttf", {}, {}, 5)
                                sbs.player = image.CreateImage("overworld/Menu/ut-heart.png", {182, 290}, 5, {
                                g = 0,
                                b = 0,
                                scale = {x = 1.1, y = 1.1}
                                })
                                sbs.player.step = 1
                                zKeyCooldown = 0.3
                            end
                            sbs.page = 1
                            Player.canmove = false
                        end
                    end
                    
                    if sbs.page == 2 then
                        if sbs.player.step == 1 then
                            sbs.player.x = 182
                        elseif sbs.player.step == 2 then
                            sbs.player.x = 362
                        end
                        
                        if Keyboard.getState("left") == 1 or Keyboard.getState("right") == 1 then
                            if sbs.player.step == 1 then
                                sbs.player.step = 2
                            elseif sbs.player.step == 2 then
                                sbs.player.step = 1
                            end
                            Audio.PlaySound("snd_menu_0.wav")
                        end
                        
                        if Keyboard.getState("z") == 1 and zKeyCooldown <= 0 then
                            if sbs.player.step == 1 then
                                Audio.PlaySound("snd_save.wav")
                                save.save(1, {landmark = trigger.landmarkIndex})
                                sbs.text:SetColor(1, 1, 0, true)
                                sbs.save:SetText("[instant]保存成功")
                                sbs.save:SetColor(1, 1, 0, true)
                                sbs.return_:Remove()
                                sbs.player:Remove()
                                sbs.page = 3
                                zKeyCooldown = 0.3
                            elseif sbs.player.step == 2 then
                                sbs.page = 4
                            end
                        end
                    end
                    
                    if sbs.page == 3 then
                        if Keyboard.getState("z") == 1 and zKeyCooldown <= 0 then
                            sbs.page = 4
                        end
                    end
                    
                    if sbs.page >= 2 then
                        if Keyboard.getState("x") == 1 then
                            sbs.page = 4
                        end
                    end
                end 
            end
        end
    end
    
    -- 重置单帧标志
    if oneframe then oneframe = false end
end

-- 初始化Player引用
function sbs.init(playerModule)
    Player = playerModule
end

-- 清理场景
function sbs.clear()
    -- 清理碰撞块
    for i = #sbs.blocks, 1, -1 do
        local block = sbs.blocks[i]
        if block and block.Remove then
            block:Remove()
        end
        table.remove(sbs.blocks, i)
    end

    -- 清理触发器
    for i = #sbs.triggers, 1, -1 do
        local trigger = sbs.triggers[i]
        if trigger and trigger.Remove then
            trigger:Remove()
        end
        table.remove(sbs.triggers, i)
    end

    -- 清理地标
    for i = #sbs.landmarks, 1, -1 do
        local landmark = sbs.landmarks[i]
        if landmark and landmark.Remove then
            landmark:Remove()
        end
        table.remove(sbs.landmarks, i)
    end

    -- 清理其他对象
    for i = #sbs.objects, 1, -1 do
        local obj = sbs.objects[i]
        if obj and obj.Remove then
            obj:Remove()
        end
        table.remove(sbs.objects, i)
    end

    -- 重置对话/菜单状态
    sbs.page = 0
    sbs.choosing = 0
    
    -- 重置单帧标志
    oneframe = false
    
    -- 调试输出
    print("场景清理完成")
    print("碰撞块剩余:", #sbs.blocks)
    print("触发器剩余:", #sbs.triggers)
end

return sbs