-- Settings Preset Manager
-- Handles saving/loading game settings presets

---@class SettingsPresetManager
local SettingsPresetManager = {}
SettingsPresetManager.__index = SettingsPresetManager

function SettingsPresetManager.new()
    local self = setmetatable({}, SettingsPresetManager)
    
    self.presets = {}
    self.presets_directory = "mods/Noita Bingo/settings_presets/"
    
    -- Load all existing presets
    self:loadAllPresets()
    
    return self
end

---Load all preset files from directory
function SettingsPresetManager:loadAllPresets()
    -- TODO: Noita doesn't have directory listing, so we'll use a manifest file
    -- For now, just load default preset
    self.presets = {
        default = self:getDefaultSettings()
    }
end

---Get default settings template
---@return table
function SettingsPresetManager:getDefaultSettings()
    return {
        board_size = 5,
        category_limits = {
            luck = nil,
            bloodshed = nil,
            exploration = nil,
            magic = nil,
            items = nil,
            general = nil
        },
        enable_rewards = true,
        rewards_file = "default",
        timer_mode = "elapsed",
        timer_enabled = true,
        countdown_duration = 1800,
        reveal_countdown = true,
        reveal_countdown_duration = 3,
        rush_objective_count = 3
    }
end

---Save settings preset
---@param name string
---@param settings table
function SettingsPresetManager:savePreset(name, settings)
    -- Sanitize name
    name = name:gsub("[^%w_-]", "")
    
    if name == "" then
        name = "unnamed"
    end
    
    -- Store in memory
    self.presets[name] = settings
    
    -- Serialize to string
    local serialized = self:serializeSettings(settings)
    
    -- Save to mod settings (since Noita doesn't have easy file writing)
    ModSettingSet("noita_bingo.preset_" .. name, serialized)
    
    -- Update preset list
    self:updatePresetList()
end

---Load settings preset
---@param name string
---@return table|nil
function SettingsPresetManager:loadPreset(name)
    -- Check if in memory
    if self.presets[name] then
        return self.presets[name]
    end
    
    -- Try to load from mod settings
    local serialized = ModSettingGet("noita_bingo.preset_" .. name)
    if serialized and serialized ~= "" then
        local settings = self:deserializeSettings(serialized)
        self.presets[name] = settings
        return settings
    end
    
    return nil
end

---Rename preset
---@param old_name string
---@param new_name string
function SettingsPresetManager:renamePreset(old_name, new_name)
    local settings = self:loadPreset(old_name)
    if settings then
        -- Save with new name
        self:savePreset(new_name, settings)
        
        -- Delete old one
        self:deletePreset(old_name)
    end
end

---Delete preset
---@param name string
function SettingsPresetManager:deletePreset(name)
    -- Remove from memory
    self.presets[name] = nil
    
    -- Remove from mod settings
    ModSettingSet("noita_bingo.preset_" .. name, "")
    
    -- Update preset list
    self:updatePresetList()
end

---Get list of all preset names
---@return table
function SettingsPresetManager:getPresetNames()
    local names = {}
    for name, _ in pairs(self.presets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

---Update the preset list in mod settings
function SettingsPresetManager:updatePresetList()
    local names = self:getPresetNames()
    local list_str = table.concat(names, ",")
    ModSettingSet("noita_bingo.preset_list", list_str)
end

---Serialize settings to string
---@param settings table
---@return string
function SettingsPresetManager:serializeSettings(settings)
    -- Simple JSON-like serialization
    local parts = {}
    
    table.insert(parts, "board_size:" .. tostring(settings.board_size))
    
    -- Category limits
    local limits = {}
    for category, limit in pairs(settings.category_limits) do
        if limit then
            table.insert(limits, category .. "=" .. tostring(limit))
        else
            table.insert(limits, category .. "=nil")
        end
    end
    table.insert(parts, "limits:" .. table.concat(limits, ";"))
    
    table.insert(parts, "rewards:" .. (settings.enable_rewards and "1" or "0"))
    table.insert(parts, "rewards_file:" .. settings.rewards_file)
    table.insert(parts, "timer_mode:" .. settings.timer_mode)
    table.insert(parts, "timer_enabled:" .. (settings.timer_enabled and "1" or "0"))
    table.insert(parts, "countdown_duration:" .. tostring(settings.countdown_duration))
    table.insert(parts, "reveal_countdown:" .. (settings.reveal_countdown and "1" or "0"))
    table.insert(parts, "reveal_countdown_duration:" .. tostring(settings.reveal_countdown_duration))
    table.insert(parts, "rush_count:" .. tostring(settings.rush_objective_count))
    
    return table.concat(parts, "|")
end

---Deserialize settings from string
---@param str string
---@return table
function SettingsPresetManager:deserializeSettings(str)
    local settings = self:getDefaultSettings()
    
    for part in string.gmatch(str, "([^|]+)") do
        local key, value = string.match(part, "([^:]+):(.+)")
        
        if key == "board_size" then
            settings.board_size = tonumber(value) or 5
        elseif key == "limits" then
            for limit_pair in string.gmatch(value, "([^;]+)") do
                local category, limit = string.match(limit_pair, "([^=]+)=(.+)")
                if category and limit then
                    if limit == "nil" then
                        settings.category_limits[category] = nil
                    else
                        settings.category_limits[category] = tonumber(limit)
                    end
                end
            end
        elseif key == "rewards" then
            settings.enable_rewards = value == "1"
        elseif key == "rewards_file" then
            settings.rewards_file = value
        elseif key == "timer_mode" then
            settings.timer_mode = value
        elseif key == "timer_enabled" then
            settings.timer_enabled = value == "1"
        elseif key == "countdown_duration" then
            settings.countdown_duration = tonumber(value) or 1800
        elseif key == "reveal_countdown" then
            settings.reveal_countdown = value == "1"
        elseif key == "reveal_countdown_duration" then
            settings.reveal_countdown_duration = tonumber(value) or 3
        elseif key == "rush_count" then
            settings.rush_objective_count = tonumber(value) or 3
        end
    end
    
    return settings
end

BingoCore.SettingsPresetManager = SettingsPresetManager
