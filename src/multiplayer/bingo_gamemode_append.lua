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
        
        -- Bingo is now always enabled since it's the active gamemode
        -- No need to check for a toggle setting anymore
        local bingo_always_enabled = true
        
        if BingoMultiplayer and BingoMultiplayer.onLobbyRefresh then
            BingoMultiplayer.onLobbyRefresh(lobby)
        end
    end,
    
    -- Called when player enters lobby
    enter = function(lobby)
        print("Bingo gamemode: Entered lobby " .. tostring(lobby))
        
        -- Bingo is always active since it's the selected gamemode
        GamePrint("Bingo: Gamemode is ACTIVE!")
        if BingoMultiplayer and BingoMultiplayer.onLobbyEnter then
            BingoMultiplayer.onLobbyEnter(lobby)
        end
    end,
    
    -- Called when game starts for non-spectators
    start = function(lobby)
        print("Bingo gamemode: Game started")
        
        -- Bingo is always active since it's the selected gamemode
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
if gamemodes then
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
else
    print("ERROR: gamemodes table not found! Cannot register Bingo gamemode")
    GamePrint("ERROR: Bingo gamemode registration failed")
end