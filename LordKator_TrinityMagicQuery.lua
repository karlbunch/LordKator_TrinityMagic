--
-- LordKator_TrinityMagicQuery.lua - Simple Trinity Core Query Functions
--
LKTM_Query = { queue = {}, history = {} }

--
-- Query GPS via the .gps command
--
-- typical_result = {
--     ["doors"] = "outdoors",
--     ["mapPosition"] = {
--         ["zoneId"] = "3537",
--         ["zoneName"] = "Borean Tundra",
--         ["mapName"] = "Northrend",
--         ["areaId"] = "4129",
--         ["y"] = "6154.602051",
--         ["x"] = "2800.580811",
--         ["areaName"] = "Warsong Hold",
--         ["z"] = "84.723717",
--         ["mapId"] = "571",
--         ["o"] = "4.556426",
--         ["phase"] = "1",
--     },
--     ["gridPosition"] = {
--         ["zone"] = {
--             ["y"] = "54.564831",
--             ["x"] = "41.915104",
--         },
--         ["instanceId"] = "0",
--         ["cell"] = {
--             ["y"] = "4",
--             ["x"] = "2",
--         },
--         ["ground"] = {
--             ["map"] = "1",
--             ["z"] = "77.691803",
--             ["floorZ"] = "84.723236",
--             ["mmap"] = "1",
--             ["vmap"] = "1",
--         },
--         ["grid"] = {
--             ["y"] = "43",
--             ["x"] = "37",
--         },
--     },
-- }

function LKTM_Query:getGPS(args, data, callback)
    -- Look for output of .gps
    LKTM_Query:RunQuery({
        values = {},
        timeout = 5,
        callback = callback,
        data = data,
        command = ".gps " .. args .. "\n",
        patterns = {
            -- luacheck: ignore 432 shadowing upvalue argument self
            -- luacheck: ignore 212 unused variable length argument
            -- LANG_GPS_POSITION_OUTDOORS = 5042
            -- You are outdoors.
            -- LANG_GPS_POSITION_INDOORS = 5043
            -- You are indoors.
            ['You are (%S*doors).'] = function(self, ...)
                self.values.doors = select(1, ...)
                self.isStarted = 1
            end,
            -- LANG_GPS_NO_VMAP = 5044
            -- no VMAP available for area info
            ['no VMAP available for area info'] = function(self, ...)
                self.values.vmap = 0
            end,
            -- if tansport LANG_TRANSPORT_POSITION = 186
            -- TransMapID: %u TransOffsetX: %f TransOffsetY: %f TransOffsetZ: %f TransOffsetO: %f (Transport ID: %u %s)
            ['TransMapID: ([-]*%d+) TransOffsetX: ([-]*%d+%.?%d*) TransOffsetY: ([-]*%d+%.?%d*) TransOffsetZ: ([-]*%d+%.?%d*) TransOffsetO: (%d+%.?%d*) %(Transport ID: (%d+) (%.-)%)'] = function(self, ...)
                local v = {}
                v.MapID, v.OffsetX, v.OffsetY, v.OffsetZ, v.OffsetO, v.ID, v.Name = ...
                self.values.transport = v
            end,
            -- if liquid LANG_LIQUID_STATUS = 175
            -- Liquid level: %f, ground: %f, type: %u, flags %u, status: %d.
            ['Liquid level: ([-]*%d+%.?%d*), ground: ([-]*%d+%.?%d*), type: (%d+), flags (%d+), status: (%d+).'] = function(self, ...)
                local v = {}
                v.level, v.ground, v.type, v.flags, v.status = ...
                self.values.liquid = v
            end,
            -- LANG_MAP_POSITION = 101,
            -- Map: %u (%s) Zone: %u (%s) Area: %u (%s) Phase: %u
            -- X: %f Y: %f Z: %f Orientation: %f
            ['Map: (%d+) %(([^)]*)%) Zone: (%d+) %(([^)]*)%) Area: (%d+) %(([^)]*)%) Phase: (%d+)'] = function(self, ...)
                local v = {}
                v.mapId, v.mapName, v.zoneId, v.zoneName, v.areaId, v.areaName, v.phase = ...
                v.x, v.y, v.z, v.o = ...
                self.values.mapPosition = v
            end,
            ['X: ([-]*%d+%.?%d*) Y: ([-]*%d+%.?%d*) Z: ([-]*%d+%.?%d*) Orientation: (%d+%.?%d*)'] = function(self, ...)
                local v = self.values.mapPosition or { }
                v.x, v.y, v.z, v.o = ...
                self.values.mapPosition = v
            end,
            -- LANG_GRID_POSITION = 185
            -- grid[%u,%u]cell[%u,%u] InstanceID: %u
            --  ZoneX: %f ZoneY: %f
            -- GroundZ: %f FloorZ: %f Have height data (Map: %u VMap: %u MMap: %u)
            ['grid%[(%d+),(%d+)%]cell%[(%d+),(%d+)%] InstanceID: (%d+)'] = function(self, ...)
                local v = { grid = {}, cell = {}, zone = {}, ground = {} }
                v.grid.x, v.grid.y, v.cell.x, v.cell.y, v.instanceId = ...
                self.values.gridPosition = v
            end,
            [' ZoneX: (%d+%.?%d*) ZoneY: (%d+%.?%d*)'] = function(self, ...)
                local v = self.values.gridPosition or { zone = {} }
                v.zone.x, v.zone.y = ...
                self.values.gridPosition = v
            end,
            ['GroundZ: ([-]*%d+%.?%d*) FloorZ: ([-]*%d+%.?%d*) Have height data %(Map: (%d+) VMap: (%d+) MMap: (%d+)%)'] = function(self, ...)
                self.timeout = 30
                local v = self.values.gridPosition or { ground = {} }
                v.ground.z, v.ground.floorZ, v.ground.map, v.ground.vmap, v.ground.mmap = ...
                self.values.gridPosition = v
                self.isComplete = 1
            end,
        },
        onSuccess = function(self)
            self.callback("success", self.values, self.data)
        end,
        onTimeout = function(self)
            self.callBack("timeout", self.values, self.data)
        end,
    })
