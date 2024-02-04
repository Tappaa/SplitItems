useSplitItems = {}

function useSplitItems.contextMenu(player, context, items)
    if (#items == 1 and not instanceof(items[1], "InventoryItem") and #items[1].items > 2) then -- 선택한 아이템의 타입이 한 개 이면서 모두 선택한 경우
        local item = items[1].items[1] -- 첫 번째 아이템을 기준으로 처리

        local stackItems = {}
        local rawStackItems = item:getContainer():getAllType(item:getType())

        for i = 1, rawStackItems:size() do
            table.insert(stackItems, i, rawStackItems:get(i - 1))
        end

        context:addOption(getText("ContextMenu_SplitItems"), player, useSplitItems.createSplitItemsUI, stackItems)
    elseif (#items > 1 and instanceof(items[1], "InventoryItem")) then -- 선택한 아이템의 타입이 한 개 이면서 특정 개수만 선택한 경우
        context:addOption(getText("ContextMenu_SplitItems"), player, useSplitItems.createSplitItemsUI, items)
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