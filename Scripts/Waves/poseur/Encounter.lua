local encounter = {
    Text = "[font:SmileySans-Oblique.ttf][font_size:30]* 你遭遇了[wait:0.7]空气?",
    nextwaves = {"wave_2"},
    canflee = false,
    Escapeprobability = 0,
    scene = {"kong"},
    wintext = nil,
    wave = "wave_1",
    enemies = {
        {
            path_name = "qwq"
        }
    }
}

function encounter.load()
    Player.Name = "zzy"
    Player.maxhp = 20
    Player.Hp = 20
    Player.Lv = 1
    Player.inventory = {
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        },
        {
            name = "ZZY"
        }
    }
end

function encounter.update(dt)
    local froggit = battle.GetEnemieData(1)
    local whimsun = battle.GetEnemieData(2)
    if froggit and froggit.name == "froggit" then
        froggit.Swing()
    end
    if whimsun and whimsun.name == "whimsun" then
        whimsun.Swing()
    end
end

function encounter.EnteringState(new, old)
end

function encounter.HandleItems(itemID)
    if itemID == "ZZY" then
        BattleDialogue({"[font:SmileySans-Oblique.ttf][font_size:30]* 你吃掉了[color:1,0,0]ZZY[/color]?", "* 吃我是不会增加任何HP的\n* 快停止你这种行为!"})
    end
end

function encounter.HandleSpare()
end

function encounter.DefenseEnding()
end

function OnHit(bullet)
    Player.Hurt(2, 1, true)
end

return encounter