useSplitItems = {}

function useSplitItems.contextMenu(player, context, items) -- 컨텍스트 메뉴에 항목 추가
    if (#items == 1 and not instanceof(items[1], "InventoryItem")) then -- 선택한 아이템의 타입이 한 개 이면서 모두 선택한 경우
        local item = items[1].items[1] -- 첫 번째 아이템을 기준으로 처리

        local stackItems = {}
        local rawStackItems = item:getContainer():getAllType(item:getType())

        for i = 1, rawStackItems:size() do
            if (not splitItemsModOption.includeWearingItems.value and (rawStackItems:get(i - 1):isEquipped() or rawStackItems:get(i - 1):getAttachedSlot() ~= -1)) then -- 아이템을 착용중인지 확인
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

function useSplitItems.dragNDropSplit() -- 드래그 앤 드롭으로 아이템을 나누기
    local originalPerform = ISInventoryTransferAction.start
    function ISInventoryTransferAction:start()
        local configKey = splitItemsModOption.keyBind.key

        if isKeyDown(configKey) then
            local player = self.character
            local items = self.item
            local srcContainer = self.srcContainer
            local destContainer = self.destContainer

            -- items 변수의 아이템과 같은 타입의 아이템을 모두 가져옴
            local stackItems = {}
            local rawStackItems = items:getContainer():getAllType(items:getType())

            for i = 1, rawStackItems:size() do
                if (not splitItemsModOption.includeWearingItems.value and (rawStackItems:get(i - 1):isEquipped() or rawStackItems:get(i - 1):getAttachedSlot() ~= -1)) then -- 아이템을 착용중인지 확인
                    -- 착용중인 아이템은 제외
                else
                    table.insert(stackItems, rawStackItems:get(i - 1))
                end
            end

            if (#stackItems == 1) then -- 스택된 아이템이 1개인 경우
                originalPerform(self)
                return
            end

            self:forceStop() -- ISInventoryTransferAction를 강제로 중지
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, items, destContainer, srcContainer, 0))
            useSplitItems.createSplitItemsUI(player:getPlayerNum(), stackItems, destContainer)
            return

        end
        originalPerform(self)
    end
end

function useSplitItems.createSplitItemsUI(player, items, container)
    local character = getSpecificPlayer(player)
    local ui = useSplitItemsUI:new(getMouseX(), getMouseY(), 300, 180, character, items, container)
    ui:setVisible(true)
    ui:addToUIManager()
    ui:initialise()
    return ui
end

Events.OnFillInventoryObjectContextMenu.Add(useSplitItems.contextMenu)
Events.OnGameStart.Add(useSplitItems.dragNDropSplit)