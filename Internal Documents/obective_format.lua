return {
    -- ===== COMBAT CATEGORY =====
    {
        id = "combat_01",
        title = "Executioner",
        description = "Kill 100 enemies",
        category = "combat",
        luck = 0,
        difficulty = "medium"
    },
    {
        id = "deaths_01",
        title = "Johnny Storm",
        description = "Die to fire damage",
        category = {"combat", "deaths"},
        luck = 0,
        difficulty = "easy"
    },
    -- ===== WANDBUILDING CATEGORY =====
    {
        id = "wandbuilding_01",
        title = "Boom Stick",
        description = "Find a wand with 8 or more capacity",
        category = "wandbuilding",
        luck = 7,
        difficulty = "medium",
        }
    }
},

return {
    {
        id = "inventory_01",
        title = "Ponderer",
        description = "Collect ${count} Orbs",
        category = "inventory",
        count = {
            competitive = {1, 3},
            coop = {3, 5},
        }
    }
}