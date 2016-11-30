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
        [".combatstop"] = {
            tooltipTitle = "Stop Combat",
            tooltipText = "Clear target from combat.",
        },
    }
}

function LKTMM:SetDefaultCommand()
    LKTM:PromptForCommand()
end

function LKTMM:LordKator_TrinityMagicMenu_InitializeDropDown(self, level)
    local menu = LKTMM_MenuBuilder:New()

    menu.addCommand = function (self, menuLevel, command)
        local tips = LKTMM.commandTips[command]

        if tips then
            return self:addItem(menuLevel, tips.tooltipTitle, tips.tooltipText, {
                func = function(frame) LKTM:CommandOnUnit("target", command) end,
            })
        else
            return self:addItem(menuLevel, command, "", {
                func = function(frame) LKTM:CommandOnUnit("target", command) end,
            })
        end
    end

    -- Build Menu
    menu:addTitle(1, "Trinity Core Magic Menu")
    menu:addFlyout(1, "Set Control-Click Command","Set the command to run when you control-click a target", "SetControlClickCommand")

    -- Context Sensitive Items
    if UnitIsUnit("player", "target") then
        if GetNumPartyMembers() > 0 then
            menu:addCommand(1, ".group summon")
        end

        if LKTM_Data_TaxiMenu ~= nil then
            menu:addFlyout(1, "Instant Taxi","Choose a location you'd like to teleport to.", "TaxiMenu")

            for menuValue, menuItem in pairs(LKTM_Data_TaxiMenu) do
                if string.match(menuValue, "^%d+$") ~= nil then
                    menu:addToMenu(2, menuItem, "TaxiMenu")
                else
                    for _, item in pairs(menuItem) do
                        if item.value == "TaxiMenuHistory" then
                            item.disabled = 1
                        end
                        item.func = function(self, arg1, arg2, checked) LKTM:GotoTaxiNode(self) end,
                        menu:addToMenu(3, item, menuValue)
                    end
                end
            end

            local taxiHistory = LKTM:GetTaxiHistory()

            if taxiHistory ~= nil then
                local sortByCount = function(a,b) return taxiHistory[b]['count'] < taxiHistory[a]['count'] end
                local historyItems = {}
                for _,v in LKTM:pairsByKeys(taxiHistory, sortByCount) do
                    table.insert(historyItems, {
                        text = v.text,
                        tooltipTitle = v.text,
                        tooltipText = ".go taxinode " .. v.id,
                        arg1 = v.id,
                        notCheckable = 1,
                        func = function(self, arg1, arg2, checked) LKTM:GotoTaxiNode(self) end,
                    })
                end

                if #historyItems > 0 then
                    table.insert(historyItems, 1, {
                        ["text"] = "Recent Destinations",
                        notCheckable = 1,
                        isTitle = 1
                    })

                    menu:addItems(3, historyItems, "TaxiMenuHistory")

                    for k,v in pairs(menu:getItems(2, "TaxiMenu")) do
                        if v.value == "TaxiMenuHistory" then
                            v.disabled = nil
                            break
                        end
                    end
                end
            end
        end
    elseif UnitIsPlayer("target") then
        menu:addCommand(1, ".appear"):addCommand(1, ".summon")
    else
        menu:addCommand(1, ".die")
    end

    if UnitIsPlayer("target") then
        menu:addCommand(1, ".recall"):addCommand(1, ".revive"):addCommand(1, ".repairitems"):addCommand(1, ".combatstop")
    end

    menu:addTitle(2, "Set Control-Click Command", "SetControlClickCommand")

    menu:addItem(2, "Prompt For Command","Prompt for command to use as control-click default.", {
        func = LKTMM.SetDefaultCommand,
    }, "SetControlClickCommand")

    for cmd, tips in pairs(LKTMM.commandTips) do
        menu:addItem(2, tips.tooltipTitle, tips.tooltipText, {
            func = function(frame)
                LKTM:SetDefaultCommand(cmd)
                CloseDropDownMenus()
            end
        }, "SetControlClickCommand")
    end

    local history = LKTM:GetCommandHistory()

    for cmd, count in pairs(history) do
        if LKTMM.commandTips[cmd] == nil then
            menu:addItem(2, cmd, "", {
                func = function(frame)
                    LKTM:SetDefaultCommand(cmd)
                    CloseDropDownMenus()
                end
            }, "SetControlClickCommand")
        end
    end

    menu:addItem(1, CLOSE, "Close Menu", { func = function(frame) CloseDropDownMenus() end })

    menu:build(level or 1)
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
