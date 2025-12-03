-- Settings Configuration
-- Handles user settings, hotkeys, and preferences

---@class Settings
local Settings = {}
Settings.__index = Settings

function Settings.new()
    local self = setmetatable({}, Settings)
    
    -- Default settings
    self.data = {
        -- Display settings
        display_mode = "large",
        decouple_boards = false,
        
        -- Game settings
        game_type = "traditional",
        board_size = 5,
        enable_rewards = true,
        
        -- Hotkeys
        hotkeys = {
            full_screen = "f6",
            large = "f7",
            small = "f8",
            hidden = "f9",
            toggle_rewards = "f10"
        },
        
        -- Category weights (0.0 to 2.0)
        category_weights = {
            bloodshed = 1.0,
            deaths = 1.0,
            wandbuilding = 1.0,
            inventory = 1.0,
            exploration = 1.0,
            events_misc = 1.0
        },
        
        -- Category limits (nil = no limit)
        category_limits = {
            bloodshed = nil,
            deaths = nil,
            wandbuilding = nil,
            inventory = nil,
            exploration = nil,
            events_misc = nil
        },
        
        -- Sound and visual settings
        volume = 1.0,
        animate_board_moves = true,
        board_animation_speed = 0.3
    }
    
    return self
end

---Load settings from file
---@param file_path string
function Settings:loadFromFile(file_path)
    if love.filesystem.getInfo(file_path) then
        local content = love.filesystem.read(file_path)
        if content then
            -- Simple Lua table parsing (use a proper Lua loader if needed)
            local loaded_settings = loadstring(content)
            if loaded_settings then
                self.data = loaded_settings()
            end
        end
    end
end

---Save settings to file
---@param file_path string
function Settings:saveToFile(file_path)
    -- Serialize settings to Lua table format
    local content = "return " .. self:serialize(self.data)
    
    love.filesystem.write(file_path, content)
end

---Serialize a table to Lua format
---@param tbl table
---@param indent number
---@return string
function Settings:serialize(tbl, indent)
    indent = indent or 0
    local indent_str = string.rep("  ", indent)
    local next_indent_str = string.rep("  ", indent + 1)
    
    local result = "{\n"
    
    for key, value in pairs(tbl) do
        result = result .. next_indent_str .. key .. " = "
        
        if type(value) == "table" then
            result = result .. self:serialize(value, indent + 1) .. ",\n"
        elseif type(value) == "string" then
            result = result .. string.format("%q", value) .. ",\n"
        elseif type(value) == "boolean" then
            result = result .. tostring(value) .. ",\n"
        elseif type(value) == "number" then
            result = result .. tostring(value) .. ",\n"
        end
    end
    
    result = result .. indent_str .. "}"
    return result
end

---Get a setting value
---@param key string
---@param default any
---@return any
function Settings:get(key, default)
    if self.data[key] ~= nil then
        return self.data[key]
    end
    return default
end

---Set a setting value
---@param key string
---@param value any
function Settings:set(key, value)
    self.data[key] = value
end

BingoConfig.Settings = Settings
