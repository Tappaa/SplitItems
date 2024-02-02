useSplitItems = {}

function useSplitItems.contextMenu(player, context, items)
    for _, v in ipairs(items) do

        if (not instanceof(v, "InventoryItem") and #items == 1 and #v.items > 2) then -- 선택한 아이템의 타입이 한 개 이면서 모두 선택한 경우
            local _items = useSplitItems.deepClone(v.items)
            table.remove(_items, 1)
            context:addOption(getText("ContextMenu_SplitItems"), player, useSplitItems.createSplitItemsUI, _items)
        elseif (instanceof(v, "InventoryItem") and #items > 1) then -- 선택한 아이템의 타입이 한 개 이면서 특정 개수만 선택한 경우
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

function useSplitItems.deepClone(original)
    local clone = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = deepClone(v)
        end
        clone[k] = v
    end
    return clone
end

Events.OnFillInventoryObjectContextMenu.Add(useSplitItems.contextMenu)