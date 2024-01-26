useSplitItems = {}

function useSplitItems.isSameItemType(items)
    if (items[1].items ~= nil) then
        return false
    else
        return true
    end
end

function useSplitItems.contextMenu(player, context, items)
    for _, v in ipairs(items) do
        local item = v

        if not (instanceof(item, "InventoryItem")) then
            item = v.items[1]
        end

        local stackItems = {}
        local rawStackItems = item:getContainer():getAllType(item:getType())

        -- 데이터 가공
        for i = 1, rawStackItems:size() do
            table.insert(stackItems, i, rawStackItems:get(i - 1))
        end

        if (#items == 1 and #stackItems > 1) then
            context:addOption(getText("ContextMenu_SplitItems"), player, useSplitItems.createSplitItemsUI, stackItems)
        elseif (#items > 1 and useSplitItems.isSameItemType(items)) then
            context:addOption(getText("ContextMenu_SplitItems"), player, useSplitItems.createSplitItemsUI, items)
        end
        break
    end
end

function useSplitItems.createSplitItemsUI(player, items)
    local character = getSpecificPlayer(player)
    local ui = useSplitItemsUI:new(getMouseX(), getMouseY(), 300, 180, character, items)
    ui:setVisible(true)
    ui:addToUIManager()
    ui:initialise()
    return ui
end

Events.OnFillInventoryObjectContextMenu.Add(useSplitItems.contextMenu)