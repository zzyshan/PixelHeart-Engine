local map2 = {}
scene.Landmark(50, 240, false)
scene.Landmark(400, 240, false)
scene.Trigger(150, 150, 40, 40, 0, 
    {"dialog", {"[font:方正像素12.ttf]* 你踩到我(*￣m￣)"}}, false
)
scene.SavePoint(350, 240, {"* 决心"}, "测试房间", 1)
t1 = scene.Trigger(230, 150, 40, 40, 0, 
    {"dialog-z", {"* 我是zzy!"}}, false
)
t2 = scene.Trigger(350, 150, 40, 40, 0, 
    {"dialog-z", {"* sisbidgdjs\n  skjsvdj\n  sidhej"}}, false
)
ow_Init()

function map2.update(dt)
    local times = t1.GetTimes()
    if times == 1 then
        t1.SetText({"* 这里是关于Overworld的测试..."})
    elseif times == 2 then
        t1.SetText({"* 如你所见,我制作模板是从Overworld开始的"})
    elseif times == 3 then
        t1.SetText({"* 这是因为\n我觉得啊,一个好的Overworld相比[color:1,0,0]战斗[color:1,1,1]要更重要一些\n(ps. 对于rpg游戏)"})
    elseif times == 4 then
        t1.SetText({"* 当然[color:1,0,0]战斗[color:1,1,1]之后做完Overworld后\n肯定会做\n只能说敬请期待了"})
    elseif times == 5 then
        t1.SetText({"* 没啥了"})
    end
end
return map2