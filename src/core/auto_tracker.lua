-- Auto-Tracking System for Objectives
-- Declarative detection engine that automatically detects objective completion
-- without requiring manual configuration per objective

-- Frame counter for debug output throttling (module-level)
local auto_tracker_debug_frame_counter = 0

---@class AutoTracker
---@field tracked_objectives table<string, {completed: boolean, state: table}>
---@field event_history table<string, number> Event name -> timestamp of last occurrence
---@field kill_history table Kill tracking
local AutoTracker = {}
AutoTracker.__index = AutoTracker

---Create new auto-tracker instance
---@return AutoTracker
function AutoTracker.new()
    local self = setmetatable({}, AutoTracker)
    
    self.tracked_objectives = {}
    self.event_history = {}
    self.kill_history = {
        recent_kills = {},
        total_kills = 0,
        kills_by_type = {},
        player_deaths = 0
    }
    self.player_state = {
        current_biome = nil,
        last_position = {x = 0, y = 0},
        polymorphed = false,
        polymorphed_start_time = nil
    }
    
    return self
end

-- ============================================================================
-- GAME STATE QUERY FUNCTIONS
-- ============================================================================

---Get player entity
---@return integer|nil
local function getPlayerEntity()
    local players = EntityGetWithTag("player_unit")
    if players and #players > 0 then
        return players[1]
    end
    return nil
end

---Get player position
---@return number, number
local function getPlayerPosition()
    local player = getPlayerEntity()
    if player then
        local x, y = EntityGetTransform(player)
        return x, y
    end
    return 0, 0
end

---Get current biome name player is in
---@return string|nil
local function getCurrentBiome()
    local x, y = getPlayerPosition()
    
    -- Check biome at player position
    local biome_checks = {
        {name = "caverns", check = function() return y > 4000 and y < 12000 end},
        {name = "hell", check = function() return y > 12000 end},
        {name = "snowy_depths", check = function() return y > 8000 and y < 12000 and x > 10000 end},
        {name = "hiisi_base", check = function() return y > 10000 and y < 12000 and x > -5000 and x < 5000 end},
        {name = "holy_mountain", check = function() return y > 0 and y < 2000 end}
    }
    
    for _, biome in ipairs(biome_checks) do
        if biome.check() then
            return biome.name
        end
    end
    
    return "surface"
end

---Check if player has a specific perk
---@param perk_id string
---@return boolean
local function hasPlayerPerk(perk_id)
    -- In Noita, perks are tracked via run flags
    -- The perk flag format is "perk_<perk_id>"
    return GameHasFlagRun("perk_" .. perk_id)
end

---Get player's current wands
---@return table
local function getPlayerWands()
    local player = getPlayerEntity()
    if not player then return {} end
    
    local wands = {}
    local inventory = GameGetAllInventoryItems(player)
    
    if inventory then
        for _, item_id in ipairs(inventory) do
            local filename = EntityGetFilename(item_id)
            if filename and string.match(filename, "wand") then
                table.insert(wands, item_id)
            end
        end
    end
    
    return wands
end

---Analyze a wand's properties
---@param wand_entity integer
---@return table {capacity: number, fire_rate_wait: number, reload_time: number, cast_delay: number}
local function analyzeWand(wand_entity)
    local wand_comp = EntityGetFirstComponent(wand_entity, "ItemComponent")
    if not wand_comp then
        return {capacity = 0, fire_rate_wait = 0, reload_time = 0, cast_delay = 0}
    end
    
    local capacity = ComponentGetValue2(wand_comp, "mana_max") or 100
    local fire_rate_wait = ComponentGetValue2(wand_comp, "fire_rate_wait") or 0.5
    local reload_time = ComponentGetValue2(wand_comp, "reload_time") or 1.0
    local cast_delay = ComponentGetValue2(wand_comp, "cast_delay_frames") or 0
    
    return {
        capacity = capacity,
        fire_rate_wait = fire_rate_wait,
        reload_time = reload_time,
        cast_delay = cast_delay
    }
end

