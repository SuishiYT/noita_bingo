-- Example: Custom Objectives Configuration
-- Copy this to: mods/noita_bingo/objectives/custom.lua
-- 
-- Add your own custom objectives here!
-- They will be loaded automatically and combined with default objectives.

CUSTOM_OBJECTIVES = {
    -- ===== BLOODSHED CATEGORY =====
    {
        id = "custom_bloodshed_01",
        title = "Kill 100 Enemies",
        category = "bloodshed",
        difficulty = "medium",
        auto_track = {type = "kill_with_condition", condition = nil, min_kills = 100}
    },
    {
        id = "custom_bloodshed_02",
        title = "Defeat Mini-Boss",
        category = "bloodshed",
        difficulty = "hard",
        auto_track = {type = "kill_with_condition", condition = "boss", min_kills = 1}
    },
    {
        id = "custom_bloodshed_03",
        title = "Use Melee Weapon",
        category = "bloodshed",
        difficulty = "easy",
        auto_track = {type = "kill_with_condition", condition = "melee", min_kills = 1}
    },
    {
        id = "custom_bloodshed_04",
        title = "Kill Enemy with Environmental Hazard",
        category = "bloodshed",
        difficulty = "medium",
        auto_track = {type = "kill_with_condition", condition = "environment", min_kills = 1}
    },
    
    -- ===== DEATHS CATEGORY =====
    {
        id = "custom_deaths_01",
        title = "Die to Electricity",
        category = "deaths",
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "player_death_electricity"}
    },
    {
        id = "custom_deaths_02",
        title = "Die in Holy Mountain",
        category = "deaths",
        difficulty = "hard",
        auto_track = {type = "event_triggered", event_name = "player_death_holy_mountain"}
    },
    
    -- ===== WANDBUILDING CATEGORY =====
    {
        id = "custom_wand_01",
        title = "Build Multi-Cast Wand",
        category = "wandbuilding",
        difficulty = "hard",
        auto_track = {type = "wand_analysis", conditions = {
            {property = "capacity", operator = ">=", value = 3}
        }, require_all = true}
    },
    {
        id = "custom_wand_02",
        title = "Find Wand with 10+ Capacity",
        category = "wandbuilding",
        difficulty = "medium",
        auto_track = {type = "wand_analysis", conditions = {
            {property = "capacity", operator = ">=", value = 10}
        }, require_all = true}
    },
    {
        id = "custom_wand_03",
        title = "Build Infinite Spells Wand",
        category = "wandbuilding",
        difficulty = "hard",
        auto_track = {type = "wand_analysis", conditions = {
            {property = "capacity", operator = ">=", value = 15}
        }, require_all = true}
    },
    
    -- ===== INVENTORY CATEGORY =====
    {
        id = "custom_inventory_01",
        title = "Collect 3 Potions",
        category = "inventory",
        difficulty = "easy",
        auto_track = {type = "inventory_count", item_name = "potion", min_count = 3}
    },
    {
        id = "custom_inventory_02",
        title = "Find Enchantment",
        description = "Discover an enchanted item",
        category = "inventory",
        difficulty = "medium",
        auto_track = {type = "inventory_count", item_name = "enchantment", min_count = 1}
    },
    {
        id = "custom_inventory_03",
        title = "Collect 2000 Gold",
        category = "inventory",
        difficulty = "hard",
        auto_track = {type = "gold_collect", min_gold = 2000}
    },
    
    -- ===== EXPLORATION CATEGORY =====
    {
        id = "custom_explore_01",
        title = "Find Secret Room",
        category = "exploration",
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "found_secret_room"}
    },
    {
        id = "custom_explore_02",
        title = "Reach Deep Caverns",
        category = "exploration",
        difficulty = "hard",
        auto_track = {type = "biome_reach", biome_name = "deep_cavern"}
    },
    {
        id = "custom_explore_03",
        title = "Visit 3 Parallel Worlds",
        category = "exploration",
        difficulty = "hard",
        auto_track = {type = "event_triggered", event_name = "parallel_worlds_visited"}
    },
    
    -- ===== EVENTS/MISC CATEGORY =====
    {
        id = "custom_events_01",
        title = "Survive 30 Minutes",
        category = "events_misc",
        difficulty = "medium",
        auto_track = {type = "time_survive", min_time = 1800}
    },
    {
        id = "custom_events_02",
        title = "Get 3 Perks",
        category = "events_misc",
        difficulty = "easy",
        auto_track = {type = "composite", logic = "and", objectives = {
            {type = "perk_obtain", perk_id = "perk_1"},
            {type = "perk_obtain", perk_id = "perk_2"},
            {type = "perk_obtain", perk_id = "perk_3"}
        }}
    },
    {
        id = "custom_events_03",
        title = "Trigger Random Event",
        category = "events_misc",
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "random_event"}
    }
}
