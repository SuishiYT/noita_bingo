-- Noita Event Hooks
-- Connects game events to auto-tracker recording system
-- Monitors entity deaths, player deaths, biome changes, and special events

-- ============================================================================
-- DAMAGE TRACKING
-- ============================================================================

-- Tracks damage sources to categorize kills
local LAST_DAMAGE_SOURCE = {}
local LAST_DAMAGE_TYPE = {}
local DEATH_CAUSE_CACHE = {}

---Log damage event with source tracking
---@param damaged_entity int Entity being damaged
---@param damage_source string Type of damage (weapon, material, etc.)
---@param damage_type string Category of damage
function trackDamageEvent(damaged_entity, damage_source, damage_type)
    LAST_DAMAGE_SOURCE[damaged_entity] = damage_source
    LAST_DAMAGE_TYPE[damaged_entity] = damage_type
end

---Get the last damage info for an entity
---@param entity int
---@return string, string damage_source, damage_type
function getDamageInfo(entity)
    return LAST_DAMAGE_SOURCE[entity] or "unknown", LAST_DAMAGE_TYPE[entity] or "unknown"
end

-- ============================================================================
-- ENTITY DEATH TRACKING
-- ============================================================================

local TRACKED_ENTITIES = {}
local MAX_TRACKED_ENTITIES = 1000

---Get the player entity safely
---@return int|nil player_entity
function getPlayer()
    local players = EntityGetWithTag("player_unit")
    if players and #players > 0 then
        return players[1]
    end
    return nil
end

---Register an entity for death tracking
---@param entity int Entity ID
function trackEntity(entity)
    TRACKED_ENTITIES[entity] = true
end

---Check if entity is alive
---@param entity int
---@return boolean
function isEntityAlive(entity)
    return EntityGetIsAlive(entity)
end

-- ============================================================================
-- PLAYER DEATH DETECTION
-- ============================================================================

local PLAYER_LAST_STATE = {
    alive = true,
    health = 100,
    last_position = {x = 0, y = 0}
}

---Detect if player died this frame
---@return boolean
function didPlayerDie()
    local player = getPlayer()
    if not player then
        return false
    end
    
    if PLAYER_LAST_STATE.alive and not EntityGetIsAlive(player) then
        PLAYER_LAST_STATE.alive = false
        return true
    elseif not PLAYER_LAST_STATE.alive and EntityGetIsAlive(player) then
        PLAYER_LAST_STATE.alive = true
    end
    
    return false
end

---Get player death cause
---@return string
function getPlayerDeathCause()
    local player = getPlayer()
    if not player then return "unknown" end
    
    -- Check damage component for last damage type
    local damage_source, damage_type = getDamageInfo(player)
    
    -- Try to infer death cause from environment
    local x, y = EntityGetTransform(player)
    
    -- Check for lava (hell biome)
    if y > 12000 then
        return "lava"
    end
    
    -- Check for water (drowning)
    if y > 4000 then
        return "drown"
    end
    
    -- Return tracked damage type or unknown
    if damage_type ~= "unknown" then
        return damage_type
    end
    
    return "unknown"
end

---Detect player falling damage
---@return boolean
function detectFallDamage()
    local player = getPlayer()
    if not player then return false end
    
    local vel_x, vel_y = GameGetVelocityCompVelocity(player)
    
    -- High downward velocity indicates potential fall
    if vel_y and vel_y > 50 then
        return true
    end
    
    return false
end

-- ============================================================================
-- BIOME TRACKING
-- ============================================================================

local LAST_BIOME = "surface"
local BIOME_VISIT_HISTORY = {}

-- Biome detection helpers
local function getCurrentBiomeFromPosition()
    local x, y = GameGetWorldStateEntity() and EntityGetTransform(GameGetWorldStateEntity()) or 0, 0
    
    if y > 12000 then
        return "hell"
    elseif y > 10000 then
        return "hiisi_base"
    elseif y > 8000 then
        return "snowy_depths"
    elseif y > 4000 then
        return "caverns"
    elseif y > 0 then
        return "holy_mountain"
    else
        return "surface"
    end
