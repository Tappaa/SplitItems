useSplitItemsUI = ISCollapsableWindow:derive("SplitItemsUI")

function useSplitItemsUI:new(x, y, width, height, player, items)
    local o = {}
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:setResizable(false)
    o.pin = true
    o.title = getText("UI_SplitItems_Title", items[1]:getDisplayName())
    o.player = player
    o.items = items
    o.lastSquare = player:getCurrentSquare()

    return o
end

function useSplitItemsUI:prerender()
    ISCollapsableWindow.prerender(self)
    local text = getText("UI_SplitItems_Text", self.items[1]:getDisplayName(), self.sliderPanel.currentValue, #self.items)
    self:drawText(text, 100, 30, 1, 1, 1, 1, UIFont.Small)
end

function useSplitItemsUI:initialise()
    ISCollapsableWindow.initialise(self)

    self.sliderPanel = ISSliderPanel:new(10, 60, 220, 30, self, useSplitItemsUI.onSliderChange)
    self.sliderPanel:setValues(1, #self.items, 1, 0)
    self.sliderPanel:setCurrentValue(#self.items)
    self.sliderPanel:initialise()
    self.sliderPanel:instantiate()
    self.sliderPanel.doToolTip = false
    self:addChild(self.sliderPanel)

    self.entryText = ISTextEntryBox:new(tostring(#self.items), 240, 60, 50, 30)
    self.entryText.internal = "ITEM_COUNT"
    self.entryText:initialise()
    self.entryText:instantiate()
    self.entryText:setOnlyNumbers(true)
    self.entryText:setTooltip(getText("UI_SplitItems_entryText_Tooltip"))
    self:addChild(self.entryText)

    self.comboBox = ISComboBox:new(10, 100, 280, 30, self)
    self.comboBox:initialise()
    self.comboBox:instantiate()
    self:addChild(self.comboBox)

    self.comboBox:addOption(getText("UI_SplitItems_Select_Inventory"))

    self.containers = {}

    -- 데이터 가공
    local containers = useSplitItemsUI:getContainers(self.player)
    for i = 1, containers:size() do
        local data = containers:get(i - 1)
        local name = data.name
        local container = data.inventory
        if (not container:contains(self.items[1]) and container:getType() ~= "KeyRing") then
            self.comboBox:addOption(name)
            table.insert(self.containers, container)
        end
    end

    self.splitButton = ISButton:new(10, 140, 135, 30, getText("UI_SplitItems_Split"), self, useSplitItemsUI.onMouseDown)
    self.splitButton.internal = "SPLIT"
    self.splitButton:initialise()
    self.splitButton:instantiate()
    self:addChild(self.splitButton)

    self.closeButton = ISButton:new(155, 140, 135, 30, getText("UI_SplitItems_Cancel"), self, useSplitItemsUI.onMouseDown)
    self.closeButton.internal = "CLOSE"
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)
end

function useSplitItemsUI:onMouseDown(button)
    if (button.internal == "SPLIT" and button.parent.comboBox.selected ~= 1) then
        for i = 1, button.parent.sliderPanel.currentValue do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, self.items[i], self.items[i]:getContainer(), self.containers[button.parent.comboBox.selected - 1]))
        end
        self:close()
    elseif (button.internal == "CLOSE") then
        self:close()
    else
        ISCollapsableWindow.onMouseDown(self, button)
    end
end

function useSplitItemsUI:onSliderChange(slider)
    if (self.entryText ~= nil) then
        self.entryText:setText(tostring(slider))
    end
end

function ISTextEntryBox:onCommandEntered()
    if (self.internal == "ITEM_COUNT") then
        if (tonumber(self:getText()) <= #self.parent.items) then
            self.parent.sliderPanel:setCurrentValue(tonumber(self:getText()))
        else
            self:setText(tostring(#self.parent.items))
            self.parent.sliderPanel:setCurrentValue(tonumber(self:getText()))
        end
    else
        ISCollapsableWindow.onCommandEntered(self)
    end
end

-- ISIventoryPaneContextMenu.lua 에서 가져옴
function useSplitItemsUI:getContainers(character)
    local containerList = ArrayList.new();
    for _, v in ipairs(getPlayerInventory(character:getPlayerNum()).inventoryPane.inventoryPage.backpacks) do
        containerList:add(v);
    end
    for _, v in ipairs(getPlayerLoot(character:getPlayerNum()).inventoryPane.inventoryPage.backpacks) do
        containerList:add(v);
    end
    return containerList;
end

-- 플레이어가 움직이면 ComboBox 업데이트
function useSplitItemsUI:update()
    ISCollapsableWindow.update(self)
    if (self:getIsVisible() and self.player:getCurrentSquare() ~= self.lastSquare) then
        self:close()
    end

    --if (self:getIsVisible() and self.player:getCurrentSquare() ~= self.lastSquare) then
    --    -- comboBox 1번 인덱스 제외 모두 삭제
    --    for i = 1, #self.containers do
    --        self.comboBox:removeChild(self.comboBox.options[i + 1])
    --    end
    --
    --    self.containers = {}
    --
    --    -- 데이터 가공
    --    local containers = useSplitItemsUI:getContainers(self.player)
    --    for i = 1, containers:size() do
    --        local data = containers:get(i - 1)
    --        local name = data.name
    --        local container = data.inventory
    --        if (not container:contains(self.items[1]) and container:getType() ~= "KeyRing") then
    --            self.comboBox:addOption(name)
    --            table.insert(self.containers, container)
    --        end
    --    end
    --
    --    self.lastSquare = self.player:getCurrentSquare()
    --end
end