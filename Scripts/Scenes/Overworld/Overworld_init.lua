local Overworld_init = {
    newmap = "map1",--初始map
    isFirstLoad = true, -- 标记是否首次加载
    transition = {
        active = false,    -- 是否正在过渡中
        timer = 0,   -- 计时器
        duration = 0.5,   -- 过渡总持续时间（秒）
        fadeOutDone = false, -- 是否已完成淡出阶段
        targetMap = nil
    } 
}
local path = "Lua/Scenes/Overworld/"
Player = require("Lua/Libraries/Player")
scene = require(path.."sceneblocks")
menu = require(path.."menu")

function Overworld_init.load()
    scenes.Settype("Overworld")
    save.load(1) -- 存档加载
    Player.load()
    topground = image.CreateImage("px.png", {320, 240}, 6)
    topground:SetScale(640, 480)
    topground:SetColor(0, 0, 0)
    topground.alpha = 1 -- 初始设为不透明
    scene.init(Player)
    if Overworld_init.isFirstLoad then
        topground.alpha = 1
        Overworld_init.newmap = Overworld_init.Load(Overworld_init.newmap)
        Overworld_init.isFirstLoad = false
    else
        Overworld_into(Overworld_init.newmap)
    end
end

--room初始化
function ow_Init()
    local landmark_index = save.GetVariable("landmark") or 1
    
    if landmark_index > #scene.landmarks or landmark_index < 1 then
        landmark_index = 1
    end
    
    -- 放置玩家到地标位置
    Player.place(scene.landmarks[landmark_index])
end

function Overworld_init.update(dt)

    if Overworld_init.isFirstLoad == false then
        topground.alpha = math.max(topground.alpha - dt*2, 0)
    end
    
    if Overworld_init.transition.active then
        Overworld_init.transition.timer = Overworld_init.transition.timer + dt
        --淡出
        if not Overworld_init.transition.fadeOutDone then
            topground.alpha = math.min(Overworld_init.transition.timer / (Overworld_init.transition.duration / 2), 1)
            
            if topground.alpha >= 1 then
                Overworld_init.transition.fadeOutDone = true
                -- 实际切换地图
                scene.clear()
                Overworld_init.newmap = Overworld_init.Load(Overworld_init.transition.targetMap)
                Overworld_init.transition.timer = 0
            end
        -- 淡入
        else
            topground.alpha = 1 - math.min(Overworld_init.transition.timer / (Overworld_init.transition.duration / 2), 1)
            
            if topground.alpha <= 0 then
                Overworld_init.transition.active = false
                Player.canmove = true
            end
        end
    end

    typer.Pressed()
    Player.update(dt)
    menu.update()
    scene.update(dt)
    if Overworld_init.newmap then
        if Overworld_init.newmap.update then
            Overworld_init.newmap.update(dt)
        end
    end
end

function Overworld_init.draw()
    if Overworld_init.newmap then
        if Overworld_init.newmap.draw then
            Overworld_init.newmap.draw()
        end
    end 
end

function Overworld_init.over()
    package.loaded[scene] = nil
    image.clear()
end

function Overworld_init.Load(map)
    local path = "Lua/world/"..map
    package.loaded[path] = nil
    local map = require(path)
    if map.load then
        map.load()
    end
    return map
end

function Overworld_init.over()
    if Overworld_init.newmap then
        if Overworld_init.newmap.over then
            Overworld_init.newmap.over()
        end
        Overworld_init.newmap=nil
    end
end

function Overworld_into(map)
    if Overworld_init.transition.active then return end
    -- 初始化过渡状态
    Player.canmove = false
    if not Overworld_init.isFirstLoad then
        Overworld_init.transition = {
            active = true,
            timer = 0,
            duration = 0.5,
            fadeOutDone = false,
            targetMap = map
        }
    else
        scene.clear()
        Overworld_init.newmap = Overworld_init.Load(map)
    end
end

function GetNewmap()
    return Overworld_init.newmap
end

return Overworld_init