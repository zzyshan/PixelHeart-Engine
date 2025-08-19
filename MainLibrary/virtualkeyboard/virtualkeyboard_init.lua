local vkb = {
    isopen = false,--是否开启
    mode = {"buttonlayout"},--存键盘布局
    modeindex = nil,--布局下标
    newmode = nil--现在布局
}

local function IntroduceLayout()
    local mode = vkb.mode[vkb.modeindex]
    if mode then
        local path = "MainLibrary/virtualkeyboard/"..mode
        package.loaded[path] = nil
        vkb.newmode = require(path)
    end
end

function vkb.update(dt)
    if vkb.newmode and vkb.newmode.update then
        vkb.newmode.update(dt)
    end
end

function vkb.keypressed(key)
    if key == "escape" then
        if not vkb.isopen then
            vkb.isopen = true
            vkb.modeindex = 1
            IntroduceLayout()
            Audio.PlaySound("snd_save.wav")
        else
            if vkb.newmode and vkb.newmode.clean then
                vkb.newmode.clean()
            end
            if vkb.modeindex < #vkb.mode then
                vkb.modeindex = vkb.modeindex + 1
                IntroduceLayout()
                Audio.PlaySound("snd_save.wav")
            else
                vkb.isopen = false
                vkb.modeindex = nil
                vkb.newmode = nil
                Audio.PlaySound("snd_save.wav")
            end
        end
    end
end


return vkb