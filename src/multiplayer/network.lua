-- Network Module
-- Handles network communication for multiplayer via evaisa.mp framework

---@class Network
local Network = {}
Network.__index = Network

function Network.new()
    local self = setmetatable({}, Network)
    
    self.lobby_code = nil
    self.is_connected = false
    self.message_callbacks = {}
    
    return self
end

---Check if evaisa.mp framework is available
---@return boolean
function Network:isFrameworkAvailable()
    return steamutils ~= nil and steam ~= nil and lobby_code ~= nil
end

---Get connection status
---@return string
function Network:getStatus()
    if not self:isFrameworkAvailable() then
        return "framework_unavailable"
    end
    
    if self.lobby_code and self.is_connected then
        return "connected"
    else
        return "disconnected"
    end
end

---Send a message over the network
---@param message_type string
---@param payload table
---@param recipient_id? string Optional specific recipient
function Network:send(message_type, payload, recipient_id)
    if not self:isFrameworkAvailable() then
        print("Bingo Network: evaisa.mp framework not available")
        return false
    end
    
    local message_data = {message_type, payload, GameGetFrameNum()}
    
    if recipient_id then
        -- Send to specific player (if supported by framework)
        steamutils.sendMessage(self.lobby_code, message_data)
    else
        -- Broadcast to all players
        steamutils.sendMessage(self.lobby_code, message_data)
    end
    
    return true
end

---Broadcast a message to all connected players
---@param message_type string
---@param payload table
function Network:broadcast(message_type, payload)
    return self:send(message_type, payload)
end

---Register a callback for specific message types
---@param message_type string
---@param callback function
function Network:onMessage(message_type, callback)
    if not self.message_callbacks[message_type] then
        self.message_callbacks[message_type] = {}
    end
    table.insert(self.message_callbacks[message_type], callback)
end

---Internal: Handle received messages (called by multiplayer system)
---@param lobby any
---@param event string
---@param message any
---@param user any
function Network:_handleMessage(lobby, event, message, user)
    local callbacks = self.message_callbacks[event]
    if callbacks then
        for _, callback in ipairs(callbacks) do
            callback(event, message, user)
        end
    end
end

---Set the current lobby (internal use)
---@param lobby any
function Network:_setLobby(lobby)
    self.lobby_code = lobby
    self.is_connected = (lobby ~= nil)
end

---Initialize network system (called when joining/creating lobby)
function Network:initialize(lobby)
    self:_setLobby(lobby)
    print("Bingo Network: Initialized for lobby " .. tostring(lobby))
end

---Clean up network system (called when leaving lobby)
function Network:cleanup()
    self.lobby_code = nil
    self.is_connected = false
    self.message_callbacks = {}
    print("Bingo Network: Cleaned up")
end

BingoMultiplayer.Network = Network
