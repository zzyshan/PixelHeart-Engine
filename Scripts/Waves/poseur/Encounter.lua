local encounter = {
    Text = "[font:SmileySans-Oblique.ttf][font_size:30]* 你遭遇了[wait:0.5]空气?",
    nextwaves = {"wave_1", "wave_2"},
    canflee = false,
    Escapeprobability = 0,
    scene = {"kong"},
    wintext = nil,
    wave = "wave_1",
    enemies = {
        {
            name = "???",
            hp = 1000,
            maxdamage = 200,
            commands = {"Observation"}
        }
    },
    
    load = function()
        Player.Name = "ZZY"
        Player.maxhp = 20
        Player.Hp = 20
        Player.Lv = 1
        Player.inventory = {}
    end,
    
    EnteringState = function(new, old)
    end,
    
    HandleActions = function(enemy_name, action, enemy)
        if enemy_name == "???" then
            if action == "Observation" then
                -- battle.DeleteEnemie(1)
                BattleDialogue("* 你仔细观察的四周[speed:0.3]...[speed:0.05]\n* 似乎没有奇怪的地方")
            end
        end
    end,
    
    HandleItems = function(itemID)
    end,
    
    DefenseEnding = function()
    end
}

function OnHit(bullet)
    Player.Hurt(2, 2, true)
end

return encounter