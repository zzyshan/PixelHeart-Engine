local scenes = {
    newscene = nil,--当前场景
    scenetype = nil
}

function scenes.Load(scenename, new)
    local scene
    if scenename == "Overworld" or scenename == "battle" then
        local path = "Scripts/Scenes/"..scenename.."/"..scenename.."_init"
        package.loaded[path] = nil--清理缓存
        
        if scenename == "battle" then
            scenes.BATTLE = new
        end
        
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

function scenes.into(scenename, new)--进入场景
    scenes.over()
    scenes.newscene = scenes.Load(scenename, new)
end

function scenes.Gettype()
    return scenes.scenetype
end

function scenes.Settype(type)
    scenes.scenetype = type
end

return scenes