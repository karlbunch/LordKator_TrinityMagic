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

function LKTMM:LordKator_TrinityMagicMenu_InitializeDropDown(self, level, menuList)
    level = level or 1

    print("LKTMM:LordKator_TrinityMagicMenu_InitializeDropDown(" .. (self or "nil") .. ", " .. (level or "nil") .. ", " .. (menuList or "nil") .. ")")

    local menuTable = {}
    local function appendMenuItem(menuText, tooltipText, item, keyValue)
        local idx = keyValue or 1

        item['text'] = menuText
        item['tooltipTitle'] = menuText
        item['tooltipText'] = tooltipText
        item['notCheckable'] = 1

        if menuTable[idx] == nil then
            menuTable[idx] = {}
        end
        table.insert(menuTable[idx], item)
    end
    local function appendMenuCommand(command)
        local tips = LKTMM.commandTips[command]

        if tips then
            appendMenuItem(tips.tooltipTitle, tips.tooltipText, {
                func = function(self) LKTM:CommandOnUnit("target", command) end,
            })
        else
            addMenuItem(command, "", {
                func = function(self) LKTM:CommandOnUnit("target", command) end,
            })
        end
    end

    -- Build Menu
    appendMenuItem("Trinity Core Magic Menu", "", { text = "Trinity Core Magic Menu", isTitle = 1, });

    appendMenuItem("Set Control-Click Command","Set the command to run when you control-click a target", {
        func = LKTMM.SetDefaultCommand,
    })

    -- Context Sensitive Items
    if UnitIsUnit("player", "target") then
        if GetNumPartyMembers() > 0 then
            appendMenuCommand(".group summon")
        end
    elseif UnitIsPlayer("target") then
        appendMenuCommand(".appear")
        appendMenuCommand(".summon")
    else
        appendMenuCommand(".die")
    end

    if UnitIsPlayer("target") then
        appendMenuCommand(".recall")
        appendMenuCommand(".revive")
        appendMenuCommand(".repairitems")
    end

    -- Every Level Gets a Close
    for k,v in ipairs(menuTable) do
        if type(k) == "number" then
            appendMenuItem(CLOSE, "Close Menu", {
                func = function(self) CloseDropDownMenus() end,
            }, k)
        end
    end

    local info = menuTable[level]

    if menuList then
        if info[menuList] then
            info = info[menuList]
        else
            info = { }
        end
    end

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

    local LordKator_TrinityMagicMenu = CreateFrame("Frame", "LordKator_TrinityMagicMenu", _G[anchorName], "UIDropDownMenuTemplate") 

    UIDropDownMenu_Initialize(LordKator_TrinityMagicMenu, LKTMM.LordKator_TrinityMagicMenu_InitializeDropDown, "MENU")

    ToggleDropDownMenu(1, nil, LordKator_TrinityMagicMenu, anchorName, xOfs, yOfs)
end
