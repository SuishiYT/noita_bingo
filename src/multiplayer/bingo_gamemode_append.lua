-- Noita Bingo Gamemode Append File
-- This file is appended to evaisa.mp's gamemodes.lua via ModLuaFileAppend

-- Debug: Check what systems are available
print("Bingo Gamemode: Checking available systems...")
print("BingoMultiplayer available: " .. tostring(BingoMultiplayer ~= nil))
print("menu_system available: " .. tostring(menu_system ~= nil))
print("BingoBoardState available: " .. tostring(BingoBoardState ~= nil))
print("BingoCore available: " .. tostring(BingoCore ~= nil))

local BingoGamemode = {
    id = "noita_bingo",
    name = "Noita Bingo", -- Use plain text instead of translation for now
    version = 1,
    author = "Noita Bingo Mod", 
    description = "A customizable bingo experience with multiple game modes and difficulty settings",
    enabled = true, -- Explicitly mark as enabled
    
    -- Required fields for evaisa.mp compatibility
    lobby_type = "gamemode", -- Specify as gamemode type
    max_players = 8, -- Support up to 8 players
    min_players = 1, -- Allow solo testing
    
    -- Lobby settings that appear in the lobby configuration
    settings = {
        {
            id = "bingo_enabled", 
            name = "Enable Bingo",
            type = "bool",
            default = false,
        },
        {
            id = "board_size", 
            name = "Board Size",
            type = "select",
            default = "5x5",
            options = {"3x3", "4x4", "5x5", "6x6"},
        },
        {
            id = "game_mode",
            name = "Game Mode", 
            type = "select",
            default = "traditional",
            options = {"traditional", "blackout", "lockout", "rush"},
        },
        {
            id = "difficulty",
            name = "Difficulty",
            type = "select", 
            default = "normal",
            options = {"easy", "normal", "hard", "extreme"},
        },
        {
            id = "seed",
            name = "Seed",
            type = "string",
            default = "",
        },
    },
    
    -- Default lobby data when created
    default_data = {
        board_generated = "false",
        board_data = "",
        game_started = "false",
        winner = "",
    },
    
    -- Called when lobby settings are changed
    refresh = function(lobby)
        print("Bingo gamemode: Lobby refreshed")
        
        -- Check if bingo should be enabled
        local bingo_should_be_enabled = false
        if steam and steam.matchmaking and steam.matchmaking.getLobbyData then
            bingo_should_be_enabled = steam.matchmaking.getLobbyData(lobby, "setting_bingo_enabled") == "true"
        end
        
        -- Test if gamemode functionality is actually working
        local gamemode_actually_active = false
        
        -- Test 1: Check if BingoMultiplayer exists and is loaded
        local bingo_multiplayer_loaded = BingoMultiplayer ~= nil
        
        -- Test 2: Check if menu system exists 
        local menu_system_loaded = menu_system ~= nil
        
        -- Test 3: Check if core bingo systems are available
        local bingo_core_loaded = BingoBoardState ~= nil and BingoCore ~= nil
        
        -- Actually load and enable bingo systems when toggled on
        if bingo_should_be_enabled then
            print("Bingo: Attempting to load full bingo systems...")
            
            -- Try to load the core bingo mod files
            local systems_loaded = 0
            local total_systems = 4
            
            local failed_systems = {}
            
            -- Load core objective system
            if not BingoCore or not BingoCore.Objective then
                local success = pcall(function()
                    dofile("mods/noita_bingo/src/core/objective.lua")
                end)
                if success then
                    systems_loaded = systems_loaded + 1
                    print("Bingo: Loaded objective system")
                else
                    table.insert(failed_systems, "Objectives")
                    print("Bingo: FAILED to load objective system")
                end
            else
                systems_loaded = systems_loaded + 1
            end
            
            -- Load bingo board system  
            if not BingoCore or not BingoCore.BingoBoard then
                local success = pcall(function()
                    dofile("mods/noita_bingo/src/core/bingo_board.lua")
                end)
                if success then
                    systems_loaded = systems_loaded + 1
                    print("Bingo: Loaded bingo board system")
                else
                    table.insert(failed_systems, "BingoBoard")
                    print("Bingo: FAILED to load bingo board system")
                end
            else
                systems_loaded = systems_loaded + 1
            end
            
            -- Load UI system
            if not BingoUI or not BingoUI.BingoBoardGUI then
                local success = pcall(function()
                    dofile("mods/noita_bingo/src/ui/bingo_board_gui.lua")
                end)
                if success then
                    systems_loaded = systems_loaded + 1  
                    print("Bingo: Loaded UI system")
                else
                    table.insert(failed_systems, "UI")
                    print("Bingo: FAILED to load UI system")
                end
            else
                systems_loaded = systems_loaded + 1
            end
            
            -- Load multiplayer integration
            if not BingoMultiplayer or not BingoMultiplayer.isFrameworkAvailable then
                local success = pcall(function()
                    dofile("mods/noita_bingo/src/multiplayer/integration.lua")
                end)
                if success then
                    systems_loaded = systems_loaded + 1
                    print("Bingo: Loaded multiplayer integration")
                else
                    table.insert(failed_systems, "Multiplayer")
                    print("Bingo: FAILED to load multiplayer integration")
                end
            else
                systems_loaded = systems_loaded + 1
            end
            
            gamemode_actually_active = (systems_loaded == total_systems)
            
            if gamemode_actually_active then
                GamePrint("Bingo: FULLY LOADED (" .. systems_loaded .. "/" .. total_systems .. ")")
                print("Bingo: All systems loaded successfully")
            else
                GamePrint("Bingo: PARTIAL (" .. systems_loaded .. "/" .. total_systems .. ") Missing: " .. table.concat(failed_systems, ", "))
                print("Bingo: Failed systems: " .. table.concat(failed_systems, ", "))
            end
        else
            gamemode_actually_active = false
            GamePrint("Bingo: DISABLED")
        end
        
        -- Regenerate board if needed
        if BingoMultiplayer and BingoMultiplayer.onLobbyRefresh then
            BingoMultiplayer.onLobbyRefresh(lobby)
        end
    end,
    
    -- Called when player enters lobby
    enter = function(lobby)
        print("Bingo gamemode: Entered lobby " .. tostring(lobby))
        
        -- Check if bingo is enabled via gamemode settings
        local bingo_enabled = false
        if steam and steam.matchmaking and steam.matchmaking.getLobbyData then
            bingo_enabled = steam.matchmaking.getLobbyData(lobby, "setting_bingo_enabled") == "true"
        end
        
        if bingo_enabled then
            GamePrint("Bingo: Gamemode is ACTIVE!")
            if BingoMultiplayer and BingoMultiplayer.onLobbyEnter then
                BingoMultiplayer.onLobbyEnter(lobby)
            end
        else
            GamePrint("Bingo: Gamemode is INACTIVE (enable in lobby settings)")
        end
    end,
    
    -- Called when game starts for non-spectators
    start = function(lobby)
        print("Bingo gamemode: Game started")
        
        -- Check if bingo is enabled via gamemode settings
        local bingo_enabled = false
        if steam and steam.matchmaking and steam.matchmaking.getLobbyData then
            bingo_enabled = steam.matchmaking.getLobbyData(lobby, "setting_bingo_enabled") == "true"
        end
        
        if bingo_enabled then
            GamePrint("Bingo: Game starting!")
            GamePrint("Bingo: Opening bingo board...")
            
            -- Try to open the bingo menu automatically
            if menu_system then
                menu_system:open()
                GamePrint("Bingo: Menu opened!")
            else
                GamePrint("Bingo: Menu system not available - use F6 to open")
            end
            
            if BingoMultiplayer and BingoMultiplayer.onGameStart then
                BingoMultiplayer.onGameStart(lobby)
            end
        else
            GamePrint("Bingo: Regular gameplay (bingo disabled)")
        end
    end,
    
    -- Called when game starts for spectators
    spectate = function(lobby) 
        print("Bingo gamemode: Spectating")
        if BingoMultiplayer and BingoMultiplayer.onSpectate then
            BingoMultiplayer.onSpectate(lobby)
        end
    end,
    
    -- Called every frame during game
    update = function(lobby)
        -- Only print this once to avoid spam
        if not BingoGamemode._update_logged then
            GamePrint("Bingo: Update loop active")
            BingoGamemode._update_logged = true
        end
        
        if BingoMultiplayer and BingoMultiplayer.onUpdate then
            BingoMultiplayer.onUpdate(lobby)
        end
    end,
    
    -- Called at end of every frame during game
    late_update = function(lobby)
        if BingoMultiplayer and BingoMultiplayer.onLateUpdate then
            BingoMultiplayer.onLateUpdate(lobby)
        end
    end,
    
    -- Called when local player leaves lobby
    leave = function(lobby)
        print("Bingo gamemode: Left lobby")
        if BingoMultiplayer and BingoMultiplayer.onLobbyLeave then
            BingoMultiplayer.onLobbyLeave(lobby)
        end
    end,
    
    -- Called when a player disconnects
    disconnected = function(lobby, user)
        print("Bingo gamemode: Player disconnected - " .. tostring(user))
        if BingoMultiplayer and BingoMultiplayer.onPlayerDisconnected then
            BingoMultiplayer.onPlayerDisconnected(lobby, user)
        end
    end,
    
    -- Called when receiving network messages
    received = function(lobby, event, message, user)
        if BingoMultiplayer and BingoMultiplayer.onMessageReceived then
            BingoMultiplayer.onMessageReceived(lobby, event, message, user)
        end
    end,
    
    -- Optional: Called when projectiles are fired
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        if BingoMultiplayer and BingoMultiplayer.onProjectileFired then
            BingoMultiplayer.onProjectileFired(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        end
    end,
    
    -- Optional: Called after projectiles are fired
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        if BingoMultiplayer and BingoMultiplayer.onProjectileFiredPost then
            BingoMultiplayer.onProjectileFiredPost(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message, unknown1, multicast_index, unknown3)
        end
    end,
}

-- Debug information
print("Bingo Gamemode Append: Loaded gamemode definition with ID: " .. BingoGamemode.id)
print("Bingo Gamemode Append: Name: " .. BingoGamemode.name)
print("Bingo Gamemode Append: Settings count: " .. #BingoGamemode.settings)

-- Add to the gamemodes table (this is the key part that was missing!)
table.insert(gamemodes, BingoGamemode)
print("Bingo Gamemode Append: Added to gamemodes table")
print("Bingo Gamemode Append: Total gamemodes now: " .. #gamemodes)

-- Debug: Print all gamemodes to see what's in the table
print("=== All Gamemodes ===")
for i, gm in ipairs(gamemodes) do
    print("  [" .. i .. "] " .. (gm.id or "no_id") .. " - " .. (gm.name or "no_name") .. " (enabled: " .. tostring(gm.enabled) .. ")")
end
print("=== End Gamemodes ===")

-- Force a GamePrint so we can see this in the game
GamePrint("Bingo: Gamemode registered! Total: " .. #gamemodes)