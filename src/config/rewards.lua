-- Rewards Configuration
-- Defines objective rewards for completing tasks

---@class RewardsManager
local RewardsManager = {}
RewardsManager.__index = RewardsManager

function RewardsManager.new()
    local self = setmetatable({}, RewardsManager)
    
    -- Rewards database
    self.rewards = {
        -- Health rewards
        health_small = { type = "health", value = 25, display_name = "Small Health Potion" },
        health_medium = { type = "health", value = 50, display_name = "Medium Health Potion" },
        health_large = { type = "health", value = 100, display_name = "Large Health Potion" },
        
        -- Mana rewards
        mana_small = { type = "mana", value = 50, display_name = "Small Mana Potion" },
        mana_medium = { type = "mana", value = 100, display_name = "Medium Mana Potion" },
        
        -- Gold rewards
        gold_small = { type = "gold", value = 100, display_name = "100 Gold" },
        gold_medium = { type = "gold", value = 500, display_name = "500 Gold" },
        gold_large = { type = "gold", value = 1000, display_name = "1000 Gold" },
        
        -- Perk rewards
        perk_random = { type = "perk", value = "random", display_name = "Random Perk" },
        perk_damage = { type = "perk", value = "damage", display_name = "Damage Perk" },
        perk_speed = { type = "perk", value = "speed", display_name = "Speed Perk" },
        
        -- Spell rewards
        spell_random = { type = "spell", value = "random", display_name = "Random Spell" }
    }
    
    -- Objective to reward mappings
    self.objective_rewards = {}
    
    return self
end

---Set reward for an objective
---@param objective_id string
---@param reward_id string
function RewardsManager:setObjectiveReward(objective_id, reward_id)
    if self.rewards[reward_id] then
        self.objective_rewards[objective_id] = reward_id
    end
end

---Get reward for an objective
---@param objective_id string
---@return table|nil
function RewardsManager:getObjectiveReward(objective_id)
    local reward_id = self.objective_rewards[objective_id]
    if reward_id then
        return self.rewards[reward_id]
    end
    return nil
end

---Claim reward (apply to player)
---@param player_id string
---@param objective_id string
function RewardsManager:claimReward(player_id, objective_id)
    local reward = self:getObjectiveReward(objective_id)
    
    if reward then
        -- TODO: Implement reward application logic
        print(string.format("Player %s claims reward: %s", player_id, reward.display_name))
    end
end

BingoConfig.RewardsManager = RewardsManager
