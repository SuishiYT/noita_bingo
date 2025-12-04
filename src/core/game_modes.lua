-- Game mode implementations
-- Traditional, Lockout, Blackout, Rush

---@class GameMode
---@field board BingoBoard
---@field is_multiplayer boolean
---@field completed boolean
---@field start_time number
local GameMode = {}
GameMode.__index = GameMode

---Create a new game mode instance
---@param board BingoBoard
---@param is_multiplayer boolean
---@return GameMode
function GameMode.new(board, is_multiplayer)
    local self = setmetatable({}, GameMode)
    
    self.board = board
    self.is_multiplayer = is_multiplayer or false
    self.completed = false
    self.start_time = GameGetFrameNum()
    
    return self
end

---Update game state
---@param dt number
function GameMode:update(dt)
    if self.board:checkWin() then
        self.completed = true
        self:onWin()
    end
end

---Handle input (can be overridden)
---@param key string
function GameMode:handleInput(key)
    -- Override in subclasses
end

---Called when game is won (can be overridden)
function GameMode:onWin()
    print("Game won!")
end

BingoCore.GameMode = GameMode

---@class TraditionalBingo : GameMode
local TraditionalBingo = setmetatable({}, { __index = GameMode })
TraditionalBingo.__index = TraditionalBingo

---Create traditional bingo game
---@param objectives table
---@param is_multiplayer boolean
---@return TraditionalBingo
function TraditionalBingo.new(objectives, is_multiplayer)
    local board = BingoCore.BingoBoard.new(objectives, 5, "traditional")
    local self = setmetatable(GameMode.new(board, is_multiplayer), TraditionalBingo)
    return self
end

function TraditionalBingo:onWin()
    print("Traditional Bingo: Game Won!")
    if self.is_multiplayer then
        BingoMultiplayer:broadcastWin()
    end
end

BingoCore.TraditionalBingo = TraditionalBingo

---@class Lockout : GameMode
local Lockout = setmetatable({}, { __index = GameMode })
Lockout.__index = Lockout

---Create lockout game (multiplayer only)
---@param objectives table
---@return Lockout
function Lockout.new(objectives)
    local board = BingoCore.BingoBoard.new(objectives, 5, "lockout")
    local self = setmetatable(GameMode.new(board, true), Lockout)
    
    self.player_scores = {} -- Track scores by player
    
    return self
end

function Lockout:recordClear(player_id, row, col)
    if not self.player_scores[player_id] then
        self.player_scores[player_id] = 0
    end
    
    if not self.board:isLocked(row, col) then
        self.board:setClearedAt(row, col, true)
        self.player_scores[player_id] = self.player_scores[player_id] + 1
        
        -- Broadcast to other players
        BingoMultiplayer:broadcastClear(player_id, row, col)
    end
end

function Lockout:onWin()
    print("Lockout: Someone achieved bingo!")
    BingoMultiplayer:broadcastWin()
end

BingoCore.Lockout = Lockout

---@class Blackout : GameMode
local Blackout = setmetatable({}, { __index = GameMode })
Blackout.__index = Blackout

---Create blackout game (solo only)
---@param objectives table
---@return Blackout
function Blackout.new(objectives)
    local board = BingoCore.BingoBoard.new(objectives, 5, "blackout")
    local self = setmetatable(GameMode.new(board, false), Blackout)
    return self
end

function Blackout:onWin()
    print("Blackout: All squares cleared!")
end

BingoCore.Blackout = Blackout

---@class Rush : GameMode
local Rush = setmetatable({}, { __index = GameMode })
Rush.__index = Rush

---Create rush game (solo only)
---@param objectives table
---@param time_limit number
---@return Rush
function Rush.new(objectives, time_limit)
    local board = BingoCore.BingoBoard.new(objectives, 5, "rush")
    local self = setmetatable(GameMode.new(board, false), Rush)
    
    self.time_limit = time_limit or 600 -- 10 minutes default
    self.time_remaining = self.time_limit
    
    return self
end

function Rush:update(dt)
    self.time_remaining = self.time_remaining - dt
    
    GameMode.update(self, dt)
    
    if self.time_remaining <= 0 and not self.completed then
        self.completed = true
        self:onTimeOut()
    end
end

function Rush:onTimeOut()
    print("Rush: Time's up!")
end

function Rush:onWin()
    print(string.format("Rush: Bingo achieved in %.2f seconds!", self.time_limit - self.time_remaining))
end

BingoCore.Rush = Rush
