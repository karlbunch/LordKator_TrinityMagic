--[[
--
-- LordKator_TrinityMagicMenu - Lord Kator's Trinity Core MagicMenu
--
-- Author: Lord Kator <kator@karlbunch.com>
--
-- Created: Sun Nov 27 19:40:38 EST 2016
]]

LKTMM = {
    commandTips = {
        [".group summon"] = {
            tooltipTitle = "Group Summon",
            tooltipText = "Summon your group to your location."
        },
        [".appear"] = {
            tooltipTitle = "Appear At Target",
            tooltipText = "Teleports you to the target."
        },
        [".summon"] = {
            tooltipTitle = "Summon To Me",
            tooltipText = "Teleports the target to you.",
        },
        [".die"] = {
            tooltipTitle = "Die",
            tooltipText ="Kills the target instantly.",
        },
        [".recall"] = {
            tooltipTitle = "Return To Previous Location",
            tooltipText = "Returns the target to the last location they teleported from or zoned into.",
        },
        [".revive"] = {
            tooltipTitle = "Revive",
            tooltipText = "Revive the target from death or damage.",
        },
        [".repairitems"] = {
            tooltipTitle = "Repair Items",
            tooltipText = "Repair the target's items.",
        },
    }
}

function LKTMM:SetDefaultCommand()
    LKTM:PromptForCommand()
end

function LKTMM:LordKator_TrinityMagicMenu_InitializeDropDown(self, level)
    level = level or 1
    local menuTable = {}

    local function appendMenuItem(menuLevel, menuText, tooltipText, item, keyValue)
        item['text'] = menuText
        item['tooltipTitle'] = menuText
        item['tooltipText'] = tooltipText
        item['notCheckable'] = 1

        if menuTable[menuLevel] == nil then
            menuTable[menuLevel] = {}
        end
        table.insert(menuTable[menuLevel], item)
    end
    local function appendMenuCommand(level, command)
        local tips = LKTMM.commandTips[command]

        if tips then
            appendMenuItem(level, tips.tooltipTitle, tips.tooltipText, {
                func = function(frame) LKTM:CommandOnUnit("target", command) end,
            })
        else
            addMenuItem(level, command, "", {
                func = function(frame) LKTM:CommandOnUnit("target", command) end,
            })
        end
    end

    -- Build Menu
    appendMenuItem(1, "Trinity Core Magic Menu", "", { text = "Trinity Core Magic Menu", isTitle = 1, })

    appendMenuItem(1, "Set Control-Click Command","Set the command to run when you control-click a target", {
        hasArrow = 1,
    })

    -- Context Sensitive Items
    if UnitIsUnit("player", "target") then
        if GetNumPartyMembers() > 0 then
            appendMenuCommand(1, ".group summon")
        end
    elseif UnitIsPlayer("target") then
        appendMenuCommand(1, ".appear")
        appendMenuCommand(1, ".summon")
    else
        appendMenuCommand(1, ".die")
    end

    if UnitIsPlayer("target") then
        appendMenuCommand(1, ".recall")
        appendMenuCommand(1, ".revive")
        appendMenuCommand(1, ".repairitems")
    end

    appendMenuItem(2, "Set Control-Click Command", "", { text = "Set Control-Click Command", isTitle = 1, })

    appendMenuItem(2, "Prompt For Command","Prompt for command to use as control-click default.", {
        func = LKTMM.SetDefaultCommand,
    })

    for cmd,tips in pairs(LKTMM.commandTips) do
        appendMenuItem(2, tips.tooltipTitle, tips.tooltipText, {
            func = function(frame)
                LKTM:SetDefaultCommand(cmd)
                CloseDropDownMenus()
            end
        })
    end

    local history = LKTM:GetCommandHistory()

    for cmd, count in pairs(history) do
        if LKTMM.commandTips[cmd] == nil then
            appendMenuItem(2, cmd, "", {
                func = function(frame)
                    LKTM:SetDefaultCommand(cmd)
                    CloseDropDownMenus()
                end
            })
        end
    end

    -- Every Level Gets a Close
    for k,v in ipairs(menuTable) do
        if type(k) == "number" then
            appendMenuItem(k, CLOSE, "Close Menu", {
                func = function(frame) CloseDropDownMenus() end,
            })
        end
    end

    local info = menuTable[level]

    --[[
    local menuValue = UIDROPDOWNMENU_MENU_VALUE

    if menuValue then
        if info[menuValue] then
            info = info[menuValue]
        else
            info = { }
        end
    end
    ]]

    for idx,entry in ipairs(info) do
        UIDropDownMenu_AddButton(entry, level)
    end
end

function LKTMM:Init(parent)
end

function LKTMM:Show(parent, unit)
    local anchorName, xOfs, yOfs = "TargetFrame", 120, 10

    if UnitIsUnit("player", "target") then
        anchorName, xOfs, yOfs = "PlayerFrame", 106, 27
    end

    if string.sub(unit, 1, 5) == "party" then
        anchorName, xOfs, yOfs = "PartyMemberFrame" .. string.sub(unit, 6, -1), 47, 15
    end

    local LordKator_TrinityMagicMenuDropDown = CreateFrame("Frame", "LordKator_TrinityMagicMenuDropDown", _G[anchorName], "UIDropDownMenuTemplate") 

    UIDropDownMenu_Initialize(LordKator_TrinityMagicMenuDropDown, function(frame, level, menuList) LKTMM:LordKator_TrinityMagicMenu_InitializeDropDown(frame, level, menuList) end, "MENU")
    ToggleDropDownMenu(1, nil, LordKator_TrinityMagicMenuDropDown, anchorName, xOfs, yOfs)
end
