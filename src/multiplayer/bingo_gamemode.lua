-- Noita Bingo Gamemode for evaisa.mp framework
-- This integrates the bingo mod with the evaisa.mp multiplayer system

local bingo_gamemode = {
    id = "noita_bingo",
    name = "$mp_gamemode_bingo", -- Will be translated
    version = 1,
    author = "Noita Bingo Mod", 
    description = "$mp_gamemode_bingo_description",
    enabled = true, -- Explicitly mark as enabled
    type = "gamemode", -- Explicitly mark as gamemode type
    category = "competitive", -- Category for lobby filtering
    
    -- Required fields for evaisa.mp compatibility
    lobby_type = "public", -- Allow public lobbies
    max_players = 8, -- Support up to 8 players
    min_players = 1, -- Allow solo testing
    
    -- Lobby settings that appear in the lobby configuration
    settings = {
        {
            id = "board_size", 
            name = "$bingo_setting_board_size",
            type = "select",
            default = "5x5",
            options = {"3x3", "4x4", "5x5", "6x6"},
        },
        {
            id = "game_mode",
            name = "$bingo_setting_game_mode", 
            type = "select",
            default = "traditional",
            options = {"traditional", "blackout", "lockout", "rush"},
        },
        {
            id = "difficulty",
            name = "$bingo_setting_difficulty",
            type = "select", 
            default = "normal",
            options = {"easy", "normal", "hard", "extreme"},
        },
        {
            id = "seed",
            name = "$bingo_setting_seed",
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
        -- Regenerate board if needed
        if BingoMultiplayer and BingoMultiplayer.onLobbyRefresh then
            BingoMultiplayer.onLobbyRefresh(lobby)
        end
    end,
    
    -- Called when player enters lobby
    enter = function(lobby)
        print("Bingo gamemode: Entered lobby " .. tostring(lobby))
        GamePrint("Bingo: Entered multiplayer lobby!")
        if BingoMultiplayer and BingoMultiplayer.onLobbyEnter then
            BingoMultiplayer.onLobbyEnter(lobby)
        end
    end,
    
    -- Called when game starts for non-spectators
    start = function(lobby)
        print("Bingo gamemode: Game started")
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
print("Bingo Gamemode: Loaded gamemode definition with ID: " .. bingo_gamemode.id)
print("Bingo Gamemode: Name: " .. bingo_gamemode.name)
print("Bingo Gamemode: Settings count: " .. #bingo_gamemode.settings)
print("Bingo Gamemode: Type: " .. tostring(bingo_gamemode.type))
print("Bingo Gamemode: Enabled: " .. tostring(bingo_gamemode.enabled))

return bingo_gamemode