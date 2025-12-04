-- Multiplayer Synchronization
-- Handles board synchronization and multiplayer state management via evaisa.mp

---@class MultiplayerSync
local MultiplayerSync = {}
MultiplayerSync.__index = MultiplayerSync

function MultiplayerSync.new()
    local self = setmetatable({}, MultiplayerSync)
    
    self.is_host = false
    self.is_multiplayer = false
    self.players = {}
    self.player_id = ""
    self.host_id = ""
    self.lobby_code = nil
    
    -- Board state sync
    self.board_state_version = 0
    self.last_sync_time = 0
    self.sync_interval = 60 -- Sync every 60 frames (1 second at 60 FPS)
    
    return self
end

---Check if evaisa.mp framework is available and we're in a lobby
---@return boolean
function MultiplayerSync:isFrameworkAvailable()
    return steamutils ~= nil and steam ~= nil and self.lobby_code ~= nil
end

---Initialize multiplayer with lobby
---@param lobby any
function MultiplayerSync:initialize(lobby)
    if not lobby then
        self.is_multiplayer = false
        return
    end
    
    self.lobby_code = lobby
    self.is_multiplayer = true
    
    -- Get our Steam ID as player ID
    if steam and steam_utils then
        self.player_id = tostring(steam_utils.getSteamID())
    end
    
    -- Check if we're the host
    if steam and steam.matchmaking then
        local owner = steam.matchmaking.getLobbyOwner(lobby)
        self.is_host = (tostring(owner) == self.player_id)
        self.host_id = tostring(owner)
    end
    
    print("Bingo Sync: Initialized multiplayer - Host: " .. tostring(self.is_host))
end

---Clean up multiplayer session
function MultiplayerSync:cleanup()
    self.is_multiplayer = false
    self.lobby_code = nil
    self.players = {}
    self.is_host = false
    self.player_id = ""
    self.host_id = ""
    print("Bingo Sync: Cleaned up multiplayer session")
end

---Get lobby member data
function MultiplayerSync:updatePlayers()
    if not self:isFrameworkAvailable() then
        return
    end
    
    local members = steamutils.getLobbyMembers(self.lobby_code, true, false) or {}
    
    for _, member in ipairs(members) do
        local steam_id = tostring(member)
        if not self.players[steam_id] then
            local name = steamutils.getTranslatedPersonaName(member)
            self.players[steam_id] = {
                id = steam_id,
                name = name,
                score = 0,
                cleared = {},
                joined_at = GameGetFrameNum()
            }
            print("Bingo Sync: Added player " .. name)
        end
    end
end

---Add a player to the session
---@param player_id string
---@param player_name string
function MultiplayerSync:addPlayer(player_id, player_name)
    self.players[player_id] = {
        id = player_id,
        name = player_name,
        score = 0,
        cleared = {},
        joined_at = GameGetFrameNum()
    }
end

---Remove a player from the session
---@param player_id string
function MultiplayerSync:removePlayer(player_id)
    self.players[player_id] = nil
end

---Sync board state to other players (host only)
---@param board_data table
function MultiplayerSync:syncBoardState(board_data)
    if not self.is_multiplayer or not self.is_host then
        return
    end
    
    self.board_state_version = self.board_state_version + 1
    
    -- Store in lobby data for persistence
    if steam and steam.matchmaking and steamutils then
        local serialized_board = smallfolk.dumps(board_data)
        steam_utils.TrySetLobbyData(self.lobby_code, "board_data", serialized_board)
        steam_utils.TrySetLobbyData(self.lobby_code, "board_version", tostring(self.board_state_version))
    end
    
    local message = {
        version = self.board_state_version,
        board = board_data,
        timestamp = GameGetFrameNum()
    }
    
    if BingoMultiplayer.Network then
        BingoMultiplayer.Network:broadcast("board_state", message)
    end
end

---Sync a cleared square to other players
---@param row number
---@param col number
---@param player_id string
function MultiplayerSync:syncSquareClear(row, col, player_id)
    if not self.is_multiplayer then
        return
    end
    
    local message = {
        row = row,
        col = col,
        player_id = player_id or self.player_id,
        timestamp = GameGetFrameNum()
    }
    
    if BingoMultiplayer.Network then
        BingoMultiplayer.Network:broadcast("square_clear", message)
    end
end

---Broadcast a win
---@param player_id string|nil
function MultiplayerSync:broadcastWin(player_id)
    if not self.is_multiplayer then
        return
    end
    
    local message = {
        player_id = player_id or self.player_id,
        timestamp = GameGetFrameNum()
    }
    
    self:sendToOtherPlayers("game_win", message)
end

---Handle received messages
---@param event string
---@param message any
---@param user any
function MultiplayerSync:handleMessage(event, message, user)
    local from_player_id = tostring(user)
    
    if event == "board_state" and not self.is_host then
        -- Non-hosts receive board state from host
        if BingoBoardState and BingoBoardState.loadBoard then
            BingoBoardState.loadBoard(message.board)
            self.board_state_version = message.version
            print("Bingo Sync: Received board state update")
        end
    elseif event == "square_clear" then
        -- All players receive square clear updates
        if BingoBoardState and BingoBoardState.clearSquare then
            BingoBoardState.clearSquare(message.row, message.col, from_player_id)
            print("Bingo Sync: Player " .. from_player_id .. " cleared square " .. message.row .. "," .. message.col)
        end
    elseif event == "game_win" then
        -- Handle game win announcement
        local winner_name = self.players[message.player_id] and self.players[message.player_id].name or message.player_id
        GamePrint("Game won by " .. winner_name .. "!")
        print("Bingo Sync: Game won by " .. winner_name)
    end
end

---Update synchronization (called each frame)
function MultiplayerSync:update()
    if not self.is_multiplayer then
        return
    end
    
    self.last_sync_time = self.last_sync_time + 1
    
    if self.last_sync_time >= self.sync_interval then
        -- Update player list periodically
        self:updatePlayers()
        self.last_sync_time = 0
    end
end

BingoMultiplayer.Sync = MultiplayerSync
