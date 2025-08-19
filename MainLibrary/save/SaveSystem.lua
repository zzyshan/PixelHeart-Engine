--本库全由deepseek写(zzy只负责可爱 不是),主要是因为我懒得写 ≡ω≡
local serpent = require("MainLibrary/save/serpent")

local SaveSystem = {
    slots = 3,              -- 存档位数量
    currentSlot = 1,        -- 当前选中存档位
    dir = "saves/",         -- 存档目录
    encryptionKey = 0x55,   -- 简易加密密钥
    dataTemplate = {        -- 存档数据结构
        room = "room1",     -- 当前房间
        landmark = 1,       -- 当前地标
        flags = {},         -- 剧情标记
        player = {          -- 玩家状态
            name = "Player",
            lv = 1,
            x = 320, y = 240, 
            hp = 20, maxhp = 20,
            gold = 0,
            inventory = {}  -- 物品栏
        },
        meta = {            -- 元数据
            version = "1.0",
            created = os.time(),
            lastModified = os.time(),
            playTime = 0
        }
    },
    currentData = nil       -- 当前加载的存档数据
}

--- 初始化存档目录
function SaveSystem.init()
    if not love.filesystem.getInfo(SaveSystem.dir) then
        love.filesystem.createDirectory(SaveSystem.dir)
    end
end

--- 序列化并加密数据
local function _serialize(data)
    local str = serpent.block(data, {
        comment = false,
        sortkeys = true,
        indent = "  "
    })
    
    return string.gsub(str, ".", function(c) 
        return string.char((c:byte() + SaveSystem.encryptionKey) % 256)
    end)
end

--- 解密并反序列化数据
local function _deserialize(str)
    local decrypted = string.gsub(str, ".", function(c) 
        return string.char((c:byte() - SaveSystem.encryptionKey) % 256)
    end)
    
    local func, err = loadstring("return " .. decrypted)
    if not func then
        return nil, "反序列化失败: " .. tostring(err)
    end
    
    local ok, result = pcall(func)
    if not ok then
        return nil, "执行失败: " .. tostring(result)
    end
    
    return result
end

--- 深拷贝辅助函数
local function deepCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = deepCopy(v)
    end
    return copy
end

--- 创建新存档
function SaveSystem.create(slot)
    local data = {
        global = deepCopy(SaveSystem.dataTemplate),
        timestamp = os.time()
    }
    
    data.global.meta.created = os.time()
    data.global.meta.lastModified = os.time()
    
    local path = SaveSystem.dir .. "save_" .. slot .. ".dat"
    local success, err = love.filesystem.write(path, _serialize(data))
    
    if success then
        SaveSystem.currentSlot = slot
        SaveSystem.currentData = data
    end
    
    return success, err
end

--- 保存数据到指定存档位
function SaveSystem.save(slot, val)
    slot = slot or SaveSystem.currentSlot
    local path = SaveSystem.dir .. "save_" .. slot .. ".dat"
    
    -- 确保有当前数据
    if not SaveSystem.currentData then
        local success, err = SaveSystem.create(slot)
        if not success then return false, err end
    end
    
    -- 更新数据
    SaveSystem.currentData.timestamp = os.time()
    SaveSystem.currentData.global.player = {
        name = Player.Name or "Player",
        lv = Player.Lv,
        x = Player.sprite.x or 320,
        y = Player.sprite.y or 240,
        hp = Player.Hp or 20,
        maxhp = Player.maxhp or 20,
        gold = Player.gold or 0,
        inventory = deepCopy(Player.inventory or {})
    }
    
    SaveSystem.currentData.global.room = GetNewmap or "room1"
    SaveSystem.currentData.global.landmark = val.landmark or 1
    
    -- 更新元数据
    SaveSystem.currentData.global.meta.lastModified = os.time()
    SaveSystem.currentData.global.meta.playTime = (SaveSystem.currentData.global.meta.playTime or 0) + 
                                                (os.time() - (SaveSystem.currentData.global.meta.lastPlayTime or os.time()))
    SaveSystem.currentData.global.meta.lastPlayTime = os.time()
    
    -- 保存到文件
    local success, err = love.filesystem.write(path, _serialize(SaveSystem.currentData))
    return success, err
