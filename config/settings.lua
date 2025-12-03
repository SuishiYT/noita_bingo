-- Default Settings Configuration for Noita Bingo Mod
-- Place this in: mods/noita_bingo/config/settings.lua
--
-- You can customize any settings below to your preference.
-- Comments show default/recommended values.

return {
    -- ===== DISPLAY SETTINGS =====
    
    -- Current display mode: "large", "small", "full_screen", "hidden"
    display_mode = "large",
    
    -- When false: Large and Small boards share position (coupled)
    -- When true: Large and Small boards have separate positions (decoupled)
    decouple_boards = false,
    
    -- ===== GAME SETTINGS =====
    
    -- Game type: "traditional", "lockout", "blackout", "rush"
    game_type = "traditional",
    
    -- Board size (currently only 5x5 supported)
    board_size = 5,
    
    -- Enable/disable objective rewards for completed squares
    enable_rewards = true,
    
    -- ===== HOTKEY BINDINGS =====
    
    -- Customize hotkeys for display modes
    -- Valid keys: f1-f12, a-z, 0-9, tab, return, escape, space, up, down, left, right
    hotkeys = {
        full_screen = "f6",       -- Switch to full screen mode
        large = "f7",             -- Switch to large board
        small = "f8",             -- Switch to small board
        hidden = "f9",            -- Hide/show board (toggle)
        toggle_rewards = "f10"    -- Toggle rewards on/off
    },
    
    -- ===== CATEGORY WEIGHTS =====
    
    -- Weight for each objective category (0.0 to 2.0)
    -- Higher weight = more likely to appear on board
    -- Default is 1.0 (normal probability)
    -- Examples: 0.5 = half as likely, 1.5 = 50% more likely
    category_weights = {
        luck = 1.0,
        bloodshed = 1.0,
        exploration = 1.0,
        magic = 1.0,
        items = 1.0,
        general = 1.0
    },
    
    -- ===== CATEGORY LIMITS =====
    
    -- Maximum number of objectives from each category on the board
    -- nil = no limit, any number = limit to that count
    -- Useful for board diversity
    category_limits = {
        luck = nil,          -- No limit (comment out or set to number)
        bloodshed = nil,
        exploration = nil,
        magic = nil,
        items = nil,
        general = nil
    },
    
    -- ===== VISUAL & AUDIO SETTINGS =====
    
    -- Master volume (0.0 to 1.0)
    volume = 1.0,
    
    -- Enable smooth board movement animations
    animate_board_moves = true,
    
    -- Animation speed (0.1 = slow, 0.5 = normal, 1.0+ = fast)
    -- Lower values for slower computers
    board_animation_speed = 0.3
}