end

---Check if player entered a new biome
---@return boolean, string
function didPlayerChangeBiome()
    local current_biome = getCurrentBiomeFromPosition()
    
    if current_biome ~= LAST_BIOME then
        local old_biome = LAST_BIOME
        LAST_BIOME = current_biome
        
        if not BIOME_VISIT_HISTORY[current_biome] then
            BIOME_VISIT_HISTORY[current_biome] = true
            return true, current_biome
        end
        
        return false, current_biome
    end
    
    return false, current_biome
end

---Get all visited biomes
---@return table
function getVisitedBiomes()
    return BIOME_VISIT_HISTORY
end

-- ============================================================================
-- SPECIAL EVENT TRACKING
-- ============================================================================

local EVENT_TRIGGERS = {
    fungal_shift_detected = false,
    secret_room_found = false,
    treasure_chest_found = false,
    player_polymorphed_frame = -1,
    polymorphed_ended_frame = -1,
    holy_mound_collapsed = false
}

local SECRET_ROOM_COUNT = 0
local CURRENT_FRAME = 0

---Detect polymorph status
---@return boolean
function isPlayerPolymorphed()
    local player = getPlayer()
    if not player then return false end
    
    -- Check for polymorph component/effect
    local comps = EntityGetAllComponents(player)
    for _, comp in ipairs(comps) do
        local comp_type = ComponentGetTypeName(comp)
        if comp_type == "PolymorphComponent" or string.match(comp_type, "Polymorph") then
            return true
        end
    end
    
    return false
end

---Detect if polymorph just started
---@return boolean
function didPlayerPolymorphThisFrame()
    local is_polymorphed = isPlayerPolymorphed()
    local last_frame_polymorphed = (EVENT_TRIGGERS.player_polymorphed_frame == CURRENT_FRAME - 1)
    
    if is_polymorphed and not last_frame_polymorphed then
        EVENT_TRIGGERS.player_polymorphed_frame = CURRENT_FRAME
        return true
    end
    
    return false
end

---Detect fungal shift (check for specific visual/audio cue or unusual entities)
---@return boolean
function detectFungalShift()
    -- Look for polymorph/perk changes that indicate fungal shift
    local player = getPlayer()
    if not player then return false end
    
    -- Check if reality shift particle effects exist
    local shift_entities = EntityGetWithTag("reality_shift_particle")
    
    if shift_entities and #shift_entities > 0 then
        if not EVENT_TRIGGERS.fungal_shift_detected then
            EVENT_TRIGGERS.fungal_shift_detected = true
            return true
        end
    else
        EVENT_TRIGGERS.fungal_shift_detected = false
    end
    
    return false
end

---Detect secret room discovery (treasure chests, special chambers)
---@return boolean
function detectSecretRoomDiscovered()
    local player = getPlayer()
    if not player then return false end
    
    local player_x, player_y = EntityGetTransform(player)
    
    -- Look for treasure chests or secret room markers nearby
    local treasure_chests = EntityGetWithTag("treasure_chest")
    
    if treasure_chests and #treasure_chests > 0 then
        for _, chest in ipairs(treasure_chests) do
            local chest_x, chest_y = EntityGetTransform(chest)
            local distance = math.sqrt((player_x - chest_x)^2 + (player_y - chest_y)^2)
            
            if distance < 500 then  -- Player is close to chest
                if not EVENT_TRIGGERS.treasure_chest_found then
                    EVENT_TRIGGERS.treasure_chest_found = true
                    return true
                end
            end
        end
    end
    
    return false
end

---Detect secret areas (count reached)
---@param count number
---@return boolean
function didDiscoverSecretAreas(count)
    SECRET_ROOM_COUNT = SECRET_ROOM_COUNT + 1
    return SECRET_ROOM_COUNT >= count
end

-- ============================================================================
-- WAND MODIFICATION TRACKING
-- ============================================================================

local WAND_STATE_CACHE = {}
local WAND_MOD_COUNT = 0

