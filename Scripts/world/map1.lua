local map1 = {}

scene.Landmark(320, 240, false)
scene.Block(320, 90, 550, 20, 0, false)
scene.Block(90, 240, 20, 400, 0, false)
scene.Block(320, 400, 550, 20, 0, false)
scene.Block(560, 340, 20, 200, 0, false)
scene.Trigger(560, 170, 20, 140, 0, 
    {"warp", "map2", 2}, false
)
ow_Init()

function map1.over()
    scene.clear()
end

return map1