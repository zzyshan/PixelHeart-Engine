local vkb = {
    isopen = false,--是否开启
    mode = {"buttonlayout"},--存键盘布局
    modeindex = nil,--布局下标
    newmode = nil--现在布局
}

vkb.path = "MainLibrary/virtualkeyboard/"

local os = love.system.getOS()
local isMobile = (os == "Android" or os == "iOS")

local function IntroduceLayout()
    local mode = vkb.mode[vkb.modeindex]
    if mode then
        local path = vkb.path .. "layout/" .. mode
        package.loaded[path] = nil
        vkb.newmode = require(path)
    end
end

function vkb.update(dt)
    if vkb.newmode and vkb.newmode.update then
        vkb.newmode.update(dt)
    end
    
    local isFullscreen, _ = love.window.getFullscreen()
    
    if isMobile and not isFullscreen then
        isFullscreen = love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    end
end

function vkb.draw()
    if vkb.newmode then
        --vkb.newmode.draw()
    end
end

function vkb.keypressed(key)
    if not isMobile then return  end
    
    if key == "escape" then
        if not vkb.isopen then
            vkb.isopen = true
            vkb.modeindex = 1
            IntroduceLayout()
        else
            if vkb.newmode and vkb.newmode.clean then
                vkb.newmode.clean()
            end
            if vkb.modeindex < #vkb.mode then
                vkb.modeindex = vkb.modeindex + 1
                IntroduceLayout()
            else
                vkb.isopen = false
                vkb.modeindex = nil
                vkb.newmode = nil
            end
        end
    end
end


return vkb