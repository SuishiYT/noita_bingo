return {
    {
        id = "objective_01",
        title = "Ponderer",
        description = "Collect ${count} Orbs",
        category = "inventory",
        luck = 4,
        difficulty = "medium",
        count = {
            competitive = {1, 3},
            coop = {3, 5},
        }
    },
    {
        id = "objective_02",
        title = "On your left",
        description = "Freeze to death.",
        category = {"wandbuilding", "inventory"},
        modifier = "death"
        luck = 5,
        difficulty = "hard",
        count = {
            competitive = nil,
            coop = nil
        },
        reward = {
            reward_type = "good"
        },
    }
}