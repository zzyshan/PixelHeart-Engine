local whimsun = {
    name = "whimsun",
    hp = 10,
    maxdamage = 20,
    commands = {"Check"},
    position = {420, 160},
    isSwing = false,
    canspare = true,
    sprites = {}
}

function whimsun.init()
    whimsun.sprites.body = Sprites.New("whimsun/spr_whimsun_0.png", whimsun.position, 1)
    whimsun.sprites.body:SetAnimation({"whimsun/spr_whimsun_0.png", "whimsun/spr_whimsun_1.png"}, 0.8)
    --whimsun.sprites.body.alpha = 0
    whimsun.isSwing = true
end

function whimsun.Swing()
    if not whimsun.isSwing then return end
    
    whimsun.sprites.body.y = whimsun.position[2] + 30 * math.sin(love.timer.getTime()*4)
end

function whimsun.HandleActions(enemy_name, action, enemy)
    if action == "Check" then
        BattleDialogue("* WHIMSUN - ATK 5 DEF 0\n* This monster is too\n  sensitive to fight...")
    end
end

return whimsun