end

--- 从存档位加载数据（自动创建新存档如果不存在）
function SaveSystem.load(slot)
    SaveSystem.currentSlot = slot
    local path = SaveSystem.dir .. "save_" .. slot .. ".dat"
    
    -- 如果存档不存在，创建新存档
    if not love.filesystem.getInfo(path) then
        local success, err = SaveSystem.create(slot)
        if not success then return false, err end
        return true
    end
    
    -- 读取并解析存档
    local content, size = love.filesystem.read(path)
    if not content or size == 0 then
        return false, "存档文件为空"
    end
    
    local ok, data = pcall(_deserialize, content)
    if not ok or not data then
        -- 尝试修复损坏的存档
        print("存档损坏，尝试创建新存档")
        local success, err = SaveSystem.create(slot)
        return success, err or "存档损坏并已重建"
    end
    
    -- 确保关键字段存在
    data.global.landmark = data.global.landmark or 1
    data.global.meta = data.global.meta or {
        version = "1.0",
        created = os.time(),
        lastModified = os.time(),
        playTime = 0
    }
    
    SaveSystem.currentData = data
    return true
end

--- 获取存档变量（支持点分路径）
function SaveSystem.GetVariable(path, slot)
    slot = slot or SaveSystem.currentSlot
    
    -- 如果请求的是当前槽位且已加载数据
    if slot == SaveSystem.currentSlot and SaveSystem.currentData then
        local parts = {}
        for part in path:gmatch("[^.]+") do
            table.insert(parts, part)
        end
        
        local value = SaveSystem.currentData.global
        for _, key in ipairs(parts) do
            if type(value) ~= "table" then return nil end
            value = value[key]
        end
        return value
    end
    
    -- 对于非当前槽位，从文件读取
    local filePath = SaveSystem.dir .. "save_" .. slot .. ".dat"
    if not love.filesystem.getInfo(filePath) then
        return nil
    end
    
    local content = love.filesystem.read(filePath)
    local ok, data = pcall(_deserialize, content)
    if not ok or not data then
        return nil
    end
    
    local parts = {}
    for part in path:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    local value = data.global
    for _, key in ipairs(parts) do
        if type(value) ~= "table" then return nil end
        value = value[key]
    end
    
    return value
end

--- 设置存档变量
function SaveSystem.SetVariable(path, value, slot)
    slot = slot or SaveSystem.currentSlot
    
    -- 确保已加载数据
    if slot ~= SaveSystem.currentSlot or not SaveSystem.currentData then
        local success = SaveSystem.load(slot)
        if not success then return false end
    end
    
    local parts = {}
    for part in path:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    local target = SaveSystem.currentData.global
    for i = 1, #parts - 1 do
        local key = parts[i]
        if type(target[key]) ~= "table" then
            target[key] = {}
        end
        target = target[key]
    end
    
    target[parts[#parts]] = value
    
    -- 保存更改
    local path = SaveSystem.dir .. "save_" .. slot .. ".dat"
    local success, err = love.filesystem.write(path, _serialize(SaveSystem.currentData))
    return success, err
end

--- 获取所有存档信息
function SaveSystem.getSaveSlots()
    local slots = {}
    for i = 1, SaveSystem.slots do
        local info = {
            slot = i,
            exists = false,
            timestamp = 0,
            room = "未创建",
            playTime = 0
        }
        
        local path = SaveSystem.dir .. "save_" .. i .. ".dat"
        if love.filesystem.getInfo(path) then
            local content = love.filesystem.read(path)
            local ok, data = pcall(_deserialize, content)
            if ok and data then
                info.exists = true
                info.timestamp = data.timestamp or os.time()
                info.room = data.global.room or "未知房间"
                info.playTime = data.global.meta and data.global.meta.playTime or 0
            end
        end
        
        table.insert(slots, info)
    end
    return slots
end

--- 删除存档
function SaveSystem.delete(slot)
    local path = SaveSystem.dir .. "save_" .. slot .. ".dat"
    if love.filesystem.getInfo(path) then
        local success = love.filesystem.remove(path)
        if success and slot == SaveSystem.currentSlot then
            SaveSystem.currentData = nil
        end
        return success
    end
    return false
end

return SaveSystem