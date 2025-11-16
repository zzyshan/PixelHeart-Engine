local into = {}

local isstart = false
function start()
    isstart = true
end
local time = 0
local text = typer.New({"[font:SmileySans-Oblique.ttf][font_size:30]* 你仔细观察的四周[speed:0.3]...[speed:0.05]\n* 似乎没有奇怪的地方", "[noskip][call:start:][nextpage]", "[noskip][/mode]* 等等!\n* 前面有动静[speed:0.3]......[speed:0.05]"}, {60, 270}, 3, {voice = "uifont.wav"})
text.mode = "manual"
battle.AddEnemie("froggit")
battle.AddEnemie("whimsun")

local num
--local e = 0

function into.update(dt, ui)
    --e = e + 1
    --global.camera:SetScale(0.5 + 0.5 * math.sin(e/30), 0.5 + 0.5 * math.sin(e/30))
    if not isstart then return end

    time = time + 1
    local froggit = battle.GetEnemieData(1)
    if time == 1 then
        froggit.init()
    end
    
    if time > 50 and time <= 250 then
        froggit.sprites.head.alpha = froggit.sprites.head.alpha + 0.005
        froggit.sprites.body.alpha = froggit.sprites.body.alpha + 0.005
    end
    
    if time == 250 then
        text:SetText({"* 哦,原来只是一只青蛙呀"})
    end
    
    if time == 350 then
        text:Remove()
        Player.sprite:MoveTo(battle.main_arena.black.x, battle.main_arena.black.y)
    end
    
    if time == 360 then
        battle.main_arena:Resize(160, 130)
    end
    
    if time == 380 then
        Audio.PlayMusic("mus_battle2.ogg", true, 0)
        num = 0
        Player.sprite.hide = false
    end
    if time > 380 and time <= 430 then
        num = num + 0.02
        Audio.Music["mus_battle2.ogg"]:setVolume(num)
    end
    
    if time == 430 then
        into.END = true
        STATE("DEFENDING")
    end
end

return into