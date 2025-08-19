local ATTACKING = {
    sprites = {},
    over = false,
    overtime = 0,
    DamageCalculation = false
}
local AA = ATTACKING

-- 用于管理所有跳跃文字的列表
local PopUp = {}

----------- 临时函数 ------------
local function Removesprite()
    for _, sprite in pairs(ATTACKING.sprites) do
        if sprite and sprite.Remove then
            sprite:Remove()
        end
    end
    ATTACKING.sprites = {}
end

local function Createhp(position, hp, isOffset)
    local sprite = Sprites.New("px.png", position or {320, 180}, 1, {xscale = mathlib.clamp(hp * 1.21, 1 * 1.21, 99 * 1.21), yscale = 20})
    sprite:SetPivot(0, 0.5)
    if isOffset then
        sprite.x = position[1] - sprite.scale.x / 2
    end
    return sprite
end
---------- end -----------------

--------- 共用函数 -------------

--- 创建一个跳跃的伤害/数值文本
function ATTACKING.PopUpText(text, position, settings)
    local settings = settings or {}
    local default_settings = {
        font = "Hachicro.ttf",
        g = 0,
        b = 0,
        size = 30,
        -- 默认物理参数
        Initialforce = settings.Initialforce or 6,
        gravity = settings.gravity or 0.5
    }
    -- 合并设置
    for k, v in pairs(settings) do
        default_settings[k] = v
    end

    local text_obj = typer.New(tostring(text), {position[1], position[2] - 50}, 1, default_settings)
    text_obj.Alignment = false
    -- 添加物理属性
    text_obj.Initialforce = default_settings.Initialforce
    text_obj.gravity = default_settings.gravity
    text_obj.starty = position[2] -- 记录起始Y坐标，可用于消失判断

    table.insert(PopUp, text_obj)
    return text_obj
end


--- 默认的伤害处理逻辑
function ATTACKING.Damage()
    local enemie = ui.Selectedenemie
    enemie.position = enemie.position or {320, 180}
    if not enemie then return end

    local absLength = math.abs(AA.sprites.targetchoice.x - ATTACKING.sprites.target.x)
    local damage = enemie.maxdamage
    if absLength > 5 then
        damage = math.floor(enemie.maxdamage * (1 - absLength / (ATTACKING.sprites.target:getWidth() / 2 - 10)))
    end

    enemie.maxhp = enemie.maxhp or enemie.hp

    -- 创建血条
    AA.sprites.maxhp = Createhp(enemie.position, enemie.maxhp, true)
    AA.sprites.maxhp:SetColor(74 / 255, 76 / 255, 76 / 255)
    AA.sprites.hp = Createhp({AA.sprites.maxhp.x, AA.sprites.maxhp.y}, enemie.hp)
    AA.sprites.hp:SetColor(0, 1, 0)

    -- 创建跳跃伤害数字
    AA.sprites.damage_text = AA.PopUpText("[skip]" .. damage, {enemie.position[1], enemie.position[2] - 50})

    -- 伤害结算
    enemie.hp = enemie.hp - damage
    enemie.hp = math.max(0, enemie.hp)

    AA.DamageCalculation = true
end
----------- end --------------

--- 检查敌人是否存活
local function isEnemyAlive(enemie)
    return enemie and enemie.hp and enemie.hp > 0
end

local randomise

function ATTACKING.init()
    randomise = math.random(0, 1)
    ATTACKING.isattack = false
    ATTACKING.over = false
    ATTACKING.DamageCalculation = false
    ATTACKING.customAttack = false

    ATTACKING.sprites.target = Sprites.New("ui/spr_target_0.png", {320, 320}, 3)
    ATTACKING.sprites.targetchoice = Sprites.New("ui/spr_targetchoice_0.png", {320, 320}, 3)

    if randomise == 0 then
        ATTACKING.sprites.targetchoice.x = 320 + 285
    elseif randomise == 1 then
        ATTACKING.sprites.targetchoice.x = 320 - 285
    end
