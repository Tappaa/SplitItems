useSplitItems = {}

function useSplitItems.contextMenu(player, context, items) -- 컨텍스트 메뉴에 항목 추가
    if (#items == 1 and not instanceof(items[1], "InventoryItem")) then -- 선택한 아이템의 타입이 한 개 이면서 모두 선택한 경우
        local item = items[1].items[1] -- 첫 번째 아이템을 기준으로 처리

        local stackItems = {}
        local rawStackItems = item:getContainer():getAllType(item:getType())

        for i = 1, rawStackItems:size() do
            if (not SplitItemsConfig.includeWearingItems and (rawStackItems:get(i - 1):isEquipped() or rawStackItems:get(i - 1):getAttachedSlot() ~= -1)) then -- 아이템을 착용중인지 확인
                -- 착용중인 아이템은 제외
            else
                table.insert(stackItems, rawStackItems:get(i - 1))
            end
        end

        if (#items[1].items <= 2 and #stackItems == 1) then -- 선택한 아이템의 개수가 2개 이하이면서 스택된 아이템이 1개인 경우
            return
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