local lg = love.graphics

-- zh.导入模块 en.Import Module
scenes = require("MainLibrary/scenes")
Keyboard = require("MainLibrary/Keyboard")
global = require("MainLibrary/Global")
Audio = require("MainLibrary/Audio")
Sprites = require("MainLibrary/Sprites")
typer = require("MainLibrary/typer")
collision = require("MainLibrary/collision")
layers = require("MainLibrary/Layers")
Perf = require("perf")
vkb = require("MainLibrary/virtualkeyboard/virtualkeyboard_init")
mathlib = require("MainLibrary/mathlib")
Player = require("Scripts/Libraries/Player/Player_init")
save = require("MainLibrary/save/SaveSystem")
Camera = require("MainLibrary/camera")
masks = require("MainLibrary/masks")
DEBUG = require("MainLibrary/DEBUG")

local gameWidth, gameHeight = 640, 480  -- zh.游戏内部分辨率 en.Game internal resolution
local screen_w, screen_h = love.graphics.getDimensions()
-- zh.计算缩放比例 en.Calculate Scale
local scaleX = screen_w / gameWidth
local scaleY = screen_h / gameHeight
local scale = math.min(scaleX, scaleY)

-- zh.计算偏移量 en.Calculate Offset
local draw_x = math.floor((screen_w - gameWidth * scale) * 0.5 + 0.5)
local draw_y = math.floor((screen_h - gameHeight * scale) * 0.5 + 0.5)

-- ch.创建全局相机实例并设置为当前相机
-- en.Creates a global camera instance and sets it as the current camera
global.camera = Camera.new()
Camera.SetCamera(global.camera)

CANVAS = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight(),
    nil,
    {
        format = "stencil",
        readable = true
    }
)
CANVAS:setFilter("nearest", "nearest")
local INTERMEDIATE_CANVAS = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight(),
    nil,
    {
        format = "stencil",
        readable = true
    }
)
INTERMEDIATE_CANVAS:setFilter("nearest", "nearest")

global.SetVar("ScreenShaders", {})

function love.load()
    save.init() -- 存档初始化
    Player.init()
    if love.system.getOS() == "Android" then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
    end
    -- 初始化场景
    scenes.into("battle", {BATTLE = "poseur"})
end

function love.update(dt)
    Perf.update(dt)
    Keyboard.update(dt)
    Audio.update(dt)
    Sprites.allupdate(dt)
    vkb.update(dt)
    Player.update(dt)
    Camera.update(dt)
    typer.allupdate(dt)
    if scenes.newscene and scenes.newscene.update then
        scenes.newscene.update(dt)
    end
end

function love.draw()
    screen_w, screen_h = love.graphics.getDimensions()
    scaleX = screen_w / gameWidth
    scaleY = screen_h / gameHeight
    scale = math.min(scaleX, scaleY)
    
    draw_x = math.floor((screen_w - gameWidth * scale) * 0.5 + 0.5)
    draw_y = math.floor((screen_h - gameHeight * scale) * 0.5 + 0.5)

    love.graphics.setCanvas({CANVAS, stencil = true})
    love.graphics.clear(true, true, true)

    love.graphics.push()
        love.graphics.scale(scale, scale)
        -- zh.应用相机变换 
        -- en.Apply Camera Transform
        if Camera.NewCamera then
            Camera.NewCamera:apply()
        end

        layers.sort()

        if scenes.newscene and scenes.newscene.draw then
            scenes.newscene.draw()
        end
        DEBUG.draw()
        layers.sortTop()
        -- zh.结束相机变换 
        -- en.End Camera Transform
        if Camera.NewCamera then
            Camera.NewCamera:detach()
        end
    love.graphics.pop()
        
    love.graphics.push()
        love.graphics.setCanvas()
        love.graphics.translate(draw_x, draw_y)
        love.graphics.setColor(1, 1, 1)
        
        if DEBUG.switch then
            love.graphics.rectangle("line", 0, 0, CANVAS:getWidth(), CANVAS:getHeight())
        end
        
        local shaders = global.GetVar("ScreenShaders") or {}

        if (#shaders > 0) then
            local source = CANVAS
            local target = INTERMEDIATE_CANVAS

            for _, shader in ipairs(shaders) do
                love.graphics.setCanvas(target)
                love.graphics.clear()
                love.graphics.setShader(shader)
                love.graphics.draw(source)
                love.graphics.setShader()

                source, target = target, source
            end

            love.graphics.setCanvas()
            love.graphics.draw(source)
        else
            love.graphics.draw(CANVAS)
        end
    love.graphics.pop()
end

function love.keypressed(key)
    if scenes.newscene and scenes.newscene.keypressed then
        scenes.newscene.keypressed(key)
    end
    
    if key == "f11" and love.system.getOS() ~= "Android" then
        love.window.setFullscreen(not love.window.getFullscreen())
        scale = math.min(love.graphics.getWidth() / gameWidth, love.graphics.getHeight() / gameHeight)
    end
    
    if key == "f6" then
        DEBUG.isOpen()
    end
        
    vkb.keypressed(key)
end

function love.resize(w, h)
    Keyboard.updateWindowSize(w, h)
    if CANVAS:getWidth() ~= w or CANVAS:getHeight() ~= h then
        CANVAS = love.graphics.newCanvas(w - draw_x * 2, h - draw_y)
    end
end