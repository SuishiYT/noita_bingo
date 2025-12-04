-- Objective class and category system
-- Handles individual objectives, categories, and weighting

---@class Objective
---@field id string
---@field title string
---@field description string
---@field category string
---@field difficulty "easy" | "medium" | "hard"
---@field reward_enabled boolean
---@field reward_type string
---@field reward_value any
local Objective = {}
Objective.__index = Objective

---Create a new objective
---@param data table
---@return Objective
function Objective.new(data)
    local self = setmetatable({}, Objective)

    --- Field Error Handling
    if not data.id then error("Objective must have an id") end
    if not data.title then error("Objective must have a title") end
    if not data.category then error("Objective must have a category") end
    if not data.difficulty then error("Objective must have a difficulty") end
    
    self.id = data.id or "unknown"
    self.title = data.title or "Unknown Objective"
    self.description = data.description or data.title  -- Use title as fallback for description
    self.category = data.category or "general"
    self.difficulty = data.difficulty or "medium"
    self.reward_enabled = data.reward_enabled ~= false
    self.reward_type = data.reward_type or "none"
    self.reward_value = data.reward_value or nil
    
    -- Copy auto_track configuration if present
    self.auto_track = data.auto_track or nil
    
    return self
end

---Get a string representation of the objective
---@return string
function Objective:toString()
    return string.format("[%s] %s (%s)", self.id, self.title, self.category)
end

BingoCore.Objective = Objective

---@class CategorySystem
---@field categories table<string, {weight: number, limit: number, objectives: table}>
local CategorySystem = {}
CategorySystem.__index = CategorySystem

---Create a new category system
---@return CategorySystem
function CategorySystem.new()
    local self = setmetatable({}, CategorySystem)
    
    self.categories = {
        bloodshed = { weight = 1.0, limit = nil, objectives = {} },
        deaths = { weight = 1.0, limit = nil, objectives = {} },
        wandbuilding = { weight = 1.0, limit = nil, objectives = {} },
        inventory = { weight = 1.0, limit = nil, objectives = {} },
        exploration = { weight = 1.0, limit = nil, objectives = {} },
        events_misc = { weight = 1.0, limit = nil, objectives = {} }
    }
    
    return self
end

---Set weight for a category
---@param category string
---@param weight number
function CategorySystem:setWeight(category, weight)
    if self.categories[category] then
        self.categories[category].weight = math.max(0, weight)
    end
end

---Set limit for a category
---@param category string
---@param limit number|nil
function CategorySystem:setLimit(category, limit)
    if self.categories[category] then
        self.categories[category].limit = limit
    end
end

---Get all objectives in a category
---@param category string
---@return table
function CategorySystem:getObjectivesByCategory(category)
    if self.categories[category] then
        return self.categories[category].objectives or {}
    end
    return {}
end

---Register an objective in the system
---@param objective Objective
function CategorySystem:registerObjective(objective)
    if not self.categories[objective.category] then
        self.categories[objective.category] = {
            weight = 1.0,
            limit = nil,
            objectives = {}
        }
    end
    
    table.insert(self.categories[objective.category].objectives, objective)
    print("CategorySystem: Registered objective " .. objective.id .. " in category " .. objective.category)
end

---Get objectives for board generation respecting weights and limits
---@param count number
---@return table
function CategorySystem:selectObjectives(count)
    local selected = {}
    local category_counts = {}
    
    -- Debug: log what categories we have
    local total_obj_count = 0
    for category, data in pairs(self.categories) do
        local obj_count = #data.objectives
        total_obj_count = total_obj_count + obj_count
        if obj_count > 0 then
            print("CategorySystem: Category '" .. category .. "' has " .. obj_count .. " objectives")
        end
    end
    print("CategorySystem: Total objectives available: " .. total_obj_count)
    
    if total_obj_count == 0 then
        print("ERROR: No objectives available for board generation!")
        return selected
    end
    
    -- Initialize category counts
    for category, _ in pairs(self.categories) do
        category_counts[category] = 0
    end
    
    -- Calculate total weight
    local total_weight = 0
    for category, data in pairs(self.categories) do
        if #data.objectives > 0 then
            total_weight = total_weight + data.weight
        end
    end
    
    if total_weight == 0 then
        print("ERROR: Total weight is 0, cannot select objectives!")
        return selected
    end
    
    print("CategorySystem: Selecting " .. count .. " objectives...")
    
    -- Select objectives respecting weights and limits
    for i = 1, count do
        local remaining = count - i + 1
        local selected_category = nil
        
        -- Weighted random selection of category
        local roll = math.random() * total_weight
        local accumulated = 0
        
        for category, data in pairs(self.categories) do
            if #data.objectives > 0 then
                accumulated = accumulated + data.weight
                
                if roll <= accumulated then
                    -- Check if category limit would be exceeded
                    if data.limit == nil or category_counts[category] < data.limit then
                        selected_category = category
                        break
                    end
                end
            end
        end
        
        -- Fallback if weighted selection fails
        if not selected_category then
            for category, data in pairs(self.categories) do
                if #data.objectives > 0 and (data.limit == nil or category_counts[category] < data.limit) then
                    selected_category = category
                    break
                end
            end
        end
        
        if selected_category then
            local category_objectives = self.categories[selected_category].objectives
            local selected_obj = category_objectives[math.random(1, #category_objectives)]
            table.insert(selected, selected_obj)
            category_counts[selected_category] = category_counts[selected_category] + 1
        end
    end
    
    print("CategorySystem: Successfully selected " .. #selected .. " objectives")
    for i, obj in ipairs(selected) do
        print("  [" .. i .. "] " .. obj.id .. " - " .. obj.title)
    end
    
    return selected
end

BingoCore.CategorySystem = CategorySystem

---Process description template by replacing ${count} with mode-appropriate values
---@param objective Objective
---@param mode "competitive"|"coop"
---@return string processed_description
local function processDescription(objective, mode)
    if not objective.description then
        return ""
    end
    
    local description = objective.description
    
    -- Handle ${count} placeholder
    if objective.count and objective.count[mode] then
        local count_value = objective.count[mode]
        local actual_count
        
        -- Handle range {min, max} or single value
        if type(count_value) == "table" then
            -- Range format: {min, max}
            actual_count = math.random(count_value[1], count_value[2])
        else
            -- Single value
            actual_count = count_value
        end
        
        -- Replace ${count} with actual value
        description = description:gsub("%${count}", tostring(actual_count))
    end
    
    return description
end

---Create processed objective with resolved description
---@param objective_data table Raw objective data
---@param mode "competitive"|"coop"
---@return table processed_objective
local function processObjective(objective_data, mode)
    local processed = {}
    
    -- Copy all fields
    for key, value in pairs(objective_data) do
        processed[key] = value
    end
    
    -- Process description template
    processed.description = processDescription(objective_data, mode)
    
    -- Store the actual count value used (for tracking)
    if objective_data.count and objective_data.count[mode] then
        local count_value = objective_data.count[mode]
        if type(count_value) == "table" then
            processed.actual_count = math.random(count_value[1], count_value[2])
        else
            processed.actual_count = count_value
        end
    end
    
    return processed
end

-- Export processor functions
BingoCore.ObjectiveProcessor = {
    processDescription = processDescription,
    processObjective = processObjective
}
