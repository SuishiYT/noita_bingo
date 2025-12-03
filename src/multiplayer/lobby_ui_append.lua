-- Lobby UI modification to add Bingo gamemode selection
-- This file is appended to evaisa.mp's lobby_ui.lua

print("Bingo: Lobby UI append file loaded")

-- Add bingo as a lobby setting that can be toggled
-- This approach adds it to the existing gamemode settings system

-- Try to add our setting when the lobby is being configured
local function addBingoSetting()
    -- Check if we have access to the lobby and steam functions
    if not steam or not steam.matchmaking then
        return
    end
    
    -- Get current lobby (this might be a global variable in evaisa.mp)
    local current_lobby = lobby or _G.lobby or steamutils.lobby
    if not current_lobby then
        return
    end
    
    print("Bingo: Adding bingo setting to lobby")
    
    -- Set default bingo state if not already set
    local current_bingo_state = steam.matchmaking.getLobbyData(current_lobby, "bingo_enabled")
    if current_bingo_state == nil or current_bingo_state == "" then
        steam.matchmaking.setLobbyData(current_lobby, "bingo_enabled", "false")
        print("Bingo: Set default bingo state to false")
    end
end

-- Try to hook into various possible entry points
if lobby_settings_update then
    local original_update = lobby_settings_update
    lobby_settings_update = function(...)
        original_update(...)
        addBingoSetting()
    end
end

if lobby_created then
    local original_created = lobby_created
    lobby_created = function(...)
        original_created(...)
        addBingoSetting()
    end
end

-- Fallback: try to add setting immediately if we have access
if steam and steam.matchmaking and (lobby or _G.lobby) then
    addBingoSetting()
end

print("Bingo: Lobby UI hooks installed")