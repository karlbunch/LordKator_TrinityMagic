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
SLASH_LORDKATOR_TRINITYMAGIC_ONALL1 = "/onall"

BINDING_HEADER_LKTMHEADER = "Lord Kator's Trinity Magic"
BINDING_NAME_LKTMBINDING1 = "Open Chat with DOT"

local defaultCommandKey = 'ctrl-command1'

LKTM = {
    version = "0.0.1",
    debugLevel = 8,
    defaults = {
        [defaultCommandKey] = "should use " .. SLASH_LORDKATOR_TRINITYMAGIC1 .. ' [setcmd|prompt] first!',
        [defaultCommandKey .. '-history'] = {},
        taxiHistory = {},
        savedNPClist = {},
    },

    eventHandlers = {
        ["PLAYER_ENTERING_WORLD"] = function(self, event, arg1, arg2, arg3, arg4, arg5)
            LKTM:SetupPostClicks()
        end,

        ["PARTY_MEMBERS_CHANGED"] = function(self, event, arg1, arg2, arg3, arg4, arg5)
            LKTM:SetupPostClicks()
        end,
        ["VARIABLES_LOADED"] = function(self, event, ...)
            -- Hook Carbonite Map so Goto takes you directly to the location
            LKTM.carbonite_STAC = Nx.Map.STAC
            if LKTM.carbonite_STAC then
                Nx.Map.STAC = function(self)
                    local wx,wy=self:FPTWP(self.CFX,self.CFY)
                    local zx,zy=self:GZP(self.MaI,wx,wy)
                    local zoneId = LKTM_Data:findAreaId(self.COTF)
                    if zoneId then
                        pcall(function() NxMap1:Hide() end)
                        LKTM:CommandOnUnit("player", format(".go zonexy %.4f %.4f %s\n", zx, zy, zoneId))
                    else
                        LKTM:Message(0, "Sorry can't map [" .. self.COTF .. "] to a zoneId")
                    end
                end
                local menuText = "Goto"
                local ok, ret = pcall(function()
                    Nx.Map.Map1[1].Men.Ite1[1].Tex = "Teleport..." -- Change "Goto" -> "Teleport..."
                    table.remove(Nx.Map.Map1[1].Men.Ite1, 2) -- Delete "Clear Goto" entry
                end)
                if ok then
                    menuText = "Teleport..."
                end
                LKTM:Message(0, "Hooked Carbonite map menu, right click the map and select " .. menuText)
            end
        end
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
        local displayMsg, _ = msg:gsub("\n$","");
        (LKTM:GetActiveChatFrame()):AddMessage(string.format("%s =LKTM= %s", date("%H:%M:%S"), displayMsg), 1, 0, 1)
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

function LKTM:GetTaxiHistory()
    return LKTM:GetGlobalPreference("taxiHistory") or {}
end

function LKTM:GotoTaxiNode(nodeEntry)
    local taxiNodeId = nodeEntry.arg1

    LKTM:CommandOnUnit("player", ".go taxinode " .. taxiNodeId)

    local history = LKTM:GetTaxiHistory()

    if history[taxiNodeId] then
        history[taxiNodeId].count = history[taxiNodeId].count + 1
    else
        history[taxiNodeId] = {
            count = 1,
            id = nodeEntry.arg1,
            text = nodeEntry.toolTipTitle or nodeEntry.value,
        }
    end

    LKTM:SetGlobalPreference("taxiHistory", history)
end

function LKTM:CommandOnUnit(unit, command)
    local displayCmd, _ = command:gsub("\n$", "");

    LKTM:Message(0, "Run Command: [" .. displayCmd .. "] on " .. UnitName(unit))

    if unit ~= "target" and UnitIsPlayer(unit) then
        command = command .. " " .. UnitName(unit)
    end

    -- Whispering to ourselves allows us to send commands even when the player is dead
    SendChatMessage(command, "whisper", nil, UnitName("player"))
end

function LKTM:PromptForCommand()
    StaticPopup_Show("LKTM_PromptCmd")
end

function LKTM:IsGlobalPreferenceSet(key)
    if LordKator_TrinityMagic_Prefs_Global and LordKator_TrinityMagic_Prefs_Global[key] then
        return 1
    end

    return nil
end

function LKTM:GetGlobalPreference(key)
    if LordKator_TrinityMagic_Prefs_Global then
        return LordKator_TrinityMagic_Prefs_Global[key] or LKTM.defaults[key]
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

-- User waypoint functions
function LKTM:UserWaypointNew(note, specificKey)
    local wp = {}
    local mx, my = GetPlayerMapPosition("player")
    wp.key = "waypoint-" .. (specificKey or string.format("%X", 2^31*random()))
    wp.note = note
    wp.zone = {
        x = mx * 100.0,
        y = my * 100.0,
        zoneId = LKTM_Data:findAreaId(GetZoneText()),
    }
    LKTM:UserWaypointFormatName(wp)

    local wpList = LKTM:GetGlobalPreference("userWaypoints")

    wpList[wp.key] = wp

    LKTM_Query:getGPS("", wp, function(status, gps, wp) LKTM:UserWaypointSetWithGPS(wp, gps) end)

    return wp
end

function LKTM:UserWaypointFromHandle(wpHandle)
    local wpList = LKTM:UserWaypointGetList()
    local wpKey = type(wpHandle) == "string" and wpHandle or wpHandle.key
    local wp = wpList[wpKey]

    if wp == nil then
        wp = LKTM:UserWaypointNew()
        wpList[wpKey] = wp
    end

    return wp
end

function LKTM:UserWaypointDelete(wpHandle)
    local wp = LKTM:UserWaypointFromHandle(wpHandle)
    local wpList = LKTM:UserWaypointGetList()
    if wpList[wp.key] then
        wpList[wp.key] = nil
    end
end

function LKTM:UserWaypointGetList()
    local wpList = LKTM:GetGlobalPreference("userWaypoints")

    if wpList == nil then
        wpList = {}
        LKTM:SetGlobalPreference("userWaypoints", wpList)
    end

    return wpList
end

function LKTM:UserWaypointFormatName(wp)
    if wp.map then
        wp.name = string.format("%s <%s:%s:%s @ %.01f,%.01f>",
            wp.note or "",
            wp.map.name or "-",
            wp.map.zoneName or "-",
            wp.map.areaName or "-",
            wp.zone and wp.zone.x or wp.map.x or 0.0,
            wp.zone and wp.zone.y or wp.map.y or 0.0
        )
        -- TODO: wpToolTipText ? detailed description of location
    else
        local name = GetZoneText()

        if wp.zone.x == 0 and wp.zone.y == 0 then
            name = "<" .. name .. " - Instance>"
        else
            name = string.format("<%s @ %.01f,%.01f>", name, wp.zone.x, wp.zone.y)
        end

        wp.name = (wp.note or "") .. " " .. name
    end
end

function LKTM:UserWaypointSetWithGPS(wpHandle, gps)
    local wp = LKTM:UserWaypointFromHandle(wpHandle)
    wp.gpsResult = gps
    wp.map = {
        x = tonumber(gps.mapPosition.x),
        y = tonumber(gps.mapPosition.y),
        z = tonumber(gps.mapPosition.z),
        o = tonumber(gps.mapPosition.o),
        id = tonumber(gps.mapPosition.mapId),
        name = gps.mapPosition.mapName,
        zoneId = tonumber(gps.mapPosition.zoneId),
        zoneName = gps.mapPosition.zoneName,
        areaId = tonumber(gps.mapPosition.areaId),
        areaName = gps.mapPosition.areaName,
    }
    wp.zone = {
        x = tonumber(gps.gridPosition.zone.x),
        y = tonumber(gps.gridPosition.zone.y),
        zoneId = tonumber(gps.mapPosition.zoneId),
    }
    LKTM:UserWaypointFormatName(wp)
end

function LKTM:UserWaypointSetNote(wpHandle, note)
    local wp = LKTM:UserWaypointFromHandle(wpHandle)
    wp.note = note
    LKTM:UserWaypointFormatName(wp)
end

function LKTM:UserWaypointGoto(wp)
    local m = wp.map
    if m ~= nil then
        LKTM:CommandOnUnit("player", format(".go xyz %.4f %.4f %.4f %d %.4f\n", m.x, m.y, m.z, m.id, m.o))
    elseif wp.zone and wp.zone.zoneId then
        LKTM:CommandOnUnit("player", format(".go zonexy %.4f %.4f %d\n", wp.zone.x, wp.zone.y, wp.zone.zoneId))
    else
        LKTM:Message(0, "=ERROR=: Sorry this waypoint doesn't have enough data to teleport to it! - key: " .. wp.key)
    end
end

-- NPC functions

function LKTM:CopyNPC(frame, unitName)
    LKTM.copyNPCstate = {
        startTime = GetTime(),
        unitName = unitName or UnitName("target"),
        entryID = "unknown",
        dbGUID = "unknown",
        rawLines = {},
    }
    LKTM:CommandOnUnit("target", ".npc info")
end

function LKTM:FilterSystemChat (event, message)
    -- Look for output of .npc info
    -- LANG_NPCINFO_CHAR (ID 539)
    -- NPC currently selected by player:
    -- DB GUID: %u, current GUID: %u.
    -- Faction: %u.
    -- npcFlags: %u.
    -- Entry: %u.
    if not LKTM.copyNPCstate then
        return false
    end

    if GetTime() - LKTM.copyNPCstate.startTime > 5.0 then
        LKTM:Message(0, "=ERROR=: Timeout parsing NPC information request.")
        LKTM.copyNPCstate = nil
        return false
    end

    if string.sub(arg1, 1, 33) == "NPC currently selected by player:" then
        LKTM.copyNPCstate.rawLines = {}
    elseif string.sub(arg1, 1, 19) == "MechanicImmuneMask:" then
        local newList = LKTM:GetGlobalPreference("savedNPClist")

        newList[tostring(LKTM.copyNPCstate.entryID)] = {
            parseTime = tonumber(string.format("%.02f", GetTime() - LKTM.copyNPCstate.startTime)),
            lastUpdateDate = date(),
            lastUpdateTime = time(),
            unitName = LKTM.copyNPCstate.unitName,
            entryID = LKTM.copyNPCstate.entryID,
            dbGUID = LKTM.copyNPCstate.dbGUID,
            rawLines = LKTM.copyNPCstate.rawLines,
            zone = GetZoneText(),
            subZone = GetSubZoneText(),
            mapAreaId = GetCurrentMapAreaID(),
        }

        LKTM:SetGlobalPreference("savedNPClist", newList)
        LKTM:Message(0, "Saved NPC " .. LKTM.copyNPCstate.unitName)
        LKTM.copyNPCstate = nil
    else
        table.insert(LKTM.copyNPCstate.rawLines, arg1)

        local dbGUID = arg1:match("DB GUID: (%d+),")

        if dbGUID then
            LKTM.copyNPCstate.dbGUID = dbGUID
        else
            local entryID = arg1:match("Entry: (%d+)%.")

            if entryID then
                LKTM.copyNPCstate.entryID = entryID
            end
        end
    end

    return true
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

    LKTM_Data:OnLoad(self)

    LKTMM:Init(self)

    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", LKTM.FilterSystemChat)

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

function LKTM:pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0
    return function ()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
end

function LKTM:dumpObject(obj, save)
    if LKTM_Inspect ~= nil then
        local istr = LKTM_Inspect(obj)
        local num_lines = select(2, istr:gsub('\n', '\n'))

        if num_lines <= 55 then
            LordKator_TrinityMagicConfirm:message("LKTM:dumpObject: " .. istr .. "\n")
        else
            istr = istr .. "\n" .. num_lines .. " line(s) dumped"
            for ln in istr:gmatch("([^\r\n]*)[\r\n]") do
                (LKTM:GetActiveChatFrame()):AddMessage(ln, 1, 1, 1)
            end
        end
    else
        UIParentLoadAddOn("Blizzard_DebugTools");
        DevTools_Dump(msg);
    end
    if save then
        LKTM:SetGlobalPreference("lastDumpedObject", obj)
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

SlashCmdList["LORDKATOR_TRINITYMAGIC_ONALL"] = function(msg, editBox)
    local title, command = string.match(msg, '"(.-)"%s+(.*)')

    if not title then
        title = "Run:\n\n" .. msg .. "\n\nOn everyone in the party?"
        command = msg
    end

    local playerName = UnitName("player")
    local macroText = "/target player\n/whisper " .. playerName .. " " .. command .. "\n"
    if GetNumPartyMembers() > 0 then
        for i=1,GetNumPartyMembers(),1 do
            macroText = macroText .. "/target party" .. i .. "\n/whisper " .. playerName .. " " .. command .. "\n"
        end
    end

    macroText = macroText .. "/cleartarget\n"

    LordKator_TrinityMagicConfirm:confirmMacro(title, macroText)
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

        if LKTM:IsGlobalPreferenceSet(defaultCommandKey) then
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
