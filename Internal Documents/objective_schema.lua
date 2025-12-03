---@class Objective
---@field id string
---@field title string
---@field description string
---@field category string
---@field modifier "death" | "spell_list" | nil
---@field luck number
---@field difficulty "easy" | "medium" | "hard"
---@field count Count | nil
---@field hasReward Reward | nil

---@class Count
---@field competitive number
---@field coop number

---@class Reward
---@field reward_type "good" | "bad" 

---Create a new objective
---@param data table
---@return Objective
function Objective.new(data)
    local self = setmetatable({}, Objective)

    --- Field Error Handling
    if data.id == nil then error("Objective must have an ID") end
    if data.title == nil then error("Objective must have a Title") end
    if data.description == nil then error("Objective must have a Description") end
    if data.category == nil then error("Objective must have a Category") end
    if data.luck == nil then error("Objective must have a Luck value") end
    
    -- Basic Field Assignment
    self.id = data.id
    self.title = data.title
    self.description = data.description
    self.category = data.category
    self.modifier = data.modifier or nil
    self.luck = data.luck
    self.difficulty = data.difficulty or "medium"
    
    -- count validation and assignment handler
    if data.count ~= nil then
        if data.count.competitive == nil then error("Count must have competitive value") end
        if data.count.coop == nil then error("Count must have coop value") end
        self.count = {
            competitive = data.count.competitive,
            coop = data.count.coop
        }
    else
        self.count = nil
    end

    -- hasReward validation and assignment handler
    if data.hasReward ~= nil then
        if data.hasReward.reward_type == nil then error("If hasReward is true, reward_type must be specified") end
        self.hasReward = {
            reward_type = data.hasReward.reward_type
        }
    else
        self.hasReward = nil
    end

    return self
end