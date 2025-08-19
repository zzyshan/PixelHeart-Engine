local encounter = {
    Text = "* Poseur strikes a pose!",
    nextwaves = {"wave_1", "wave_2"},
    canflee = true,
    Escapeprobability = 1,
    scene = {"kong"},
    wintext = nil,
    wave = "wave_1",
    enemies = {
        {
            sprites = {
                body = Sprites.New("poseur.png", {240, 140}, 1)
            },
            name = "poseur",
            position = {240, 140},
            hp = 100,
            atk = 1,
            def = 1,
            commands = {"Check", "Act 1", "Act 2"},
            exp = 100,
            gold = 100,
            maxdamage = 100,
            canspare = true
        },
        {
            name = "zzy",
            maxdamage = 1,
            hp = 114514,
            maxdamage = 10000,
            commands = {"Check", "Talk"}
        }
    },
    
    Player = function()
        Player.Name = "Kris"
        Player.maxhp = 100
        Player.Hp = 100
        Player.Lv = 1
        Player.inventory = {
            {
                name = "pie",
                mode = 0
            },
            {
                name = "zzy"
            },
            {
                name = "zzy"
            },
            {
                name = "zzy"
            },
            {
                name = "zzy"
            }
        }
    end,
    
    EnteringState = function(new, old)
    end,
    
    HandleActions = function(enemy_name, action, enemy)
        if enemy_name == "poseur" then
            if action == "Check" then
                BattleDialogue("* Poseur 1 atk 1def\n* Check message goes here.")
            elseif action == "Act 1" then
                BattleDialogue("* You selected Act 1")
            elseif action == "Act 2" then
                BattleDialogue("* You selected Act 2")
            end
        elseif enemy_name == "sans" then
            if action == "Check" then
                BattleDialogue({"* SANS 1 ATK 1 DEF[wait:10]\n* No matter what,[wait:07] he's still\n  the reasiest enemy.", "* Just keep attacking."})
            end
        elseif enemy_name == "zzy" then
            if action == "Check" then
                BattleDialogue("* 我是ZZY!")
            elseif action == "Talk" then
                BattleDialogue("* ~$? ?_:@/@$_?@")
                enemy.canspare = true
            end
        end
    end,
    
    HandleItems = function(itemID)
        if itemID == "pie" then
            BattleDialogue("* You eat pie")
        elseif itemID == "zzy" then
            BattleDialogue("* #?$/@?&!?@:&&~@:")
        end
    end,
    
    DefenseEnding = function()
    end
}

function OnHit(bullet)
    Player.Hurt(1, 1, true)
end

return encounter