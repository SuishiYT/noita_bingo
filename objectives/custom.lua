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
        difficulty = "medium"
    },
    {
        id = "custom_bloodshed_02",
        title = "Defeat Mini-Boss",
        category = "bloodshed",
        difficulty = "hard"
    },
    {
        id = "custom_bloodshed_03",
        title = "Use Melee Weapon",
        category = "bloodshed",
        difficulty = "easy"
    },
    {
        id = "custom_bloodshed_04",
        title = "Kill Enemy with Environmental Hazard",
        category = "bloodshed",
        difficulty = "medium"
    },
    
    -- ===== DEATHS CATEGORY =====
    {
        id = "custom_deaths_01",
        title = "Die to Electricity",
        category = "deaths",
        difficulty = "medium"
    },
    {
        id = "custom_deaths_02",
        title = "Die in Holy Mountain",
        category = "deaths",
        difficulty = "hard"
    },
    
    -- ===== WANDBUILDING CATEGORY =====
    {
        id = "custom_wand_01",
        title = "Build Multi-Cast Wand",
        category = "wandbuilding",
        difficulty = "hard"
    },
    {
        id = "custom_wand_02",
        title = "Find Wand with 10+ Capacity",
        category = "wandbuilding",
        difficulty = "medium"
    },
    {
        id = "custom_wand_03",
        title = "Build Infinite Spells Wand",
        category = "wandbuilding",
        difficulty = "hard"
    },
    
    -- ===== INVENTORY CATEGORY =====
    {
        id = "custom_inventory_01",
        title = "Collect 3 Potions",
        category = "inventory",
        difficulty = "easy"
    },
    {
        id = "custom_inventory_02",
        title = "Find Enchantment",
        description = "Discover an enchanted item",
        category = "inventory",
        difficulty = "medium"
    },
    {
        id = "custom_inventory_03",
        title = "Collect 2000 Gold",
        category = "inventory",
        difficulty = "hard"
    },
    
    -- ===== EXPLORATION CATEGORY =====
    {
        id = "custom_explore_01",
        title = "Find Secret Room",
        category = "exploration",
        difficulty = "medium"
    },
    {
        id = "custom_explore_02",
        title = "Reach Deep Caverns",
        category = "exploration",
        difficulty = "hard"
    },
    {
        id = "custom_explore_03",
        title = "Visit 3 Parallel Worlds",
        category = "exploration",
        difficulty = "hard"
    },
    
    -- ===== EVENTS/MISC CATEGORY =====
    {
        id = "custom_events_01",
        title = "Survive 30 Minutes",
        category = "events_misc",
        difficulty = "medium"
    },
    {
        id = "custom_events_02",
        title = "Get 3 Perks",
        category = "events_misc",
        difficulty = "easy"
    },
    {
        id = "custom_events_03",
        title = "Trigger Random Event",
        category = "events_misc",
        difficulty = "medium"
    }
}
