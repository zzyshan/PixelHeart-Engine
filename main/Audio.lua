local Audio={
    Music={},
    Sound={}
}
local Audio_function={
    stop=function(Audio)
        Audio.bgm:stop()
    end,
    play=function(Audio)
        Audio.bgm:play()
    end,
    Pause=function(Audio)
        Audio.bgm:Pause()
    end,
    setVolume=function(Audio,volume)
        Audio.bgm:setVolume(math.max(0,math.min(1,volume)))
    end,
    setLooping=function(Audio,isLoop)
        Audio.bgm:setLooping(isLoop and true)
    end,
    setSpeed=function(Audio,speed)
        speed=math.max(0.1,speed)
        Audio.bgm:setPitch(speed)
    end
}

Audio_function.__index=Audio_function

function Audio.LoadFile(filename,audioType)
    audioType = audioType or "Music"
    local path = ""..filename
    
    if Audio[audioType][path] then
        return Audio[audioType][path]
    end
    
    local Music={}
    Music.name=audioType.."/"..filename
    Music.bgm=love.audio.newSource(Music.name,audioType=="Music" and "stream" or "static")
    Music.Velocity=Music.bgm:getChannelCount()==1 and "Mono" or "Stereo"
    
    Audio[audioType][path] = Music
    setmetatable(Music,Audio_function)
    return Music
end

function Audio.PlayMusic(filename,isLoop,Volume)
    local Music=Audio.LoadFile(filename,"Music")
    Music:setLooping(isLoop ~= nil and isLoop)
    Music:setVolume(Volume or 1)
    Music:play()
    return Music
end

function Audio.PlaySound(filename,isLoop,Volume)
    local Sound=Audio.LoadFile(filename,"Sound")
    Sound:setLooping(isLoop ~= nil and isLoop)
    Sound:setVolume(Volume or 1)
    local instance = setmetatable({
        source = Sound.bgm:clone()
    }, Audio_function)
    instance.source:play()
    table.insert(Audio.Sound,instance)
    return Sound
end

function Audio.update(dt)
    -- 清理已完成播放的音效
    for i = #Audio.Sound, 1, -1 do
        if not Audio.Sound[i].source:isPlaying() then
            table.remove(Audio.Sound,i)
        end
    end
end

return Audio