end

-- Run a query given this general structure:
-- timeout = 5,
-- command = ".gps " .. args,
-- patterns = { ['pattern'] = function(self, ...) end
-- onSuccess = function(self) end
function LKTM_Query:RunQuery(q)
    q.matchCount = {}
    q.rawLines = {}
    q.isStarted = 0
    q.isComplete = 0
    q.runTimeQueue = time()

    if q.suppressChat == nil then
        q.suppressChat = 1
    end

    table.insert(LKTM_Query.queue, q)

    if #LKTM_Query.queue == 1 then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", LKTM_Query.ParseSystemChat)
        LKTM:CommandOnUnit("player", q.command)
        -- luacheck: globals LordKator_TrinityMagic
        LordKator_TrinityMagic:HookScript("OnUpdate", LKTM_Query.OnUpdate)
    end

    return #LKTM_Query.queue
end

function LKTM_Query:GetCurrentQuery()
    if #LKTM_Query.queue < 1 or LKTM_Query.queue[1] == nil then
        LKTM_Query.queue = {}
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", LKTM_Query.ParseSystemChat)
        return nil
    end

    return LKTM_Query.queue[1]
end

function LKTM_Query:RemoveCurrentQuery()
    local q = table.remove(LKTM_Query.queue, 1)
    if LKTM_Query.history then
        q.runDate = date()
        q.runTimeStop = time()
        table.insert(LKTM_Query.history, q)
    end
end

function LKTM_Query:OnUpdate(elapsed)
    if not LKTM_Query.queue then
        return
    end

    local q = LKTM_Query.queue[1]

    if not q then
        return
    end

    if q.isTimedout then
        return
    end

    q.timeout = q.timeout - elapsed

    if q.timeout > 0 then
        return
    end

    q.isTimedout = 1

    if q.OnTimeout then
        q:OnTimeout()
    end

    LKTM_Query:RemoveCurrentQuery()
end

function LKTM_Query:ParseSystemChat(event, message) -- luacheck: no unused args
    local q = LKTM_Query:GetCurrentQuery()

    if not q then
        return
    end

    if not q.runTimeStart then
        q.runTimeStart = time()
    end

    table.insert(q.rawLines, message)

    local matched = false
    for pattern, handleMatch in pairs(q.patterns) do
        if not q.matchCount[pattern] then
            local m = { message:match(pattern) }
            if #m > 0 then
                matched = true
                handleMatch(q, unpack(m))
                q.matchCount[pattern] = (q.matchCount[pattern] or 0) + 1
                break
            end
        end
    end

    if not matched then
        if q.unmatchedLines == nil then
            q.unmatchedLines = {}
        end
        q.unmatchedLines[message] = (q.unmatchedLines[message] or 0) + 1
    end

    if q.isComplete > 0 then
        q.onSuccessReturned = q:onSuccess()
        LKTM_Query:RemoveCurrentQuery()
    end

    local suppressLine = (q.suppressChat and true) or false

    -- Cleanup queue as needed
    LKTM_Query:GetCurrentQuery()

    return suppressLine
end
