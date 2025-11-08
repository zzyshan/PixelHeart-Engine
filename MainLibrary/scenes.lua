local scenes = {
    newscene = nil,--当前场景
    scenetype = nil
}

function scenes.Load(scenename, var)
    local scene
    scenes.var = var or {}
    if scenename == "Overworld" or scenename == "battle" then
        local path = "Scripts/Scenes/"..scenename.."/"..scenename.."_init"
        package.loaded[path] = nil--清理缓存
        
        scene = require(path)
    else
        local path = "Scripts/Scenes/"..scenename
        package.loaded[path] = nil
        scene = require(path)
    end
    
    if scene.load then
        scene.load()
    end
    
    return scene
end

function scenes.over()
    if scenes.newscene then
        if scenes.newscene.over then
            scenes.newscene.over()
        end
        scenes.newscene = nil
        scenes.newbattle = nil
    end
end

function scenes.into(scenename, var)--进入场景
    Player.save()
    print("en.Enter Scene:" .. scenename)
    scenes.over()
    scenes.newscene = scenes.Load(scenename, var)
end

function scenes.Gettype()
    return scenes.scenetype
end

function scenes.Settype(type)
    scenes.scenetype = type
end

return scenes