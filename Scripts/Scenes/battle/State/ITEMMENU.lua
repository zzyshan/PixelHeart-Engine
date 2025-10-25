local ITEMMENU = {
    current_page = 1,
    itemindex = 1,
    items_per_page = 4,
    total_pages = 1,
    page_text = nil
}

-- 创建物品文本
function ITEMMENU.CreateItemTexts(ui)
    ui.ClearTexts(ui.itemtext)
    ui.itemtext = {}
    if ITEMMENU.page_text then
        ITEMMENU.page_text:Remove()
    end
    if Player.inventory[1] == nil then return end
    
    -- 计算当前页的物品范围
    local start_index = ITEMMENU.items_per_page * (ITEMMENU.current_page - 1) + 1
    local end_index = math.min(start_index + ITEMMENU.items_per_page - 1, #Player.inventory)
    
    -- 创建位置映射表 (按阅读顺序: 左->右, 上->下)
    local positions = {
        {x = 100, y = 270},  -- 位置1: 左上
        {x = 340, y = 270},  -- 位置2: 右上
        {x = 100, y = 302},  -- 位置3: 左下
        {x = 340, y = 302}   -- 位置4: 右下
    }
    
    -- 按视觉顺序创建物品文本
    for i = start_index, end_index do
        local item = Player.inventory[i]
        local position_index = i - start_index + 1
        
        local pos = positions[position_index]

        local item_text = typer.Print(
            "[size:28]* " .. item.name,
            {pos.x, pos.y},
            3)
        table.insert(ui.itemtext, item_text)
    end
    
    ITEMMENU.page_text = typer.Print(
        "[size:28]PAGE " .. ITEMMENU.current_page .. "/" .. ITEMMENU.total_pages,
        {385, 335},
        3
    )
end

-- 修正后的导航逻辑
function ITEMMENU.update(ui)
    -- 计算当前页物品数量
    local start_index = ITEMMENU.items_per_page * (ITEMMENU.current_page - 1) + 1
    local end_index = math.min(start_index + ITEMMENU.items_per_page - 1, #Player.inventory)
    local page_item_count = end_index - start_index + 1
    
    -- 确保选中位置有效
    if ITEMMENU.itemindex > page_item_count then
        ITEMMENU.itemindex = page_item_count
    end
    
    -- 设置玩家位置 (基于视觉布局)
    if page_item_count > 0 then
        Player.sprite.x = ui.itemtext[ITEMMENU.itemindex].x - 25
        Player.sprite.y = ui.itemtext[ITEMMENU.itemindex].y + 15
    end
    
    -- 导航处理 (修正方向)
    if Keyboard.getState("down") == 1 then
        -- 向下移动: 从位置1->3, 位置2->4
        if ITEMMENU.itemindex + 2 <= page_item_count then
            ITEMMENU.itemindex = ITEMMENU.itemindex + 2
            Audio.PlaySound("snd_menu_0.wav")
        elseif ITEMMENU.itemindex - 2 >= 1 then
            ITEMMENU.itemindex = ITEMMENU.itemindex - 2
            Audio.PlaySound("snd_menu_0.wav")
        end
    end
    
    if Keyboard.getState("up") == 1 then
        -- 向上移动: 从位置3->1, 位置4->2
        if ITEMMENU.itemindex > 2 then
            ITEMMENU.itemindex = ITEMMENU.itemindex - 2
            Audio.PlaySound("snd_menu_0.wav")
        elseif ITEMMENU.itemindex + 2 <= page_item_count then
            ITEMMENU.itemindex = ITEMMENU.itemindex + 2
            Audio.PlaySound("snd_menu_0.wav")
        end
    end
    
    if Keyboard.getState("right") == 1 then
        -- 向右移动: 位置1->2, 位置3->4
        if ITEMMENU.itemindex % 2 == 1 and ITEMMENU.itemindex + 1 <= page_item_count then
            ITEMMENU.itemindex = ITEMMENU.itemindex + 1
            Audio.PlaySound("snd_menu_0.wav")
        -- 翻到下一页 (如果在右列)
        elseif ITEMMENU.current_page < ITEMMENU.total_pages then
            ITEMMENU.current_page = ITEMMENU.current_page + 1
            ITEMMENU.itemindex = 1  -- 新页面从左上角开始
            Audio.PlaySound("snd_menu_0.wav")
            ITEMMENU.CreateItemTexts(ui)
        end
    end
    
    if Keyboard.getState("left") == 1 then
        -- 向左移动: 位置2->1, 位置4->3
        if ITEMMENU.itemindex % 2 == 0 then
            ITEMMENU.itemindex = ITEMMENU.itemindex - 1
            Audio.PlaySound("snd_menu_0.wav")
        -- 翻到上一页 (如果在左列)
        elseif ITEMMENU.current_page > 1 then
            ITEMMENU.current_page = ITEMMENU.current_page - 1
            ITEMMENU.itemindex = 2  -- 新页面从右上角开始
            Audio.PlaySound("snd_menu_0.wav")
            ITEMMENU.CreateItemTexts(ui)
        end
    end
    
    -- 确认选择物品
    if Keyboard.getState("z") == 1 and page_item_count > 0 then
        local global_index = (ITEMMENU.current_page - 1) * ITEMMENU.items_per_page + ITEMMENU.itemindex
        local selected_item = Player.inventory[global_index]
        
        if selected_item then
            battle.HandleItems(selected_item.name)
            if selected_item.mode ~= 3 then
                table.remove(Player.inventory, global_index)
            end
            
            ui.ClearTexts(ui.itemtext)
            ITEMMENU.page_text:Remove()
        end
        Player.sprite.hide = true
        Audio.PlaySound("snd_menu_1.wav")
        STATE("DIALOGRESULT")
        
    -- 取消选择
    elseif Keyboard.getState("x") == 1 then
        ui.ClearTexts(ui.itemtext)
        if ITEMMENU.page_text then
            ITEMMENU.page_text:Remove()
            ITEMMENU.page_text = nil
        end
        Audio.PlaySound("snd_menu_0.wav")
        STATE("ACTIONSELECT")
    end
end

-- 初始化物品菜单
function ITEMMENU.init()
    ITEMMENU.total_pages = math.ceil(#Player.inventory / ITEMMENU.items_per_page)
    ITEMMENU.current_page = 1
    ITEMMENU.itemindex = 1
    
    if Player.inventory[1] then return true end
end

return ITEMMENU