---Check if wand was modified this frame
---@return boolean
function wasWandModifiedThisFrame()
    local player = getPlayer()
    if not player then return false end
    
    local current_wands = {}
    local inventory = GameGetAllInventoryItems(player)
    
    if inventory then
        for _, item_id in ipairs(inventory) do
            local filename = EntityGetFilename(item_id)
            if filename and string.match(filename, "wand") then
                current_wands[item_id] = true
                
                -- Check if this wand's state changed
                if not WAND_STATE_CACHE[item_id] then
                    WAND_STATE_CACHE[item_id] = {
                        capacity = 0,
                        spells = {},
                        modified = false
                    }
                end
                
                local wand_comp = EntityGetFirstComponent(item_id, "ItemComponent")
                if wand_comp then
                    local new_capacity = ComponentGetValue2(wand_comp, "mana_max") or 0
                    
                    if new_capacity ~= WAND_STATE_CACHE[item_id].capacity then
                        WAND_STATE_CACHE[item_id].capacity = new_capacity
                        WAND_MOD_COUNT = WAND_MOD_COUNT + 1
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

---Get wand modification count
---@return number
function getWandModificationCount()
    return WAND_MOD_COUNT
end

-- ============================================================================
-- MAIN UPDATE FUNCTION (Call from OnWorldPreUpdate)
-- ============================================================================

---Update all event tracking (call every frame)
function updateEventTracking()
    CURRENT_FRAME = GameGetFrameNum()
    
    -- Track player death
    if didPlayerDie() then
        if BingoBoardState and BingoBoardState.auto_tracker then
            local death_cause = getPlayerDeathCause()
            BingoBoardState.auto_tracker:recordDeath()
            BingoBoardState.auto_tracker:recordEvent("player_death_" .. death_cause)
            print(string.format("Event: Player died (%s) - recorded to auto_tracker", death_cause))
        else
            print("WARNING: auto_tracker not available when player died")
        end
    end
    
    -- Track biome changes
    local biome_changed, new_biome = didPlayerChangeBiome()
    if biome_changed then
        if BingoBoardState and BingoBoardState.auto_tracker then
            BingoBoardState.auto_tracker:recordEvent("biome_reached_" .. new_biome)
            print(string.format("Event: Reached biome %s - recorded to auto_tracker", new_biome))
        else
            print("WARNING: auto_tracker not available when biome changed")
        end
    end
    
    -- Track polymorph
    if didPlayerPolymorphThisFrame() then
        if BingoBoardState and BingoBoardState.auto_tracker then
            BingoBoardState.auto_tracker:recordEvent("player_polymorphed")
            print("Event: Player polymorphed - recorded to auto_tracker")
        else
            print("WARNING: auto_tracker not available when player polymorphed")
        end
    end
    
    -- Track fungal shift
    local fungal_detected = detectFungalShift()
    if fungal_detected then
        print("DEBUG: detectFungalShift() returned TRUE")
        if BingoBoardState and BingoBoardState.auto_tracker then
            BingoBoardState.auto_tracker:recordEvent("fungal_shift")
            print("DEBUG: Fungal shift recorded to auto_tracker")
        else
            print("WARNING: auto_tracker not available when fungal shift detected")
        end
    end
    
    -- Track wand modifications
    if wasWandModifiedThisFrame() then
        if BingoBoardState and BingoBoardState.auto_tracker then
            BingoBoardState.auto_tracker:recordKill("wand_modified")
            print("Event: Wand modified - recorded to auto_tracker")
        else
            print("WARNING: auto_tracker not available when wand modified")
        end
    end
end

-- ============================================================================
-- EXPORT FOR USE
-- ============================================================================

BingoCore.EventHooks = {
    updateEventTracking = updateEventTracking,
    didPlayerDie = didPlayerDie,
    didPlayerChangeBiome = didPlayerChangeBiome,
    isPlayerPolymorphed = isPlayerPolymorphed,
    detectFungalShift = detectFungalShift,
    getPlayerDeathCause = getPlayerDeathCause,
    trackDamageEvent = trackDamageEvent,
    getWandModificationCount = getWandModificationCount
}

