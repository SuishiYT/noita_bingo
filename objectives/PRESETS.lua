-- Example: Board Customization Presets
-- These are example configurations you can use by editing settings.lua

-- ===== PRESET 1: Balanced (Default) =====
-- Equal weight for all categories
--[[
category_weights = {
    combat = 1.0,
    deaths = 1.0,
    wandbuilding = 1.0,
    inventory = 1.0,
    exploration = 1.0,
    events_misc = 1.0
}
category_limits = {
    combat = nil,
    deaths = nil,
    wandbuilding = nil,
    inventory = nil,
    exploration = nil,
    events_misc = nil
}
--]]

-- ===== PRESET 2: Combat Focus =====
-- Weighted toward combat objectives
--[[
category_weights = {
    combat = 2.0,         -- Double combat
    deaths = 0.5,         -- Reduce deaths
    wandbuilding = 1.0,
    inventory = 1.0,
    exploration = 1.0,
    events_misc = 0.8     -- Slightly reduce events
}
category_limits = {
    combat = nil,         -- Unlimited combat
    deaths = 2,           -- Max 2 deaths
    wandbuilding = nil,
    inventory = nil,
    exploration = nil,
    events_misc = 3       -- Max 3 events
}
--]]

-- ===== PRESET 3: Exploration Adventure =====
-- Focus on exploration and discovery
--[[
category_weights = {
    combat = 1.2,         -- Increase combat slightly
    deaths = 0.5,         -- Reduce deaths
    wandbuilding = 1.0,
    inventory = 1.3,      -- More inventory management
    exploration = 2.0,    -- Heavy exploration
    events_misc = 1.5     -- More events/misc
}
category_limits = {
    combat = 4,
    deaths = 2,
    wandbuilding = 3,
    inventory = 4,
    exploration = nil,    -- Unlimited exploration
    events_misc = nil     -- Unlimited events
}
--]]

-- ===== PRESET 4: Wandbuilding Focus =====
-- Heavy focus on wand crafting and building
--[[
category_weights = {
    combat = 1.0,
    deaths = 0.3,         -- Minimal deaths
    wandbuilding = 2.5,   -- Heavy wandbuilding focus
    inventory = 1.5,      -- More inventory (wand materials)
    exploration = 1.0,
    events_misc = 0.8
}
category_limits = {
    combat = 3,
    deaths = 1,           -- Max 1 death objective
    wandbuilding = nil,   -- Unlimited wandbuilding
    inventory = nil,
    exploration = 3,
    events_misc = 2
}
--]]

-- ===== PRESET 5: Hard Challenge =====
-- Heavy on difficult objectives
--[[
category_weights = {
    combat = 1.8,         -- Increase combat (often hard)
    deaths = 1.5,         -- More death challenges
    wandbuilding = 1.5,   -- Complex wand building
    inventory = 1.0,
    exploration = 1.5,    -- Increase exploration (some hard)
    events_misc = 1.2
}
category_limits = {
    combat = nil,
    deaths = 3,           -- Up to 3 death objectives
    wandbuilding = nil,
    inventory = 2,
    exploration = nil,
    events_misc = nil
}
--]]

-- ===== PRESET 6: Speed Run Friendly =====
-- Quick objectives that can be done fast
--[[
category_weights = {
    combat = 1.5,         -- Combat can be quick
    deaths = 0.2,         -- Avoid death objectives (risky)
    wandbuilding = 0.5,   -- Less wandbuilding (slow)
    inventory = 1.5,      -- Inventory objectives (quick)
    exploration = 0.8,    -- Some exploration (medium speed)
    events_misc = 1.2     -- Events can be quick
}
category_limits = {
    combat = 5,
    deaths = 1,           -- Max 1 death objective
    wandbuilding = 2,     -- Limited wandbuilding
    inventory = nil,
    exploration = 3,
    events_misc = nil
}
--]]

-- ===== PRESET 7: No Deaths =====
-- Remove death objectives, focus on survival
--[[
category_weights = {
    combat = 1.5,
    deaths = 0.0,         -- No death objectives
    wandbuilding = 1.5,
    inventory = 1.5,
    exploration = 1.5,
    events_misc = 1.5
}
category_limits = {
    combat = nil,
    deaths = 0,           -- Explicitly forbid deaths
    wandbuilding = nil,
    inventory = nil,
    exploration = nil,
    events_misc = nil
}
--]]

-- ===== PRESET 8: Varied & Diverse =====
-- Maximum variety with hard limits on each category
--[[
category_weights = {
    combat = 1.0,
    deaths = 1.0,
    wandbuilding = 1.0,
    inventory = 1.0,
    exploration = 1.0,
    events_misc = 1.0
}
category_limits = {
    combat = 4,           -- 4 per category
    deaths = 4,
    wandbuilding = 4,
    inventory = 4,
    exploration = 4,
    events_misc = 4
}
--]]

-- ===== HOW TO USE =====
-- 1. Pick a preset above that matches your playstyle
-- 2. Copy the category_weights and category_limits
-- 3. Paste into settings.lua (replace the default ones)
-- 4. Reload the mod
-- 5. Generate a new board

-- ===== TIPS =====
-- - Weights don't have to add up to anything specific
-- - 0.5 = half as likely, 2.0 = twice as likely
-- - nil = no limit, any number = that's the maximum
-- - Mix and match weights and limits to customize
