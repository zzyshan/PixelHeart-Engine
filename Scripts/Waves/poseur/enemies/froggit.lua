local froggit = {
    name = "froggit",
    hp = 30,
    maxdamage = 17,
    commands = {"Check", "Compliment"},
    position = {320, 180},
    isSwing = false,
    sprites = {}
}

function froggit.init()
    froggit.sprites.head = Sprites.New("froggit/froggit_head_0.png", froggit.position, 1)
    froggit.sprites.body = Sprites.New("froggit/froggit_body_0.png", froggit.position, 1)
    froggit.sprites.head.y = froggit.sprites.head.y - froggit.sprites.head:getHeight()/2
    froggit.sprites.body.y = froggit.sprites.body.y + froggit.sprites.body:getHeight()/2
    froggit.sprites.head:SetAnimation({"froggit/froggit_head_0.png", "froggit/froggit_head_1.png"}, 4)
    froggit.sprites.body:SetAnimation({"froggit/froggit_body_1.png", "froggit/froggit_body_0.png"}, 2)
    froggit.sprites.head.alpha = 0
    froggit.sprites.body.alpha = 0
    froggit.isSwing = true
end

function froggit.Swing()
    if not froggit.isSwing then return end
    
    local headY, bodyY = froggit.position[2] - froggit.sprites.head:getHeight()/2, froggit.position[2] + froggit.sprites.body:getHeight()/2
    
    froggit.sprites.head:MoveTo(froggit.position[1] + 3 * math.cos(love.timer.getTime()*3), headY + 3 * math.sin(love.timer.getTime()*6))
    froggit.sprites.body:MoveTo(froggit.position[1], bodyY)
end

function froggit.HandleActions(enemy_name, action, enemy)
    if action == "Check" then
        BattleDialogue("* FROGGIT - ATK 4 DEF 5\n* Life is difficult for\n  this enemy.")
    elseif action == "Compliment" then
        froggit.canspare = true
        BattleDialogue("* Froggit didn't understand\n  what you said, but was\n  flattered angway.")
    end
end

return froggit