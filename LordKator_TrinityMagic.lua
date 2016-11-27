--[[
--
-- LordKator_TrinityMagic - Lord Kator's Trinity Core Magic
--
-- Author: Lord Kator <kator@karlbunch.com>
--
-- Created: Fri Nov 25 10:29:09 EST 2016
]]

SLASH_LORDKATOR_TRINITYMAGIC1 = "/magic"
SLASH_LORDKATOR_TRINITYMAGIC2 = "/lktm"

LKTM = {
    version = "0.0.1",
    debugLevel = 9,
    command = "should use " .. SLASH_LORDKATOR_TRINITYMAGIC2 .. ' setcmd first!',

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
		    LKTM:Message(0, "HELP:   " .. SLASH_LORDKATOR_TRINITYMAGIC2 .. " " .. cmd .. " " .. (LKTM.slashCommands[cmd].usage or ""))
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

                LKTM.command = cmd
	    end
	},

	["prompt"] = {
	    usage = "- set the command for a macro run",

	    cmd = function(args)
                StaticPopup_Show("LKTM_PromptCmd")
	    end
	},

	["do"] = {
	    usage = "- execute cmd",

	    cmd = function(args)
                if LKTM.command ~= nil and UnitExists(args) then
                    LKTM:Message(0, GetUnitName("target") .. ">> " .. LKTM.command)
                    SendChatMessage(LKTM.command, "whisper", nil, UnitName("player"))
                end
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

    print("Control-Clicked on " .. self:GetName() .. " with " .. button)

    if button == "LeftButton" then
        SendChatMessage(LKTM.command, "whisper", nil, UnitName("player"))
    end

    if button == "RightButton" then
        CloseDropDownMenus()
        LKTM:Message(0, "Show LKTM Menu for " .. unit)
        return
    end
end

function LKTM:SetupPostClicks()
    for i=1, MAX_PARTY_MEMBERS, 1 do
        local partyMemberFrame = _G["PartyMemberFrame"..i]

        if partyMemberFrame then
            partyMemberFrame:SetScript("PostClick", function(self, button) LKTM:UnitFramePostClick(self, "party"..i, button) end)
        end
    end
end

function LKTM:OnLoad(self)
  LKTM:Message(9, "OnLoad Start")

  if RegisterAddonMessagePrefix then
      RegisterAddonMessagePrefix("=LKTM=")
  end

  PlayerFrame:SetScript("PostClick", function(self, button) LKTM:UnitFramePostClick(self, "player", button) end)

  for event, func in pairs(LKTM.eventHandlers) do
      LKTM:Message(9, "Listening to " .. event)
      self:RegisterEvent(event)
  end

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
      getglobal(this:GetName().."EditBox"):SetText(LKTM.command)
    end,
    OnAccept = function()
      LKTM.command = getglobal(this:GetParent():GetName().."EditBox"):GetText()
      LKTM:Message(0, "New command [" .. LKTM.command .. "]")
    end
}
