-- Objectives Configuration
-- Defines default objectives and category system

-- Default objectives for Bingo
local DEFAULT_OBJECTIVES = {
    -- Bloodshed Category
    { id = "bloodshed_01", title = "Kill 50 Enemies", category = "bloodshed", difficulty = "medium" },
    { id = "bloodshed_02", title = "Defeat a Boss", category = "bloodshed", difficulty = "hard" },
    { id = "bloodshed_03", title = "Get Melee Damage Perk", category = "bloodshed", difficulty = "easy" },
    { id = "bloodshed_04", title = "Kill an Enemy with Explosion", category = "bloodshed", difficulty = "medium" },
    { id = "bloodshed_05", title = "Survive 20 Bloodshed Encounters", category = "bloodshed", difficulty = "medium" },
    
    -- Deaths Category
    { id = "deaths_01", title = "Die to Fall Damage", category = "deaths", difficulty = "easy" },
    { id = "deaths_02", title = "Die to Your Own Spell", category = "deaths", difficulty = "medium" },
    { id = "deaths_03", title = "Die to Poison", category = "deaths", difficulty = "medium" },
    { id = "deaths_04", title = "Die to Drowning", category = "deaths", difficulty = "hard" },
    { id = "deaths_05", title = "Die in a Specific Biome", category = "deaths", difficulty = "medium" },
    
    -- Wandbuilding Category
    { id = "wand_01", title = "Build a Wand with 5+ Spells", category = "wandbuilding", difficulty = "medium" },
    { id = "wand_02", title = "Create a Rapid Fire Wand", category = "wandbuilding", difficulty = "hard" },
    { id = "wand_03", title = "Find a Always Cast Wand", category = "wandbuilding", difficulty = "medium" },
    { id = "wand_04", title = "Modify a Wand 10 Times", category = "wandbuilding", difficulty = "medium" },
    { id = "wand_05", title = "Build a Projectile Modifier Chain", category = "wandbuilding", difficulty = "hard" },
    
    -- Inventory Category
    { id = "inventory_01", title = "Collect 5 Potions", category = "inventory", difficulty = "easy" },
    { id = "inventory_02", title = "Find a Legendary Item", category = "inventory", difficulty = "hard" },
    { id = "inventory_03", title = "Carry 10 Different Items", category = "inventory", difficulty = "medium" },
    { id = "inventory_04", title = "Find a Tablet", category = "inventory", difficulty = "medium" },
    { id = "inventory_05", title = "Collect 1000 Gold", category = "inventory", difficulty = "medium" },
    
    -- Exploration Category
    { id = "explore_01", title = "Reach Caverns", category = "exploration", difficulty = "easy" },
    { id = "explore_02", title = "Reach Hell", category = "exploration", difficulty = "hard" },
    { id = "explore_03", title = "Discover 5 Secret Areas", category = "exploration", difficulty = "medium" },
    { id = "explore_04", title = "Visit the Holy Mountain", category = "exploration", difficulty = "easy" },
    { id = "explore_05", title = "Find the Treasure Chest", category = "exploration", difficulty = "medium" },
    
    -- Events/Misc Category
    { id = "events_01", title = "Survive 10 Minutes", category = "events_misc", difficulty = "easy" },
    { id = "events_02", title = "Trigger a Fungal Shift", category = "events_misc", difficulty = "hard" },
    { id = "events_03", title = "Find a Secret Room", category = "events_misc", difficulty = "medium" },
    { id = "events_04", title = "Get Polymorphed", category = "events_misc", difficulty = "medium" },
    { id = "events_05", title = "Complete an Event", category = "events_misc", difficulty = "medium" }
}

---Load objectives from custom file if it exists
---@return table
local function loadObjectives()
    local objectives = {}
    
    -- Load defaults
    for _, obj_data in ipairs(DEFAULT_OBJECTIVES) do
        table.insert(objectives, BingoCore.Objective.new(obj_data))
    end
    
    -- TODO: Load custom objectives from file
    
    return objectives
end

BingoConfig.loadObjectives = loadObjectives
BingoConfig.DEFAULT_OBJECTIVES = DEFAULT_OBJECTIVES
