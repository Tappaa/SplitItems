splitItemsModOption = {
    sortContainerByName = nil,
    maxItemWeightDecimalPlaces = nil,
    includeWearingItems = nil,
    keyBind = nil
};

function splitItemsModOption.init()
    local options = PZAPI.ModOptions:create("SplitItems", getText("UI_options_SplitItems_Title"));

    splitItemsModOption.sortContainerByName = options:addTickBox("0", getText("UI_options_SplitItems_SortContainerByName"), true, getText("UI_options_SplitItems_SortContainerByName_tooltip"));
    splitItemsModOption.maxItemWeightDecimalPlaces = options:addSlider("1", getText("UI_options_SplitItems_MaxItemDecimalPlaces"), 0, 2, 1, 2, getText("UI_options_SplitItems_MaxItemDecimalPlaces_tooltip"));
    splitItemsModOption.includeWearingItems = options:addTickBox("2", getText("UI_options_SplitItems_IncludeWaringItemsInStack"), false, getText("UI_options_SplitItems_IncludeWaringItemsInStack_tooltip"));
    splitItemsModOption.keyBind = options:addKeyBind("3", getText("UI_options_SplitItems_ShortCut"), isSystemMacOS() and Keyboard.KEY_LMETA or Keyboard.KEY_LMENU, getText("UI_options_SplitItems_ShortCut_tooltip"));
end

splitItemsModOption.init();