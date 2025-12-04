-- Auto-Tracking System Documentation
-- ===================================
-- This file documents how the auto-tracking system works and how to extend it.

--[[
## Overview

The Auto-Tracking system automatically detects when players complete objectives
without requiring manual button clicks. It uses a declarative configuration approach
where each objective defines what conditions must be met for completion.

The system has two main components:
1. **AutoTracker** - Detects objective completion based on game state
2. **EventHooks** - Monitors game events and records them for tracking

## How It Works

### Frame-by-frame processing:

1. `OnWorldPreUpdate()` is called
2. `updateEventTracking()` detects game events (deaths, biome changes, polymorph, etc.)
3. Detected events are recorded in `AutoTracker.event_history`
4. `AutoTracker:update()` updates player state snapshot
5. `autoCheckBoard()` checks each uncompleted objective
6. If an objective's conditions are met, the board square auto-clears
7. If multiplayer, clear is broadcast to opponents

### Monitored Events:

The event_hooks.lua module tracks:
- **Player Deaths** - Records with cause (fall, poison, drown, own_spell, etc.)
- **Biome Changes** - Records when player enters new biome
- **Polymorph Status** - Records when player becomes polymorphed
- **Fungal Shifts** - Records reality shift events
- **Wand Modifications** - Records when wand properties change
- **Secret Discoveries** - Records treasure chests and secret rooms

## Adding Auto-Tracking to Objectives

Each objective includes an `auto_track` table with detection configuration:

```lua
{
    id = "explore_01",
    title = "Reach Caverns",
    category = "exploration",
    difficulty = "easy",
    auto_track = {
        type = "biome_reach",
        biome_name = "caverns"
    }
}
```

## Available Detection Types

### 1. biome_reach
Detects when player enters a specific biome.

```lua
auto_track = {
    type = "biome_reach",
    biome_name = "caverns"  -- "caverns" | "hell" | "snowy_depths" | "hiisi_base" | "holy_mountain" | "surface"
}
```

**Event Source:** `biome_reached_<biome_name>` (from event_hooks)

### 2. perk_obtain
Detects when player has a specific perk.

```lua
auto_track = {
    type = "perk_obtain",
    perk_id = "damage_melee"  -- Any perk ID from game
}
```

**Event Source:** Direct game state query (PerksComponent)

### 3. gold_collect
Detects when player has accumulated X gold.

```lua
auto_track = {
    type = "gold_collect",
    min_gold = 1000
}
```

**Event Source:** Direct game state query (MoneyComponent)

### 4. wand_analysis
Detects wands matching specific property conditions.

```lua
auto_track = {
    type = "wand_analysis",
    conditions = {
        {property = "capacity", operator = ">=", value = 5},
        {property = "fire_rate_wait", operator = "<=", value = 0.1},
        {property = "cast_delay", operator = "==", value = 0}
    },
    require_all = true  -- all conditions must pass (or 'false' for any match)
}
```

Available wand properties:
- capacity: Number of spells that can fit
- fire_rate_wait: Time between shots
- reload_time: Time to reload mana
- cast_delay: Delay before firing

Operators: "<", "<=", ">", ">=", "==", "!="

**Event Source:** Direct game state query (ItemComponent)

### 5. inventory_count
Detects items in player inventory.

```lua
auto_track = {
    type = "inventory_count",
    item_name = "potion",      -- Part of filename to match (or nil for any)
    min_count = 5,
    exclude_liquids = false    -- true to skip potions/liquids
}
```

**Event Source:** Direct game state query (ItemContainer)

### 6. kill_with_condition
Detects kills with specific conditions.

```lua
auto_track = {
    type = "kill_with_condition",
    condition = "explosion",   -- Detection type
    min_kills = 1
}
```

Kill conditions (from event_hooks.recordKill()):
- nil (any kill)
- "explosion"
- "kick"
- "tablet"
- "wand_modified"
- "boss"

**Event Source:** `recordKill(condition)` calls from event_hooks

### 7. death_count
Detects number of deaths.

```lua
auto_track = {
    type = "death_count",
    min_deaths = 1
}
```

**Event Source:** `recordDeath()` calls from event_hooks

### 8. time_survive
Detects if player survived X seconds.

```lua
auto_track = {
    type = "time_survive",
    min_time = 600  -- seconds
}
```

**Event Source:** Direct game state query (GameGetFrameNum / elapsed time)

### 9. event_triggered
Detects if a specific game event occurred.

```lua
auto_track = {
    type = "event_triggered",
    event_name = "fungal_shift"
}
```

Common events (recorded by event_hooks):
- "fungal_shift" - Reality shift occurred
- "secret_room_found" - Secret chamber discovered
- "treasure_chest_found" - Treasure chest found
- "player_polymorphed" - Player polymorphed
- "player_death_fall" - Died to fall damage
- "player_death_own_spell" - Died to own spell
- "player_death_poison" - Died to poison
- "player_death_drown" - Died to drowning
- "player_death_unknown" - Died from unknown cause
- "biome_reached_<biome>" - Entered specific biome
- "event_completed" - Generic event completion

**Event Source:** `recordEvent(event_name)` calls from event_hooks

### 10. composite
Combines multiple detection types with AND/OR logic.

```lua
auto_track = {
    type = "composite",
    logic = "and",  -- "and" or "or"
    objectives = {
        {type = "biome_reach", biome_name = "hell"},
        {type = "time_survive", min_time = 3600}
    }
}
```

## Event Recording Flow

### Player Death Detection

When player dies:
1. `updateEventTracking()` detects death via `didPlayerDie()`
2. `getPlayerDeathCause()` determines death type:
   - Check current biome → "drown", "lava"
   - Check damage type → "poison", "fall", "own_spell"
   - Fallback → "unknown"
3. `recordDeath()` increments death counter
4. `recordEvent("player_death_" .. cause)` records specific death type

Events recorded: `player_death_fall`, `player_death_poison`, `player_death_drown`, `player_death_own_spell`

### Biome Change Detection

When player enters new biome:
1. `didPlayerChangeBiome()` detects position change
2. Biome name determined from Y coordinate
3. `recordEvent("biome_reached_" .. biome)` records biome visit

Events recorded: `biome_reached_caverns`, `biome_reached_hell`, `biome_reached_holy_mountain`, etc.

### Wand Modification Tracking

Every frame:
1. `wasWandModifiedThisFrame()` checks wand properties
2. Compares capacity, fire_rate, reload_time against cache
3. If any property changed: increment modification counter
4. `recordKill("wand_modified")` records modification

### Polymorph Detection

Every frame:
1. `didPlayerPolymorphThisFrame()` checks for PolymorphComponent
2. If component exists and wasn't present last frame:
3. `recordEvent("player_polymorphed")` records polymorph

## Game State Query Functions

Available helper functions for detecting game state (in auto_tracker.lua):

- `getPlayerEntity()` - Get player entity ID
- `getPlayerPosition()` - Get player X, Y coords
- `getCurrentBiome()` - Get current biome name
- `hasPlayerPerk(perk_id)` - Check if player has perk
- `getPlayerWands()` - Get array of wand entities
- `analyzeWand(wand_entity)` - Get wand properties
- `countInventoryItems(item_name, exclude_liquids)` - Count items
- `getPlayerGold()` - Get player gold amount
- `getRecentKillsWithCondition(kill_type)` - Get kill count
- `getPlayerDeaths()` - Get death count
- `getGameTime()` - Get elapsed game time in seconds
- `isPlayerPolymorphed()` - Check polymorph status

## Adding New Detection Types

To add a new detection type:

1. Open `src/core/auto_tracker.lua`
2. Add a new function to `DETECTOR_HANDLERS`:

```lua
function DETECTOR_HANDLERS.my_new_type(obj, config)
    -- Your detection logic here
    -- Return true if objective is completed, false otherwise
    
    local player = getPlayerEntity()
    if not player then return false end
    
    -- Implement custom detection
    local condition_met = yourCustomCheck(config)
    return condition_met
end
```

3. Update objectives to use it:

```lua
{
    id = "custom_01",
    title = "My Objective",
    category = "custom",
    difficulty = "medium",
    auto_track = {
        type = "my_new_type",
        param1 = "value1",
        param2 = "value2"
    }
}
```

## Adding New Events

To record new events in event_hooks.lua:

1. In `updateEventTracking()`, add detection logic:

```lua
if myCustomDetection() then
    if BingoBoardState and BingoBoardState.auto_tracker then
        BingoBoardState.auto_tracker:recordEvent("my_event_name")
        print("Event: My custom event")
    end
end
```

2. Use in objectives:

```lua
auto_track = {
    type = "event_triggered",
    event_name = "my_event_name"
}
```

## Debugging Event Tracking

Events are logged to console when recorded. Check console output for:
- "Event: Player died (fall)" - Player death types
- "Event: Reached biome caverns" - Biome changes
- "Event: Player polymorphed" - Status effect changes
- "Event: Wand modified" - Wand changes

To see auto-cleared squares:
- "AutoTracker: Auto-cleared bloodshed_01 (1,2)" - Board square auto-cleared

## Limitations and Future Improvements

Current Limitations:
- Death cause detection is approximate (uses biome/damage type)
- Some complex objectives need manual event recording
- Wand analysis limited to basic properties

Potential Improvements:
- Hook into actual entity death events (OnEntityKilled callback if available)
- Add more wand properties (DPS, projectile types, modifier chains)
- Add entity proximity detection for chest/secret room discovery
- Add damage/health tracking for specific enemy types
- Add spell inventory tracking
- Add potion/material inventory analysis

]]--