---Count items in player inventory matching criteria
---@param item_name string|nil Match item name contains this string
---@param exclude_liquids boolean If true, don't count potions/liquids
---@return integer
local function countInventoryItems(item_name, exclude_liquids)
    local player = getPlayerEntity()
    if not player then return 0 end
    
    local count = 0
    local inventory = GameGetAllInventoryItems(player)
    
    if inventory then
        for _, item_id in ipairs(inventory) do
            local filename = EntityGetFilename(item_id)
            
            if exclude_liquids then
                if not string.match(filename or "", "potion") then
                    if not item_name or string.match(filename or "", item_name) then
                        count = count + 1
                    end
                end
            else
                if not item_name or string.match(filename or "", item_name) then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

---Get player's current gold
---@return integer
local function getPlayerGold()
    local player = getPlayerEntity()
    if not player then return 0 end
    
    local gold_comp = EntityGetFirstComponent(player, "MoneyComponent")
    if gold_comp then
        return ComponentGetValue2(gold_comp, "money") or 0
    end
    
    return 0
end

---Get number of recent kills with a specific condition
---@param kill_condition string "explosion" | "kick" | "tablet" | nil for any
---@return integer
local function getRecentKillsWithCondition(tracker, kill_condition)
    -- This would need to hook into death events
    -- For now, return tracked count
    if not kill_condition then
        return tracker.kill_history.total_kills
    end
    
    return tracker.kill_history.kills_by_type[kill_condition] or 0
end

---Get player death count
---@return integer
local function getPlayerDeaths(tracker)
    return tracker.kill_history.player_deaths
end

---Get game time in seconds
---@return number
local function getGameTime()
    return GameGetFrameNum() / 60  -- Convert frames to approximate seconds
end

---Check if player is currently polymorphed
---@return boolean
local function isPlayerPolymorphed()
    local player = getPlayerEntity()
    if not player then return false end
    
    -- Check for polymorph component or effect
    local is_polymorphed = false
    
    -- Query game state for polymorph effect
    local comps = EntityGetAllComponents(player)
    for _, comp_id in ipairs(comps) do
        local comp_type = ComponentGetTypeName(comp_id)
        if comp_type == "PolymorphComponent" then
            is_polymorphed = true
            break
        end
    end
    
    return is_polymorphed
end

-- ============================================================================
-- CONDITION EVALUATION ENGINE
-- ============================================================================

---Evaluate a single condition
---@param value number|string Value to check
---@param operator string "<" | "<=" | ">" | ">=" | "==" | "!=" | "contains"
---@param threshold number|string Threshold to compare against
---@return boolean
local function evaluateCondition(value, operator, threshold)
    if operator == "<" then
        return tonumber(value) or 0 < tonumber(threshold) or 0
    elseif operator == "<=" then
        return tonumber(value) or 0 <= tonumber(threshold) or 0
    elseif operator == ">" then
        return tonumber(value) or 0 > tonumber(threshold) or 0
    elseif operator == ">=" then
        return tonumber(value) or 0 >= tonumber(threshold) or 0
    elseif operator == "==" then
        return tostring(value) == tostring(threshold)
    elseif operator == "!=" then
        return tostring(value) ~= tostring(threshold)
    elseif operator == "contains" then
        return string.find(tostring(value), tostring(threshold)) ~= nil
    end
    return false
end

---Evaluate all conditions in a list
---@param conditions table[] Array of {property: string, operator: string, value: any}
---@param require_all boolean If true, all must pass; if false, any can pass
---@return boolean
local function evaluateConditions(conditions, require_all)
    if not conditions or #conditions == 0 then
        return true
    end
    
    require_all = require_all ~= false -- Default true
    
    for _, condition in ipairs(conditions) do
        local passes = evaluateCondition(condition.value, condition.operator, condition.threshold)
        
        if require_all and not passes then
            return false
        elseif not require_all and passes then
            return true
        end
    end
    
    return require_all -- If require_all, all passed; if not, none passed
end

-- ============================================================================
-- DETECTOR HANDLERS (Declarative detection logic)
-- ============================================================================

local DETECTOR_HANDLERS = {}

---Detect: Player reached a specific biome
---@param tracker AutoTracker
---@param obj Objective
---@param config table {biome_name: string}
---@return boolean
function DETECTOR_HANDLERS.biome_reach(tracker, obj, config)
    local current = getCurrentBiome()
    
    -- Check if currently in biome OR if event was recorded
    if current == config.biome_name then
        return true
    end
    
    -- Also check event history for recorded biome reach
    local event_name = "biome_reached_" .. config.biome_name
    return (tracker.event_history[event_name] or 0) > 0
end

