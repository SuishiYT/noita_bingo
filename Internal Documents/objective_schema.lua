---@class Objective
---@field id string
---@field title string
---@field description string
---@field category string
---@field luck number
---@field difficulty "easy" | "medium" | "hard"
---@field count Count|nil

---@class Count
---@field competitive number
---@field coop number

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
    
    self.id = data.id
    self.title = data.title
    self.description = data.description
    self.category = data.category
    self.luck = data.luck
    self.difficulty = data.difficulty or "medium"
    
    -- Handle count validation and assignment
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
    
    return self
end