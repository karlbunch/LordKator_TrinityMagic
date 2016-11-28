--[[
--
-- LordKator_TrinityMagicMenu - Lord Kator's Trinity Core MagicMenu
--
-- Author: Lord Kator <kator@karlbunch.com>
--
-- Created: Sun Nov 27 19:40:38 EST 2016
]]

LKTMM = { }

function LKTMM:ShowPartyFrame()
	LordKator_TrinityMagic_ShowHidePartyFrame(true)
end

function LKTMM:ShowMeFrame()
	LordKator_TrinityMagic_ShowHideMeFrame(true)
end

function LKTMM:ShowPetsFrame()
	LordKator_TrinityMagic_ShowHidePetsFrame(true)
end

function LKTMM:ShowTanksFrame()
	LordKator_TrinityMagic_ShowHideTanksFrame(true)
end

function LKTMM:ShowFriendsFrame()
	LordKator_TrinityMagic_ShowHideFriendsFrame(true)
end


function LKTMM:SetButtonCount(info, arg1)
	if InCombatLockdown() then
		LordKator_TrinityMagic_Warn("Can't update button count while in combat!")
		return
	end
	
	LordKator_TrinityMagic_SetButtonCount(arg1)
end

function LKTMM:SetCurrentSpell(info, btnIndex, spellIndex)
	if InCombatLockdown() then
		LordKator_TrinityMagic_Warn("Can't configure buttons while in combat!")
		return
	end
	
	local Profile = LordKator_TrinityMagic_GetProfile()
	
	Profile.SpellNames[btnIndex] = LordKator_TrinityMagic_Spell.Name[spellIndex]
	Profile.SpellIcons[btnIndex] = LordKator_TrinityMagic_Spell.Icon[spellIndex]
	
	UIDropDownMenu_SetText(LordKator_TrinityMagicDropDown[btnIndex], Profile.SpellNames[btnIndex])	

	LordKator_TrinityMagic_UpdateButtonIcons()
	LordKator_TrinityMagic_UpdateButtonSpells()
end

function LKTMM:TargetCommand(command)
    -- TODO: include target in command string? (is it even needed)
    LKTM:Message(0, "Run Command: " .. command .. " on " .. UnitName("target"))
    SendChatMessage(command, "whisper", nil, UnitName("player"))
end

function LKTMM:GenericCommand(command)
    LKTM:Message(0, "Run Command: " .. command)
    SendChatMessage(command, "whisper", nil, UnitName("player"))
end

function LKTMM:LordKator_TrinityMagicMenu_InitializeDropDown(self, level, menuList)
    print("LordKator_TrinityMagicMenu_InitializeDropDown(" .. (self or "nil") .. ", " .. (level or "nil") .. ")")

    level = level or 1

    -- Base menu items everyone gets
    local menuTable = {
        [1] = {
            {
                text = "Trinity Core Magic Menu",
                isTitle = 1,
                notCheckable = 1,
            },
            {
                text = "Set Control-Click Command",
                func = LKTMM.SetDefaultCommand,
            },
        }
    }

    -- Context Sensitive Items
    local unitMenuItems = { }

    if UnitIsUnit("player", "target") then
        unitMenuItems = {
            {
                text = "Group Summon",
                func = function(self) LKTMM:TargetCommand(".group summon") end,
            },
            {
                text = "Return To Previous Location",
                func = function(self) LKTMM:TargetCommand(".recall") end,
            },
        }
    elseif UnitIsPlayer("target") then
        unitMenuItems = {
            {
                text = "Appear At Target",
                func = function(self) LKTMM:TargetCommand(".appear") end,
            },
            {
                text = "Summon To Me",
                func = function(self) LKTMM:TargetCommand(".summon") end,
            },
        }
    else
        unitMenuItems = {
            {
                text = "Die",
                func = function(self) LKTMM:TargetCommand(".die") end,
            },
        }
    end

    if UnitIsPlayer("target") then
        unitMenuItems[#unitMenuItems+1] = {
                text = "Revive",
                func = function(self) LKTMM:TargetCommand(".revive") end,
        }
        unitMenuItems[#unitMenuItems+1] = {
                text = "Repair Items",
                func = function(self) LKTMM:TargetCommand(".repairitems") end,
        }
    end

    for k,v in pairs(unitMenuItems) do
        menuTable[1][#menuTable[1]+1] = unitMenuItems[k]
    end

    -- Rest of the generic items everyone gets
    local genericMenuItems = {
    }

    for k,v in pairs(genericMenuItems) do
        menuTable[1][#menuTable[1]+1] = genericMenuItems[k]
    end

    -- Every Level Gets a Close
    for k,v in ipairs(menuTable) do
        menuTable[k][#menuTable[k]+1] = {
            text = CLOSE,
            func = function(self) CloseDropDownMenus() end
        }
    end

    local info = menuTable[level]

    if menuList then
        if info[menuList] then
            info = info[menuList]
        else
            info = { }
        end
    end

    for idx, entry in ipairs(info) do
        UIDropDownMenu_AddButton(entry, level)
    end
end

function LKTMM:Init(parent)
    print("LKTMM:Init() complete")
end

function LKTMM:Show(parent, unit)
    local LordKator_TrinityMagicMenu = CreateFrame("Frame", "LordKator_TrinityMagicMenu", UIParent, "UIDropDownMenuTemplate") 
    UIDropDownMenu_Initialize(LordKator_TrinityMagicMenu, LKTMM.LordKator_TrinityMagicMenu_InitializeDropDown, "MENU")

    local anchorName = "TargetFrame"

    if UnitIsUnit("player", "target") then
        anchorName = "PlayerFrame"
    end

    if string.sub(unit, 1, 5) == "party" then
        anchorName = "PartyMemberFrame" .. string.sub(unit, 6, -1)
    end

    print("LKTMM:Show(" .. unit .. ") anchorName=" .. anchorName)

    ToggleDropDownMenu(1, nil, LordKator_TrinityMagicMenu, anchorName, 106, 27)
end
