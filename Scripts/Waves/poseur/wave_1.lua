local wave_1 = {}

local flybullet = require(battle.path .. "/bullets/flybullet")
local butterflybullet = require(battle.path .. "/bullets/butterflybullet")
local time = 0
local thing = 0
local time2 = 0
local overtime = 0
local bullets = {}
local mask = masks.New("rectangle", {320, 250}, 155, 130, 0, 1)
--local tt = typer.Print("", {320, 10}, 1)
local startx = battle.main_arena.x - battle.main_arena.black:getWidth()/2
local endx = startx + battle.main_arena.black:getWidth()

function wave_1.update(dt)
    flybullet.update(dt)
    butterflybullet.update()
    mask:Follow(battle.main_arena.black)
    --[[local currentTime = Audio.Music["mus_battle2.ogg"]:tell()
    if currentTime and currentTime >= 0 then
        time = math.floor(currentTime * 100 + 0.5) / 100
    else
        time = 0
    end]]
    time = math.floor(Audio.Music["mus_battle2.ogg"]:tell())
    
    
    --tt.text = tostring(time)
    
    if time >= 1 and time <= 8 then
        time2 = time2 + 1
        
        if time2 % 80 == 0 then
            local x = math.random(battle.main_arena.x - battle.main_arena.black:getWidth()/2, battle.main_arena.x + battle.main_arena.black:getWidth()/2)
            local bullet = flybullet.New({x, 250}, 1, 0.5, {mask})
            table.insert(bullets, bullet)
        end
    end
    
    if time == 3 and thing == 0 then
        local minDistance = 30  --最小距离
        local availableWidth = endx - startx
        
        if availableWidth < minDistance then
            minDistance = math.max(10, availableWidth / 2)
        end
        
        local bullet1MinX = startx + 30
        local bullet1MaxX = endx - 30 - minDistance
        
        local bullet1X = math.random(bullet1MinX, bullet1MaxX)
        
        local bullet2MinX = bullet1X + minDistance
        local bullet2MaxX = endx - 30
        
        local bullet2X = math.random(bullet2MinX, bullet2MaxX)
        
        local bullet = butterflybullet.New({bullet1X, 390}, {mask})
        local bullet2 = butterflybullet.New({bullet2X, 390}, {mask})
        
        bullet.angle = -90
        bullet.yspeed = -50
        bullet2.angle = -90
        bullet2.yspeed = -50
        thing = thing + 1
    end
    
    if time == 5 and thing == 1 then
        bulletCircle = butterflybullet.NewCircle({320, 320}, 100, 12, {mask})
        thing = thing + 1
    end
    
    if time >= 5 then
        bulletCircle.angle = bulletCircle.angle + 0.05
    end
    
    if time >= 5 and time <= 6 then
        bulletCircle.radius = mathlib.lerp(bulletCircle.radius, 60, 0.15)
    end
    
    if time == 10 then
        Camera.NewCamera:Setcovercolor(1, 1, 1)
        Camera.NewCamera:Setcoveralpha(1, 0.05)
    end
    
    if Camera.NewCamera.cover.sprite.alpha == 1 then
        overtime = overtime + 1
        local froggit = battle.GetEnemieData(1)
        local whimsun = battle.GetEnemieData(2)
        froggit.position[1] = 220
        if overtime == 1 then
            whimsun.init()
        end
        Sprites.bulletclear()
    end
    
    if overtime == 20 then
        Camera.NewCamera:Setcoveralpha(0, 0.05)
        battle.EncounterText = "[font:SmileySans-Oblique.ttf][font_size:30]* 你们都从哪里冒出来的"
        wave_1.END = true
    end
    
-------------- 循环 --------------
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if not bullet.remove and (bullet.y >= battle.main_arena.y + battle.main_arena.black:getHeight()/2 + 7 or bullet.x <= battle.main_arena.x - battle.main_arena.black:getWidth()/2 - 7 or bullet.x >= battle.main_arena.x + battle.main_arena.black:getWidth()/2 + 7) then
            bullet:Remove()
            table.remove(bullets, i)
        end
    end
end

return wave_1