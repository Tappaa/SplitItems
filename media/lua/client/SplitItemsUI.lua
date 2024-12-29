useSplitItemsUI = ISCollapsableWindow:derive("SplitItemsUI")

function useSplitItemsUI.getContainers(character) -- ISIventoryPaneContextMenu.lua 에서 가져옴
    local containerTable = {}
    for _, v in ipairs(getPlayerInventory(character:getPlayerNum()).inventoryPane.inventoryPage.backpacks) do
        table.insert(containerTable, v)
    end
    for _, v in ipairs(getPlayerLoot(character:getPlayerNum()).inventoryPane.inventoryPage.backpacks) do
        table.insert(containerTable, v)
    end
    return containerTable
end

function useSplitItemsUI.addComboBoxOption(self) -- ComboBox에 옵션 추가
    self.comboBox:addOption(getText("UI_SplitItems_Select_Inventory"))

    self.containers = {}
    tempContainer = {}

    local containers = useSplitItemsUI.getContainers(self.player) -- 데이터 가공
    for _, v in ipairs(containers) do
        local data = v
        local name = data.name
        local container = data.inventory
        if (not container:contains(self.items[1]) and container:getType() ~= "KeyRing") then
            table.insert(tempContainer, {["name"] = name, ["inventory"] = container, ["type"] = container:getType()})
        end
    end

    if (SplitItemsConfig.sortContainerByName) then
        local jump = 0

        if (tempContainer[1].type == "none") then -- 플레이어 메인 인벤토리
            table.insert(self.containers, tempContainer[1])
            table.remove(tempContainer, 1)
            jump = 1
        end

        if (tempContainer[#tempContainer].type == "floor") then -- 바닥 인벤토리
            table.insert(self.containers, tempContainer[#tempContainer])
            table.remove(tempContainer, #tempContainer)
        end

        table.sort(tempContainer, function(a, b) return a.name < b.name end) -- 이름을 A-Z 순으로 정렬

        for i, v in ipairs(tempContainer) do
            table.insert(self.containers, i + jump, v)
        end
    else
        self.containers = tempContainer
    end

    for _, v in ipairs(self.containers) do
        self.comboBox:addOption(v.name)
    end
end

function useSplitItemsUI.canTransferItems(character, container) -- 아이템을 옮길 수 있는지 확인
    local playerContainers = useSplitItemsUI.getContainers(character)

    for _, v in ipairs(playerContainers) do
        if (v.inventory == container) then
            return true
        end
    end
    return false
end

function useSplitItemsUI:new(x, y, width, height, player, items) -- UI 생성
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
    o.itemCount = #items

    return o
end

function useSplitItemsUI:prerender()
    ISCollapsableWindow.prerender(self)
    local itemWeight = 0
    for i = 1, self.sliderPanel.currentValue do
        if (self.items[i]:getAmmoType() ~= nil and not self.items[i]:isEquipped() and self.items[i]:getAttachedSlot() == -1) then -- 탄약의 무게 계산
            local ammoType = self.items[i]:getAmmoType()
            local ammoCount = self.items[i]:getCurrentAmmoCount()
            local ammoWeight = ammoType:getActualWeight()

            itemWeight = itemWeight + (ammoWeight * ammoCount)
        end

        if (self.items[i]:isEquipped()) then -- 아이템이 장착되어 있는 경우 무게 계산
            itemWeight = itemWeight + self.items[i]:getEquippedWeight()
        else if (self.items[i]:getAttachedSlot() ~= -1) then -- 아이템이 장착되어 있는 경우 무게 계산
            itemWeight = itemWeight + self.items[i]:getHotbarEquippedWeight()
        else
            itemWeight = itemWeight + self.items[i]:getActualWeight()
        end
        end
    end

    itemWeight = math.floor(itemWeight * 10 ^ (SplitItemsConfig.maxItemWeightDecimalPlaces) + 0.5) / 10 ^ (SplitItemsConfig.maxItemWeightDecimalPlaces)

    local text = getText("UI_SplitItems_Text", self.items[1]:getDisplayName(), self.sliderPanel.currentValue, self.itemCount, itemWeight)
    self:drawText(text, 100, 30, 1, 1, 1, 1, UIFont.Small)
end

function useSplitItemsUI:initialise()
    ISCollapsableWindow.initialise(self)

    self.sliderPanel = ISSliderPanel:new(10, 60, 220, 30, self, useSplitItemsUI.onSliderChange)
    self.sliderPanel:setValues(1, self.itemCount, 1, 0)
    self.sliderPanel:setCurrentValue(self.itemCount)
    self.sliderPanel:initialise()
    self.sliderPanel:instantiate()
    self.sliderPanel.doToolTip = false
    self:addChild(self.sliderPanel)

    self.entryText = ISTextEntryBox:new(tostring(self.itemCount), 240, 60, 50, 30)
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

    useSplitItemsUI.addComboBoxOption(self)

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

function useSplitItemsUI:onMouseDown(button) -- 버튼을 누르면 실행
    if (button.internal == "SPLIT" and button.parent.comboBox.selected ~= 1) then
        local selectedContainer = self.containers[button.parent.comboBox.selected - 1].inventory

        if (useSplitItemsUI.canTransferItems(self.player, self.items[1]:getContainer())) then
            for i = 1, button.parent.sliderPanel.currentValue do
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, self.items[i], self.items[i]:getContainer(), selectedContainer))
            end
        end
        self:close()
    elseif (button.internal == "CLOSE") then
        self:close()
    else
        ISCollapsableWindow.onMouseDown(self, button)
    end
end

function useSplitItemsUI:onSliderChange(slider) -- 슬라이더가 움직이면 실행
    if (self.entryText ~= nil) then
        self.entryText:setText(tostring(slider))
    end
end

function ISTextEntryBox:onCommandEntered() -- 텍스트 박스에 입력후 엔터키를 누르면 실행
    if (self.internal == "ITEM_COUNT") then
        if (tonumber(self:getText()) <= #self.parent.items) then
            self.parent.sliderPanel:setCurrentValue(tonumber(self:getText()))
        else
            self:setText(tostring(#self.parent.items))
            self.parent.sliderPanel:setCurrentValue(tonumber(self:getText()))
        end
    end
end

function useSplitItemsUI:update() -- 플레이어가 움직이면 ComboBox 업데이트
    ISCollapsableWindow.update(self)
    if (self:getIsVisible() and self.player:getCurrentSquare() ~= self.lastSquare) then
        self.lastSquare = self.player:getCurrentSquare()
        self.comboBox:clear()
        useSplitItemsUI.addComboBoxOption(self)
    end
end