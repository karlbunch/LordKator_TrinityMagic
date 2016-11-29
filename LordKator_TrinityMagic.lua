--[[
--
-- LordKator_TrinityMagic - Lord Kator's Trinity Core Magic
--
-- Author: Lord Kator <kator@karlbunch.com>
--
-- Created: Fri Nov 25 10:29:09 EST 2016
]]

-- TODO:
--   Support ctrl, shift, alt click being different commands
--   Default commands by unit: player, party, target(not player/party), npc
--

SLASH_LORDKATOR_TRINITYMAGIC1 = "/lktm"
SLASH_LORDKATOR_TRINITYMAGIC2 = "/magic"

local defaultCommandKey = 'ctrl-command1'

LKTM = {
    version = "0.0.1",
    debugLevel = 9,
    defaults = {
        [defaultCommandKey] = "should use " .. SLASH_LORDKATOR_TRINITYMAGIC1 .. ' [setcmd|prompt] first!',
        [defaultCommandKey .. '-history'] = { },
    },

    eventHandlers = {
        ["PLAYER_ENTERING_WORLD"] = function(self, event, arg1, arg2, arg3, arg4, arg5)
            LKTM:SetupPostClicks()
        end,

        ["PARTY_MEMBERS_CHANGED"] = function(self, event, arg1, arg2, arg3, arg4, arg5)
            LKTM:SetupPostClicks()
        end,
    },

    slashCommands = {
        ["help"] = {
            usage = "- List available sub-commands to " .. SLASH_LORDKATOR_TRINITYMAGIC1 .. " or " .. SLASH_LORDKATOR_TRINITYMAGIC2 .. " chat commands",

            cmd = function(args)
                LKTM:Message(0, "HELP: Available " .. SLASH_LORDKATOR_TRINITYMAGIC1 .. " or " .. SLASH_LORDKATOR_TRINITYMAGIC2 .. " commands:")

                cmds = { }

                for cmd, v in pairs(LKTM.slashCommands) do
                    table.insert(cmds, cmd)
                end

                table.sort(cmds)

                for _, cmd in pairs(cmds) do
                    LKTM:Message(0, "HELP:   " .. SLASH_LORDKATOR_TRINITYMAGIC1 .. " " .. cmd .. " " .. (LKTM.slashCommands[cmd].usage or ""))
                end
            end
        },

        ["debug"] = {
            usage = "{level} - Set debug level from 0 (none) to 9 (most verbose)",

            cmd = function(args)
                LKTM:Message(0, string.format("CMD: [%s] ARGS: [%s]", "debug", args))

                if args == nil or args == "" then
                    LKTM.debugLevel = LKTM.debugLevel > 0 and 0 or 9
                else
                    LKTM:Message(0, "set to " .. args)
                    LKTM.debugLevel = tonumber(args)
                end
                LKTM:Message(0, string.format("debugLevel = %d", LKTM.debugLevel))
            end
        },

        ["version"] = {
            usage = "- Show currently running version",

            cmd = function(args) LKTM:Message(0, "Version " .. LKTM.version) end
        },

        ["setcmd"] = {
            usage = "- set the command for a macro run",

            cmd = function(args)
                if args == nil or args == "" then
                    LKTM:Message(0, "Please specify a command to run.")
                    return
                end

                local cmd = args

                if string.sub(cmd, 1, 1) ~= '.' then
                    cmd = '.' .. cmd
                end

                LKTM:SetDefaultCommand(cmd)
            end
        },

        ["prompt"] = {
            usage = "- set the command for a macro run",

            cmd = function(args)
                LKTM:PromptForCommand()
            end
        },

        ["do"] = {
            usage = "- execute cmd",

            cmd = function(args)
                LKTM:DefaultCommandOnUnit("target", nil)
            end
        },
    },
}

function LKTM:Message(level, msg, whisperTo, whisperMsg)
    if level > LKTM.debugLevel then
        return
    end

    if msg then
        (LKTM:GetActiveChatFrame()):AddMessage(string.format("%s =LKTM= %s", date("%H:%M:%S"), msg), 1, 0, 1)
    end

    if whisperTo and (whisperMsg or msg) then
        SendChatMessage("=LKTM=: " .. (whisperMsg or msg), "WHISPER", GetDefaultLanguage("player"), whisperTo)
    end
end

function LKTM:GetActiveChatFrame()
    for i = 1,NUM_CHAT_WINDOWS do
        local name = "ChatFrame"..i
        if _G[name]:IsShown() then
            return _G[name]
        end
    end
    return DEFAULT_CHAT_FRAME
end

function LKTM:UnitFramePostClick(self, unit, button)
    if not IsControlKeyDown() then
        return
    end

    if button == "LeftButton" then
        LKTM:DefaultCommandOnUnit("target", button)
        return
    end

    if button == "RightButton" then
        CloseDropDownMenus()
        LKTM:Message(9, "Show LKTM Menu for " .. unit)
        LKTMM:Show(self, unit)
        return
    end
end