---Detect: Player has a specific perk
---@param tracker AutoTracker
---@param obj Objective
---@param config table {perk_id: string}
---@return boolean
function DETECTOR_HANDLERS.perk_obtain(tracker, obj, config)
    return hasPlayerPerk(config.perk_id)
end

---Detect: Player gold >= threshold
---@param tracker AutoTracker
---@param obj Objective
---@param config table {min_gold: number}
---@return boolean
function DETECTOR_HANDLERS.gold_collect(tracker, obj, config)
    return getPlayerGold() >= (config.min_gold or 0)
end

---Detect: Wand meets specific conditions
---@param tracker AutoTracker
---@param obj Objective
---@param config table {conditions: table[], require_all: boolean}
---@return boolean
function DETECTOR_HANDLERS.wand_analysis(tracker, obj, config)
    local wands = getPlayerWands()
    
    if #wands == 0 then
        return false
    end
    
    for _, wand in ipairs(wands) do
        local wand_props = analyzeWand(wand)
        
        -- Check each condition against wand properties
        local all_pass = true
        for _, condition in ipairs(config.conditions or {}) do
            local wand_value = wand_props[condition.property]
            local passes = evaluateCondition(wand_value, condition.operator, condition.value)
            
            if config.require_all ~= false and not passes then
                all_pass = false
                break
            elseif config.require_all == false and passes then
                return true -- Any wand matches
            end
        end
        
        if all_pass then
            return true
        end
    end
    
    return false
end

---Detect: Inventory item count
---@param tracker AutoTracker
---@param obj Objective
---@param config table {item_name: string, min_count: number, exclude_liquids: boolean}
---@return boolean
function DETECTOR_HANDLERS.inventory_count(tracker, obj, config)
    local count = countInventoryItems(config.item_name, config.exclude_liquids)
    return count >= (config.min_count or 0)
end

---Detect: Kill enemies with condition
---@param tracker AutoTracker
---@param obj Objective
---@param config table {condition: string, min_kills: number}
---@return boolean
function DETECTOR_HANDLERS.kill_with_condition(tracker, obj, config)
    local kills = getRecentKillsWithCondition(tracker, config.condition)
    return kills >= (config.min_kills or 1)
end

---Detect: Player deaths
---@param tracker AutoTracker
---@param obj Objective
---@param config table {min_deaths: number}
---@return boolean
function DETECTOR_HANDLERS.death_count(tracker, obj, config)
    return getPlayerDeaths(tracker) >= (config.min_deaths or 1)
end

---Detect: Survived X seconds
---@param tracker AutoTracker
---@param obj Objective
---@param config table {min_time: number}
---@return boolean
function DETECTOR_HANDLERS.time_survive(tracker, obj, config)
    return getGameTime() >= (config.min_time or 0)
end

---Detect: Event was triggered
---@param tracker AutoTracker
---@param obj Objective
---@param config table {event_name: string}
---@return boolean
function DETECTOR_HANDLERS.event_triggered(tracker, obj, config)
    return (tracker.event_history[config.event_name] or 0) > 0
end

---Detect: Multiple objectives with AND/OR logic
---@param tracker AutoTracker
---@param obj Objective
---@param config table {objectives: table[], logic: "and"|"or"}
---@return boolean
function DETECTOR_HANDLERS.composite(tracker, obj, config)
    local logic = config.logic or "and"
    local results = {}
    
    for _, sub_config in ipairs(config.objectives or {}) do
        local detector = DETECTOR_HANDLERS[sub_config.type]
        if detector then
            table.insert(results, detector(tracker, obj, sub_config))
        end
    end
    
    if logic == "and" then
        for _, result in ipairs(results) do
            if not result then return false end
        end
        return true
    else -- or
        for _, result in ipairs(results) do
            if result then return true end
        end
        return false
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

---Register an event occurrence (called by game state tracking)
---@param event_name string
function AutoTracker:recordEvent(event_name)
    self.event_history[event_name] = GameGetFrameNum()
    print(string.format("AutoTracker: Event recorded - %s", event_name))
end

---Record a kill
---@param kill_type string "explosion" | "kick" | "tablet" | etc
function AutoTracker:recordKill(kill_type)
    self.kill_history.total_kills = self.kill_history.total_kills + 1
    
    if kill_type then
        self.kill_history.kills_by_type[kill_type] = (self.kill_history.kills_by_type[kill_type] or 0) + 1
    end