end

function ATTACKING.update(ui)
    local enemie = ui.Selectedenemie

    if AA.sprites.targetchoice and not AA.isattack then
        if randomise == 0 then
            AA.sprites.targetchoice.x = AA.sprites.targetchoice.x - 4.5
            if AA.sprites.targetchoice.x <= 35 then
                Removesprite()
                STATE("ACTIONSELECT")
                return 
            end
        elseif randomise == 1 then
            AA.sprites.targetchoice.x = AA.sprites.targetchoice.x + 4.5
            if AA.sprites.targetchoice.x >= 605 then
                Removesprite()
                STATE("ACTIONSELECT")
                return 
            end
        end

        if Keyboard.getState("z") == 1 then
            AA.isattack = true
            Audio.PlaySound("snd_slice.wav")
            AA.sprites.targetchoice:SetAnimation({"ui/spr_targetchoice_0.png", "ui/spr_targetchoice_1.png"}, 0.15)
            AA.sprites.slice = Sprites.New("ui/Player Attack/spr_slice_o_0.png", enemie.position or {320, 180}, 3)
            local sprites = {}
            for i = 0, 5 do
                local sprite = "ui/Player Attack/spr_slice_o_" .. i .. ".png"
                table.insert(sprites, sprite)
            end
            AA.sprites.slice:SetAnimation(sprites, 0.15)
            AA.sprites.slice.anim.animmode = "oneshotempty"
        end
    end

    -- 处理攻击动画结束后的逻辑
    if AA.sprites.slice and AA.sprites.slice.remove then
        -- 检查敌人是否有自定义攻击函数
        local hasCustomAttack = enemie.customAttack and type(enemie.customAttack) == "function"

        if not hasCustomAttack then
            if not AA.DamageCalculation then
                Audio.PlaySound("snd_damage.wav")
                ATTACKING.Damage()
            end
        else
            AA.customAttack = true
        end
    end
    
    if AA.DamageCalculation then
        AA.sprites.hp.scale.x = mathlib.clamp(mathlib.smooth(AA.sprites.hp.scale.x, enemie.hp * 1.21, 2), 0, 99 * 1.21)
        if AA.sprites.hp.scale.x == mathlib.clamp(enemie.hp * 1.21, 0, 99 * 1.21) and AA.sprites.damage_text.y[1] >= AA.sprites.damage_text.starty then
            AA.overtime = AA.overtime + 1
            if AA.overtime > 30 then
                AA.over = true
            end
    
            if AA.over then
                if not isEnemyAlive(enemie) then
                    for i = #battle.enemies, 1, -1 do
                        local EM = battle.enemies[i]
                        if EM == enemie then
                            table.remove(battle.enemies, i)
                            battle.allenemy = battle.allenemy - 1
                            local dust = Sprites.New("killed.png", enemie.position, 1)
                        end
                        for _, sprite in pairs(EM) do
                            
                        end
                    end
                end
                Removesprite()
                AA.overtime = 0
                STATE("DEFENDING")
            end
        end
    end
    
    if AA.customAttack then
        local customAttackFinished = enemie.customAttack(enemie, ATTACKING)

        -- 如果自定义攻击函数返回 true，则认为攻击结束
        if customAttackFinished then
            Removesprite()
            ATTACKING.overtime = 0
            STATE("ACTIONSELECT")
        end
    end

    ---------- 循环 ------------
    for i = #PopUp, 1, -1 do
        local text = PopUp[i]
        
        -- 被迫这么对准╥﹏╥
        if not text.Alignment and next(text.char) then
            local width, _ = text:GetLettersSize() or 0, 0
            text.x[1] = text.x[1] - width * 2
            text.Alignment = true
        end
        
        if not text.remove then
            text.Initialforce = text.Initialforce - text.gravity
            text.y[1] = math.min(text.y[1] - text.Initialforce, text.starty)
        else
            table.remove(PopUp, i)
        end
    end
    ---------- end ------------
end

-- 返回模块
return ATTACKING