function LKTM:SetupPostClicks()
    PlayerFrame:SetScript("PostClick", function(self, button) LKTM:UnitFramePostClick(self, "player", button) end)
    PlayerFrame:SetAttribute("ctrl-type2", "target");

    TargetFrame:SetScript("PostClick", function(self, button) LKTM:UnitFramePostClick(self, "target", button) end)
    TargetFrame:SetAttribute("ctrl-type2", "target");

    for i=1, MAX_PARTY_MEMBERS, 1 do
        local partyMemberFrame = _G["PartyMemberFrame"..i]

        if partyMemberFrame then
            partyMemberFrame:SetScript("PostClick", function(self, button) LKTM:UnitFramePostClick(self, "party"..i, button) end)
            partyMemberFrame:SetAttribute("ctrl-type2", "target");
        end
    end
end

function LKTM:SetDefaultCommand(newCommand)
    LKTM:SetGlobalPreference(defaultCommandKey, newCommand)

    if newCommand ~= LKTM.defaults[defaultCommandKey] then
        local history = LKTM:GetGlobalPreference(defaultCommandKey .. '-history') or {}
        if history[newCommand] then
            history[newCommand] = history[newCommand] + 1
        else
            history[newCommand] = 1
        end
        LKTM:SetGlobalPreference(defaultCommandKey .. '-history', history)
    end
end

function LKTM:DefaultCommandOnUnit(unit, button)
    LKTM:CommandOnUnit(unit, LKTM:GetGlobalPreference(defaultCommandKey))
end

function LKTM:GetCommandHistory()
    return LKTM:GetGlobalPreference(defaultCommandKey .. '-history') or {}
end

function LKTM:CommandOnUnit(unit, command)
    LKTM:Message(0, "Run Command: [" .. command .. "] on " .. UnitName(unit))

    if unit ~= "target" and UnitIsPlayer(unit) then
        command = command .. " " .. UnitName(unit)
    end

    -- Whispering to ourselves allows us to send commands even when the player is dead
    SendChatMessage(command, "whisper", nil, UnitName("player"))
end

function LKTM:PromptForCommand()
    StaticPopup_Show("LKTM_PromptCmd")
end

function LKTM:GlobalPreferenceSet(key)
    if LordKator_TrinityMagic_Prefs_Global and LordKator_TrinityMagic_Prefs_Global[key] then
        return 1
    end

    return nil
end

function LKTM:GetGlobalPreference(key)
    if LordKator_TrinityMagic_Prefs_Global then
        return LordKator_TrinityMagic_Prefs_Global[key]
    else
        return LKTM.defaults[key]
    end
end

function LKTM:SetGlobalPreference(key, value)
    local oldValue = LKTM:GetGlobalPreference(key)

    if LordKator_TrinityMagic_Prefs_Global == nil then
        LordKator_TrinityMagic_Prefs_Global = { _preferencesVersion = 1 }
    end

    LordKator_TrinityMagic_Prefs_Global[key] = value

    return value, oldValue
end

function LKTM:OnLoad(self)
    LKTM:Message(9, "OnLoad Start")

    if RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("=LKTM=")
    end

    for event, func in pairs(LKTM.eventHandlers) do
        LKTM:Message(9, "Listening to " .. event)
        self:RegisterEvent(event)
    end

    LKTM:SetupPostClicks()

    LKTMM:Init(self)

    LKTM:Message(9, "OnLoad Complete")
end

function LKTM:OnEvent(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5 = ...

    LKTM:Message(10, "OnEvent: " .. (event or "nil") .. "(" .. (arg1 or "nil") .. ", " .. (arg2 or "nil") .. ", " .. (arg3 or "nil") .. ", " .. (arg4 or "nil") .. ", " .. (arg5 or "nil") .. ")")

    local handler = LKTM.eventHandlers[event]

    if handler ~= nil then
        (handler)(self, event, arg1, arg2, arg3, arg4, arg5)
    else
        LKTM:Message(0, "Unexpected Event: " .. event .. "(" .. (arg1 or "nil") .. ", " .. (arg2 or "nil") .. ", " .. (arg3 or "nil") .. ", " .. (arg4 or "nil") .. ", " .. (arg5 or "nil") .. ")")
    end
end

SlashCmdList["LORDKATOR_TRINITYMAGIC"] = function(msg, editBox)
    local cmd, args = msg:match("^(%S+)%s*(.*)$")

    cmd = string.lower(cmd or "help")

    cmdEntry = LKTM.slashCommands[cmd]

    if cmdEntry ~= nil then
        cmdEntry.cmd(args)
    else
        LKTM:Message(0, "Unknown command [" .. cmd .. "]")
        LKTM.slashCommands['help'].cmd(args)
    end
end

StaticPopupDialogs["LKTM_PromptCmd"] = {
    text = "What command would you like to use?",
    button1 = "Set",
    button2 = "Cancel",
    hasEditBox = 1,
    whileDead = 1,
    hideOnEscape = 1,
    timeout = 0,
    OnShow = function()
        local curCmd = ""

        if LKTM:GlobalPreferenceSet(defaultCommandKey) then
            curCmd = LKTM:GetGlobalPreference(defaultCommandKey)
        end
        getglobal(this:GetName().."EditBox"):SetText(curCmd)
    end,
    OnAccept = function()
        local newCommand = getglobal(this:GetParent():GetName().."EditBox"):GetText()
        LKTM:Message(0, "New command [" .. newCommand .. "]")
        LKTM:SetDefaultCommand(newCommand)
    end
}
