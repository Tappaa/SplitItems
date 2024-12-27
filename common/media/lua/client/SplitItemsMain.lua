useSplitItems = {}

local function shallowCopy(orig)
    local copy = {}
    for key, value in pairs(orig) do
        copy[key] = value
    end
    return copy
end

function useSplitItems.contextMenu(player, context, items) -- 컨텍스트 메뉴에 항목 추가
    local itemData
    local xStackItems = {}
    local skipYStackItems = false
    if (#items == 1 and not instanceof(items[1], "InventoryItem")) then -- 선택한 아이템의 타입이 한 개 이면서 모두 선택한 경우
        itemData = items[1].items[1] -- 첫 번째 아이템을 기준으로 처리

        local originItem = getScriptManager():FindItem(itemData:getType()) -- 아이템의 이름을 가져옴

        if (originItem:getName():contains("Empty") or originItem:getName():contains("Bottle")) then -- 액체 컨테이너인 경우
            skipYStackItems = true
        end

        xStackItems = shallowCopy(items[1].items)
        table.remove(xStackItems, 1) -- 첫 번째 아이템을 제외한 나머지 아이템들을 가져옴
    elseif (#items > 1 and instanceof(items[1], "InventoryItem")) then -- 선택한 아이템의 타입이 한 개 이면서 특정 개수만 선택한 경우
        itemData = items[1] -- 첫 번째 아이템을 기준으로 처리

        local originItem = getScriptManager():FindItem(itemData:getType()) -- 아이템의 이름을 가져옴
        local isOriginItemFluid = originItem:getName():contains("Empty") or originItem:getName():contains("Bottle") -- 액체 컨테이너인지 확인

        for i = 1, #items do
            if (originItem:getDisplayName() ~= items[i]:getDisplayName()) then -- 아이템의 이름이 다른 경우
                if (isOriginItemFluid and items[i]:getType():contains("Empty") or items[i]:getType():contains("Bottle")) then
                    -- 아이템의 이름이 다르지만 액체 컨테이너인 경우
                    skipYStackItems = true
                else
                    return
                end
            end
        end

        xStackItems = items
    elseif (#items == 1 and instanceof(items[1], "InventoryItem")) then -- 선택한 아이템의 타입이 한 개 이면서 컨테이너 내에 스택되지 않은 아이템을 선택한 경우
        itemData = items[1] -- 첫 번째 아이템을 기준으로 처리

        if (itemData:getContainer():getAllType(itemData:getType()):size() == 1) then -- 컨테이너 내에 스택되지 않은 아이템이 1개인 경우
            return
        end
    else
        return
    end

    local yStackItems = {}
    local rawStackItems = itemData:getContainer():getAllType(itemData:getType())

    local stackItems = {}

    if (not skipYStackItems) then
        for i = 1, rawStackItems:size() do
            if (not splitItemsModOption.includeWearingItems.value and (rawStackItems:get(i - 1):isEquipped() or rawStackItems:get(i - 1):getAttachedSlot() ~= -1)) then -- 아이템을 착용중인지 확인
                -- 착용중인 아이템은 제외
            else
                table.insert(yStackItems, rawStackItems:get(i - 1))
            end
        end

        if (#xStackItems <= 1 and #yStackItems <= 1) then -- 스택된 아이템이 아닌 경우
            return
        end

        if (#xStackItems > #yStackItems) then -- 두 스택의 아이템 개수를 비교하여 더 많은 개수를 선택
            stackItems = xStackItems
        else
            stackItems = yStackItems
        end
    else
        if (#xStackItems == 1) then -- 스택된 아이템이 아닌 경우
            return
        end

        stackItems = xStackItems
    end

    context:addOption(getText("ContextMenu_SplitItems"), player, useSplitItems.createSplitItemsUI, stackItems)
end

function useSplitItems.dragNDropSplit() -- 드래그 앤 드롭으로 아이템을 나누기
    local originalPerform = ISInventoryTransferAction.perform
    function ISInventoryTransferAction:perform()
        local configKey = splitItemsModOption.keyBind.key

        if isKeyDown(configKey) then
            self:checkQueueList()

            local player = self.character
            local queuedItems = self.queueList
            local destContainer = self.destContainer

            -- queuedItems에서 아이템정보를 가져옴
            local xStackItems = {}
            local itemTypes = {}
            for i = 1, #queuedItems do
                for j = 1, #queuedItems[i].items do
                    table.insert(xStackItems, queuedItems[i].items[j])
                end
                table.insert(itemTypes, queuedItems[i].type)
            end

            local isDifferentItem = false
            for i = 1, #itemTypes do
                if (itemTypes[1] ~= itemTypes[i]) then
                    if (string.find(itemTypes[i], "Empty") ~= nil or string.find(itemTypes[i], "Bottle") ~= nil) then -- 액체 컨테이너인 경우
                        -- 아이템의 이름이 다르지만 액체 컨테이너인 경우
                    else
                        isDifferentItem = true
                        break
                    end
                end
            end

            if (#xStackItems <= 1 or isDifferentItem) then -- 스택된 아이템이 아니거나 같은 아이템이 아닌 경우
                originalPerform(self)
                return
            end

            self:forceStop() -- ISInventoryTransferAction을 강제로 중지
            useSplitItems.createSplitItemsUI(player:getPlayerNum(), xStackItems, destContainer)
            return
        end
        originalPerform(self)
    end

    local originalNew = ISInventoryTransferAction.new
    function ISInventoryTransferAction:new (character, item, srcContainer, destContainer, time)
        local configKey = splitItemsModOption.keyBind.key

        if isKeyDown(configKey) then
            local o = originalNew(self, character, item, srcContainer, destContainer, time)
            o.maxTime = 0
            return o
        end
        return originalNew(self, character, item, srcContainer, destContainer, time)
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