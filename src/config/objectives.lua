-- Objectives Configuration
-- Defines default objectives and category system

-- Default objectives for Bingo
-- Each objective includes auto_track configuration for automatic detection
local DEFAULT_OBJECTIVES = {
    -- Bloodshed Category
    { 
        id = "bloodshed_01", 
        title = "Kill 50 Enemies", 
        category = "bloodshed", 
        difficulty = "medium",
        auto_track = {type = "kill_with_condition", condition = nil, min_kills = 50}
    },
    { 
        id = "bloodshed_02", 
        title = "Defeat a Boss", 
        category = "bloodshed", 
        difficulty = "hard",
        auto_track = {type = "kill_with_condition", condition = "boss", min_kills = 1}
    },
    { 
        id = "bloodshed_03", 
        title = "Get Melee Damage Perk", 
        category = "bloodshed", 
        difficulty = "easy",
        auto_track = {type = "perk_obtain", perk_id = "damage_melee"}
    },
    { 
        id = "bloodshed_04", 
        title = "Kill an Enemy with Explosion", 
        category = "bloodshed", 
        difficulty = "medium",
        auto_track = {type = "kill_with_condition", condition = "explosion", min_kills = 1}
    },
    { 
        id = "bloodshed_05", 
        title = "Survive 20 Bloodshed Encounters", 
        category = "bloodshed", 
        difficulty = "medium",
        auto_track = {type = "composite", logic = "and", objectives = {
            {type = "time_survive", min_time = 1200},
            {type = "kill_with_condition", condition = nil, min_kills = 20}
        }}
    },
    
    -- Deaths Category
    { 
        id = "deaths_01", 
        title = "Die to Fall Damage", 
        category = "deaths", 
        difficulty = "easy",
        auto_track = {type = "event_triggered", event_name = "player_death_fall"}
    },
    { 
        id = "deaths_02", 
        title = "Die to Your Own Spell", 
        category = "deaths", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "player_death_own_spell"}
    },
    { 
        id = "deaths_03", 
        title = "Die to Poison", 
        category = "deaths", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "player_death_poison"}
    },
    { 
        id = "deaths_04", 
        title = "Die to Drowning", 
        category = "deaths", 
        difficulty = "hard",
        auto_track = {type = "event_triggered", event_name = "player_death_drown"}
    },
    { 
        id = "deaths_05", 
        title = "Die in a Specific Biome", 
        category = "deaths", 
        difficulty = "medium",
        auto_track = {type = "death_count", min_deaths = 1}
    },
    
    -- Wandbuilding Category
    { 
        id = "wand_01", 
        title = "Build a Wand with 5+ Spells", 
        category = "wandbuilding", 
        difficulty = "medium",
        auto_track = {type = "wand_analysis", conditions = {
            {property = "capacity", operator = ">=", value = 5}
        }, require_all = true}
    },
    { 
        id = "wand_02", 
        title = "Create a Rapid Fire Wand", 
        category = "wandbuilding", 
        difficulty = "hard",
        auto_track = {type = "wand_analysis", conditions = {
            {property = "fire_rate_wait", operator = "<=", value = 0.1},
            {property = "cast_delay", operator = "<=", value = 0.1}
        }, require_all = true}
    },
    { 
        id = "wand_03", 
        title = "Find a Always Cast Wand", 
        category = "wandbuilding", 
        difficulty = "medium",
        auto_track = {type = "wand_analysis", conditions = {
            {property = "cast_delay", operator = "==", value = 0}
        }, require_all = true}
    },
    { 
        id = "wand_04", 
        title = "Modify a Wand 10 Times", 
        category = "wandbuilding", 
        difficulty = "medium",
        auto_track = {type = "kill_with_condition", condition = "wand_modified", min_kills = 10}
    },
    { 
        id = "wand_05", 
        title = "Build a Projectile Modifier Chain", 
        category = "wandbuilding", 
        difficulty = "hard",
        auto_track = {type = "kill_with_condition", condition = "wand_modifiers", min_kills = 1}
    },
    
    -- Inventory Category
    { 
        id = "inventory_01", 
        title = "Collect 5 Potions", 
        category = "inventory", 
        difficulty = "easy",
        auto_track = {type = "inventory_count", item_name = "potion", min_count = 5, exclude_liquids = false}
    },
    { 
        id = "inventory_02", 
        title = "Find a Legendary Item", 
        category = "inventory", 
        difficulty = "hard",
        auto_track = {type = "inventory_count", item_name = "legendary", min_count = 1, exclude_liquids = false}
    },
    { 
        id = "inventory_03", 
        title = "Carry 10 Different Items", 
        category = "inventory", 
        difficulty = "medium",
        auto_track = {type = "inventory_count", item_name = nil, min_count = 10, exclude_liquids = true}
    },
    { 
        id = "inventory_04", 
        title = "Find a Tablet", 
        category = "inventory", 
        difficulty = "medium",
        auto_track = {type = "inventory_count", item_name = "tablet", min_count = 1, exclude_liquids = false}
    },
    { 
        id = "inventory_05", 
        title = "Collect 1000 Gold", 
        category = "inventory", 
        difficulty = "medium",
        auto_track = {type = "gold_collect", min_gold = 1000}
    },
    
    -- Exploration Category
    { 
        id = "explore_01", 
        title = "Reach Caverns", 
        category = "exploration", 
        difficulty = "easy",
        auto_track = {type = "biome_reach", biome_name = "caverns"}
    },
    { 
        id = "explore_02", 
        title = "Reach Hell", 
        category = "exploration", 
        difficulty = "hard",
        auto_track = {type = "biome_reach", biome_name = "hell"}
    },
    { 
        id = "explore_03", 
        title = "Discover 5 Secret Areas", 
        category = "exploration", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "secret_areas_discovered_5"}
    },
    { 
        id = "explore_04", 
        title = "Visit the Holy Mountain", 
        category = "exploration", 
        difficulty = "easy",
        auto_track = {type = "biome_reach", biome_name = "holy_mountain"}
    },
    { 
        id = "explore_05", 
        title = "Find the Treasure Chest", 
        category = "exploration", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "treasure_chest_found"}
    },
    
    -- Events/Misc Category
    { 
        id = "events_01", 
        title = "Survive 10 Minutes", 
        category = "events_misc", 
        difficulty = "easy",
        auto_track = {type = "time_survive", min_time = 600}
    },
    { 
        id = "events_02", 
        title = "Trigger a Fungal Shift", 
        category = "events_misc", 
        difficulty = "hard",
        auto_track = {type = "event_triggered", event_name = "fungal_shift"}
    },
    { 
        id = "events_03", 
        title = "Find a Secret Room", 
        category = "events_misc", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "secret_room_found"}
    },
    { 
        id = "events_04", 
        title = "Get Polymorphed", 
        category = "events_misc", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "player_polymorphed"}
    },
    { 
        id = "events_05", 
        title = "Complete an Event", 
        category = "events_misc", 
        difficulty = "medium",
        auto_track = {type = "event_triggered", event_name = "event_completed"}
    }
}

---Load objectives from custom file if it exists
---@return table
local function loadObjectives()
    local objectives = {}
    
    -- Verify BingoCore.Objective exists
    if not BingoCore or not BingoCore.Objective then
        print("CRITICAL ERROR: BingoCore.Objective not available!")
        -- Create a dummy objective so the game doesn't crash
        table.insert(objectives, {
            id = "dummy_01",
            title = "Dummy Objective",
            category = "bloodshed",
            difficulty = "easy"
        })
        return objectives
    end
    
    print("Creating objectives from DEFAULT_OBJECTIVES...")
    print("DEFAULT_OBJECTIVES count: " .. #DEFAULT_OBJECTIVES)
    
    -- Load defaults
    for i, obj_data in ipairs(DEFAULT_OBJECTIVES) do
        local obj = BingoCore.Objective.new(obj_data)
        if obj then
            table.insert(objectives, obj)
        else
            print("Failed to create objective #" .. i)
        end
    end
    
    print("Loaded " .. #objectives .. " objectives total")
    return objectives
end

BingoConfig.loadObjectives = loadObjectives
BingoConfig.DEFAULT_OBJECTIVES = DEFAULT_OBJECTIVES