end

---Record a player death
function AutoTracker:recordDeath()
    self.kill_history.player_deaths = self.kill_history.player_deaths + 1
end

---Check if an objective is completed based on auto_track config
---@param objective Objective
---@return boolean
function AutoTracker:checkObjective(objective)
    if not objective then
        print("DEBUG: checkObjective called with nil objective")
        return false
    end
    
    if not objective.auto_track then
        return false
    end
    
    local auto_track = objective.auto_track
    
    -- Debug: log all checks for kill_with_condition type
    if auto_track.type == "kill_with_condition" then
        local kills = getRecentKillsWithCondition(self, auto_track.condition)
        if auto_tracker_debug_frame_counter % 600 == 0 then
            print(string.format("DEBUG checkObj kill_with_condition: %s | kills=%d min=%d",
                objective.id, kills, auto_track.min_kills or 1))
        end
    end
    
    -- Debug: log all event_triggered checks
    if auto_track.type == "event_triggered" then
        local event_name = auto_track.event_name
        local event_recorded = (self.event_history[event_name] or 0) > 0
        if auto_tracker_debug_frame_counter % 600 == 0 then
            print(string.format("DEBUG checkObj event_triggered: %s | event=%s | recorded=%s",
                objective.id, event_name, tostring(event_recorded)))
        end
    end
    
    -- Special handling for biome_reach to check event history
    if auto_track.type == "biome_reach" then
        local current = getCurrentBiome()
        if current == auto_track.biome_name then
            return true
        end
        local event_name = "biome_reached_" .. auto_track.biome_name
        return (self.event_history[event_name] or 0) > 0
    end
    
    local detector = DETECTOR_HANDLERS[auto_track.type]
    
    if not detector then
        print(string.format("WARNING: Unknown auto_track type '%s' for objective %s", 
            auto_track.type, objective.id))
        return false
    end
    
    -- Pass self as first argument so detectors can access tracker instance
    local result = detector(self, objective, auto_track)
    
    if auto_track.type == "event_triggered" and result then
        print(string.format("*** EVENT DETECTED AND MATCHED: %s", objective.id))
    end
    
    return result
end

---Update auto-tracker each frame
---@param dt number Delta time
function AutoTracker:update(dt)
    -- Update player state
    self.player_state.current_biome = getCurrentBiome()
    
    local x, y = getPlayerPosition()
    self.player_state.last_position = {x = x, y = y}
    self.player_state.polymorphed = isPlayerPolymorphed()
end

---Check all objectives on a board and auto-clear completed ones
---@param board BingoBoard
---@param objectives_list table Array of Objective
---@return table cleared_positions Array of {row, col} that were auto-cleared
function AutoTracker:autoCheckBoard(board, objectives_list)
    auto_tracker_debug_frame_counter = auto_tracker_debug_frame_counter + 1
    local cleared_positions = {}
    
    if not board or not objectives_list then
        if auto_tracker_debug_frame_counter % 600 == 0 then
            print("DEBUG: autoCheckBoard - board or objectives_list is nil")
        end
        return cleared_positions
    end
    
    if auto_tracker_debug_frame_counter % 600 == 0 then
        print(string.format("DEBUG: autoCheckBoard checking %d objectives against %dx%d board", #objectives_list, board.size, board.size))
    end
    
    for i, objective in ipairs(objectives_list) do
        -- Calculate row/col from index
        local row = math.floor((i - 1) / board.size) + 1
        local col = ((i - 1) % board.size) + 1
        
        -- Skip if already cleared
        if board:isCleared(row, col) then
            -- print(string.format("DEBUG: Square (%d,%d) already cleared", row, col))
            goto continue
        end
        
        -- Check if objective is completed
        local result = self:checkObjective(objective)
        if auto_tracker_debug_frame_counter % 600 == 0 and i <= 3 then
            print(string.format("DEBUG: Checked objective %s (type=%s): result=%s", 
                objective.id, objective.auto_track and objective.auto_track.type or "none", tostring(result)))
        end
        
        if result then
            board:setClearedAt(row, col, true)
            table.insert(cleared_positions, {row = row, col = col})
            print(string.format("AutoTracker: Auto-cleared %s (%d,%d)", objective.id or "unknown", row, col))
        end
        
        ::continue::
    end
    
    return cleared_positions
end

BingoCore.AutoTracker = AutoTracker

