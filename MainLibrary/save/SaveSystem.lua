--本库全由deepseek写(zzy只负责可爱 不是),主要是因为我懒得写 ≡ω≡❌
-- 本库由zzy重写

local SaveSystem = {
    slots = 3,              -- 存档位数量
    currentSlot = 1,        -- 当前选中存档位
    dir = "saves/",         -- 存档目录
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
        print("en.Save directory created")
    end
end

--- 序列化
local function _serialize(data, prefix)
    local prefix = prefix or ""
    local save = {}
    
    for key, val in pairs(data) do
        local full_key = (prefix == "" and tostring(key) or prefix .. tostring(key))
        
        if type(val) == "table" then
            -- 检查是否是数组（连续数字索引）
            local is_array = true
            local max_index = 0
            for k, v in pairs(val) do
                if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                    is_array = false
                    break
                end
                if k > max_index then
                    max_index = k
                end
            end
            
            if is_array and max_index > 0 then
                -- 处理数组
                table.insert(save, full_key .. " = [ARRAY]")
                for i = 1, max_index do
                    if val[i] ~= nil then
                        local item_key = full_key .. "." .. tostring(i)
                        if type(val[i]) == "table" then
                            -- 递归处理嵌套表
                            local nested = _serialize(val[i], item_key .. ".")
                            for _, line in ipairs(nested) do
                                table.insert(save, line)
                            end
                        else
                            -- 处理数组元素
                            local value_str = tostring(val[i])
                            if type(val[i]) == "string" then
                                value_str = '"' .. value_str .. '"'  -- 给字符串加引号
                            end
                            table.insert(save, item_key .. " = " .. value_str)
                        end
                    end
                end
            else
                -- 处理普通表
                table.insert(save, full_key .. " = [TABLE]")
                local nested = _serialize(val, full_key .. ".")
                for _, line in ipairs(nested) do
                    table.insert(save, line)
                end
            end
        else
            -- 处理基本类型值
            local value_str = tostring(val)
            if type(val) == "string" then
                value_str = '"' .. value_str .. '"'  -- 给字符串加引号
            end
            table.insert(save, full_key .. " = " .. value_str)
        end
    end
    
    return save
end

--- 反序列化数据
local function _deserialize(str)
    local result = {}
    local current_table = result
    local table_stack = {}
    local current_key = nil
    local current_type = nil  -- "table" 或 "array"
    
    for line in str:gmatch("([^\n]+)") do
        local key, val = line:match("^([^=]+) = (.+)$")
        if key and val then
            -- 处理特殊标记
            if val == "[TABLE]" then
                -- 开始一个新表
                local parts = {}
                for part in key:gmatch("([^.]+)") do
                    table.insert(parts, part)
                end
                
                local current = result
                for i = 1, #parts - 1 do
                    local part = parts[i]
                    if not current[part] or type(current[part]) ~= "table" then
                        current[part] = {}
                    end
                    current = current[part]
                end
                
                current[parts[#parts]] = {}
                table.insert(table_stack, current)
                table.insert(table_stack, current[parts[#parts]])
                current_type = "table"
                
            elseif val == "[ARRAY]" then
                -- 开始一个数组
                local parts = {}
                for part in key:gmatch("([^.]+)") do
                    table.insert(parts, part)
                end
                
                local current = result
                for i = 1, #parts - 1 do
                    local part = parts[i]
                    if not current[part] or type(current[part]) ~= "table" then
                        current[part] = {}
                    end
                    current = current[part]
                end
                
                current[parts[#parts]] = {}
                table.insert(table_stack, current)
                table.insert(table_stack, current[parts[#parts]])
                current_type = "array"
                
            else
                -- 处理普通值
                -- 移除字符串的引号
                if val:sub(1, 1) == '"' and val:sub(-1) == '"' then
                    val = val:sub(2, -2)
                end
                
                -- 转换数据类型
                local num_val = tonumber(val)
                if num_val then
                    val = num_val
                elseif val == "true" then
                    val = true
                elseif val == "false" then
                    val = false
                end
                
                -- 处理键路径
                local parts = {}
                for part in key:gmatch("([^.]+)") do
                    table.insert(parts, part)
                end
                
                local current = result
                for i = 1, #parts - 1 do
                    local part = parts[i]
                    if not current[part] or type(current[part]) ~= "table" then
                        current[part] = {}
                    end
                    current = current[part]
                end
                
                local last_part = parts[#parts]
                if current_type == "array" and tonumber(last_part) then
                    -- 如果是数组，使用数字索引
                    current[tonumber(last_part)] = val
                else
                    -- 如果是表，使用字符串键
                    current[last_part] = val
                end
            end
        end
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
    local serialized = _serialize(data)
    local content = table.concat(serialized, "\n")
    local success, err = love.filesystem.write(path, content)
    
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
    SaveSystem.currentData.player = {
        name = Player.Name or "Player",
        lv = Player.Lv,
        x = Player.sprite.x or 320,
        y = Player.sprite.y or 240,
        hp = Player.Hp or 20,
        maxhp = Player.maxhp or 20,
        gold = Player.gold or 0,
        inventory = Player.inventory or {}
    }
    
    SaveSystem.currentData.room = GetNewmap() or "room1"
    SaveSystem.currentData.landmark = val.landmark or 1
    
    -- 更新元数据
    SaveSystem.currentData.meta.lastModified = os.time()
    SaveSystem.currentData.meta.playTime = (SaveSystem.currentData.meta.playTime or 0) + 
                                                (os.time() - (SaveSystem.currentData.meta.lastPlayTime or os.time()))
    SaveSystem.currentData.meta.lastPlayTime = os.time()
    
    -- 保存到文件
    local content = table.concat(_serialize(SaveSystem.currentData), "\n")
    local success, err = love.filesystem.write(path, content)
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
        return false, "存档文件为空."
    end
    
    local ok, data = pcall(_deserialize, content)
    if not ok or not data then
        -- 尝试修复损坏的存档
        print("en.Archive corruption")
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
        
        local value = SaveSystem.currentData
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
    
    local target = SaveSystem.currentData
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