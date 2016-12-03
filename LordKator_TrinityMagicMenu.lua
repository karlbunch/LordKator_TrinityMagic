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
        [".tele name $home"] = {
            tooltipTitle = "Instant Hearth",
            tooltipText = "Return target to their hearth.",
        }
    },
}

function LKTMM:SetDefaultCommand()
    LKTM:PromptForCommand()
end

function LKTMM:BuildTaxiMenu(menu)
    if LKTM_Data_TaxiMenu == nil then
        return
    end

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

function LKTMM:QuestTool(frame, arg1, arg2, checked)
    local cmd, unit, title, questLogIndex = strsplit("|", arg1)
    local command = ".quest " .. cmd .. " " .. arg2

    if unit == "party" then
        local playerName = UnitName("player")
        local macroText = ""

        if cmd ~= "Add" or not IsUnitOnQuest(questLogIndex, "player") then
            macroText = macroText .. "/target player" .. "\n/whisper " .. playerName .. " " .. command .. "\n"
        end

        if GetNumPartyMembers() > 0 then
            for i=1,GetNumPartyMembers(),1 do
                if cmd ~= "Add" or not IsUnitOnQuest(questLogIndex, "party" .. i) then
                    macroText = macroText .. "/target party" .. i .. "\n/whisper " .. playerName .. " " .. command .. "\n"
                end
            end
        end

        macroText = macroText .. "/cleartarget\n"

        LordKator_TrinityMagicConfirm:confirmMacro(
            cmd .. " quest:\n\n" .. title .. "\n\nFor everyone in the party?",
            macroText,
            function() LKTM:Message(0, "Ran macro [" .. macroText .. "]") end
        )
        return
    end

    LKTM:CommandOnUnit(unit, command)
end

function LKTMM:BuildQuestMenu(menu)
    local menuValue = "QuestMenuSelection"

    menu:addFlyout(1, "Quest Log Tools", "Tools for working with quests", menuValue)

    menu:addTitle(2, "Quests", menuValue)

    local logItems = {}
    local sectionTitle = nil
    local i=0
    while 1 do
        i = i + 1
        local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID = GetQuestLogTitle(i);

        if questTitle == nil then
            break
        end
        if isHeader then
            sectionTitle = questTitle
        else
            if sectionTitle then
                menu:addTitle(2, sectionTitle, menuValue)
                sectionTitle = nil
            end

            local questMenuValue = "QuestMenu" .. questID

            menu:addFlyout(2, questTitle .. (questTag and (" |cffffff00" .. questTag .."|r") or "") .. (isComplete and " (|cff00ff00complete|r)" or ""), "", questMenuValue, menuValue)
                :getLastItem().arg1 = questID

            menu:addTitle(3, questTitle, questMenuValue)
                :addItem(3, "Complete quest", "Complete this quest for " .. UnitName("target") .. ".", {
                    arg1 = "Complete|target|" .. questTitle .. "|" .. i,
                    arg2 = questID,
                    func = function(self, arg1, arg2, checked) LKTMM:QuestTool(self, arg1, arg2, checked) end,
                }, questMenuValue)
                :addItem(3, "Remove quest", "Remove this quest from" .. UnitName("target") .. ".", {
                    arg1 = "Remove|target|" .. questTitle .. "|" .. i,
                    arg2 = questID,
                    func = function(self, arg1, arg2, checked) LKTMM:QuestTool(self, arg1, arg2, checked) end,
                }, questMenuValue)

            if GetNumPartyMembers() > 0 then
                menu:addTitle(3, "Party", questMenuValue)
                :addItem(3, "Add to party", "Add this quest to everyone in the party.", {
                    arg1 = "Add|party|" .. questTitle .. "|" .. i,
                    arg2 = questID,
                    func = function(self, arg1, arg2, checked) LKTMM:QuestTool(self, arg1, arg2, checked) end,
                }, questMenuValue)
                :addItem(3, "Complete for party", "Complete this quest for everyone.", {
                    arg1 = "Complete|party|" .. questTitle .. "|" .. i,
                    arg2 = questID,
                    func = function(self, arg1, arg2, checked) LKTMM:QuestTool(self, arg1, arg2, checked) end,
                }, questMenuValue)
                :addItem(3, "Remove from party", "Remove this quest from everyone.", {
                    arg1 = "Remove|party|" .. questTitle .. "|" .. i,
                    arg2 = questID,
                    func = function(self, arg1, arg2, checked) LKTMM:QuestTool(self, arg1, arg2, checked) end,
                }, questMenuValue)
            end
        end
    end
end

function LKTMM:InitializeDropDown(self, level)
    local menu = LKTMM_MenuBuilder:New()

    menu.addCommand = function (self, menuLevel, command, tipsHint)
        local tips = LKTMM.commandTips[tipsHint] or LKTMM.commandTips[command] or tipsHint

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
        LKTMM:BuildTaxiMenu(menu)
        LKTMM:BuildQuestMenu(menu)
        if GetNumPartyMembers() > 0 then
            menu:addCommand(1, ".group summon")
        end
        menu:addCommand(1, ".tele name $home")
    elseif UnitIsPlayer("target") then
        menu:addCommand(1, ".appear"):addCommand(1, ".summon")
            :addCommand(1, ".tele name " .. UnitName("target") .. " $home", ".tele name $home")
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

    if LKTM.debugLevel >= 9 then
        LKTM:SetGlobalPreference("lastMenu", menu:getItems())
    end

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

    UIDropDownMenu_Initialize(LordKator_TrinityMagicMenuDropDown, function(frame, level, menuList) LKTMM:InitializeDropDown(frame, level, menuList) end, "MENU")
    ToggleDropDownMenu(1, nil, LordKator_TrinityMagicMenuDropDown, anchorName, xOfs, yOfs)
end
