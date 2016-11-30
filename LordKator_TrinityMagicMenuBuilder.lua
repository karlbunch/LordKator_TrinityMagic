LKTMM_MenuBuilder = {}

function LKTMM_MenuBuilder:New(debug_level)
    return setmetatable({ menu = {}, debug_level = debug_level or 0 }, { __index = LKTMM_MenuBuilder })
end

function LKTMM_MenuBuilder:addToMenu(menuLevel, item, menuValue)
    if self.menu[menuLevel] == nil then
        self.menu[menuLevel] = {}
    end

    if menuValue then
        if self.menu[menuLevel][menuValue] == nil then
            self.menu[menuLevel][menuValue] = {}
        end
        table.insert(self.menu[menuLevel][menuValue], item)
    else
        table.insert(self.menu[menuLevel], item)
    end

    return self
end

function LKTMM_MenuBuilder:InitInfo(menuText, tooltipText, item)
    local i = item or {}
    i.text = menuText
    i.tooltipTitle = i.text
    i.tooltipText = tooltipText
    i.notCheckable = 1
    return i
end

function LKTMM_MenuBuilder:addItem(menuLevel, menuText, tooltipText, item, menuValue)
    local i = self:InitInfo(menuText, tooltipText, item)
    return self:addToMenu(menuLevel, i, menuValue)
end

function LKTMM_MenuBuilder:addItems(menuLevel, items, menuValue)
    if menuValue then
        if self.menu[menuLevel] == nil then
            self.menu[menuLevel] = {}
        end
        self.menu[menuLevel][menuValue] = items
    else
        self.menu[menuLevel] = items
    end

    return self
end

function LKTMM_MenuBuilder:addFlyout(menuLevel, menuText, tooltipText, menuValue)
    local i = self:InitInfo(menuText, tooltipText)
    i.hasArrow = 1
    i.value = menuValue
    return self:addToMenu(menuLevel, i)
end

function LKTMM_MenuBuilder:addTitle(menuLevel, menuText, menuValue)
    local i = self:InitInfo(menuText)
    i.isTitle = 1
    return self:addToMenu(menuLevel, i, menuValue)
end

function LKTMM_MenuBuilder:getItems(menuLevel, menuValue)
    if menuValue then
        if self.menu[menuLevel] then
            return self.menu[menuLevel][menuValue]
        else
            return nil
        end
    else
        if menuLevel then
            return self.menu[menuLevel]
        end
    end
    return self.menu
end

function LKTMM_MenuBuilder:build(menuLevel, menuValue)
    local info = self.menu[menuLevel]

    menuValue = menuValue or UIDROPDOWNMENU_MENU_VALUE

    if menuValue then
        info = info[menuValue]
        if not info then
            info = { { text = "Broken Menu for " .. menuValue, isTitle = 1, } }
        end
    end

    for k,v in pairs(info) do
        UIDropDownMenu_AddButton(v, menuLevel)
    end

    return info
end
