-- Game State class
-- Manages the overall game state and progression

---@class Game
---@field board BingoBoard
---@field objectives table<Objective>
---@field mode string
---@field size number
---@field enable_rewards boolean
---@field elapsed_time number
---@field is_multiplayer boolean
local Game = {}
Game.__index = Game

---Create a new game
---@param config table
---@return Game
function Game.new(config)
    local self = setmetatable({}, Game)
    
    config = config or {}
    
    -- Store configuration
    self.size = config.size or 5
    self.mode = config.mode or "traditional"
    self.enable_rewards = config.enable_rewards ~= false
    self.is_multiplayer = config.is_multiplayer or false
    
    -- Create board with objectives
    self.objectives = config.objectives or {}
    self.board = BingoCore.BingoBoard.new(self.objectives, self.size, self.mode)
    
    -- Game state
    self.elapsed_time = 0
    self.is_paused = false
    self.is_finished = false
    self.winner = nil
    
    -- Rush mode specific
    if self.mode == "rush" then
        self.rush_completed_count = 0
        self.rush_completed_objectives = {}
    end
    
    -- Blackout mode specific
    if self.mode == "blackout" then
        self.blackout_completed_time = nil
    end
    
    return self
end

---Update game state (called every frame)
---@param dt number
function Game:update(dt)
    if self.is_paused or self.is_finished then
        return
    end
    
    self.elapsed_time = self.elapsed_time + dt
end

---Check if the current game mode is won
---@return boolean
function Game:isWon()
    if self.is_finished then
        return true
    end
    
    if self.mode == "traditional" then
        return self:checkTraditionalWin()
    elseif self.mode == "blackout" then
        return self:checkBlackoutWin()
    elseif self.mode == "lockout" then
        return self:checkLockoutWin()
    elseif self.mode == "rush" then
        return self:checkRushWin()
    end
    
    return false
end

---Check if traditional bingo (5 in a row) is won
---@return boolean
function Game:checkTraditionalWin()
    local size = self.board.size
    
    -- Check rows
    for row = 1, size do
        local all_cleared = true
        for col = 1, size do
            local index = self.board:getIndex(row, col)
            if not self.board.cleared[index] then
                all_cleared = false
                break
            end
        end
        if all_cleared then
            self.is_finished = true
            self.winner = "row_" .. row
            return true
        end
    end
    
    -- Check columns
    for col = 1, size do
        local all_cleared = true
        for row = 1, size do
            local index = self.board:getIndex(row, col)
            if not self.board.cleared[index] then
                all_cleared = false
                break
            end
        end
        if all_cleared then
            self.is_finished = true
            self.winner = "col_" .. col
            return true
        end
    end
    
    -- Check diagonal (top-left to bottom-right)
    local diag_cleared = true
    for i = 1, size do
        local index = self.board:getIndex(i, i)
        if not self.board.cleared[index] then
            diag_cleared = false
            break
        end
    end
    if diag_cleared then
        self.is_finished = true
        self.winner = "diag_1"
        return true
    end
    
    -- Check diagonal (top-right to bottom-left)
    diag_cleared = true
    for i = 1, size do
        local index = self.board:getIndex(i, size - i + 1)
        if not self.board.cleared[index] then
            diag_cleared = false
            break
        end
    end
    if diag_cleared then
        self.is_finished = true
        self.winner = "diag_2"
        return true
    end
    
    return false
end

---Check if blackout (all squares) is won
---@return boolean
function Game:checkBlackoutWin()
    local total = self.board.size * self.board.size
    local cleared = 0
    
    for i = 1, total do
        if self.board.cleared[i] then
            cleared = cleared + 1
        end
    end
    
    if cleared == total then
        self.is_finished = true
        self.winner = "blackout"
        self.blackout_completed_time = self.elapsed_time
        return true
    end
    
    return false
end

---Check if lockout (more lines than opponent) is won
---@return boolean
function Game:checkLockoutWin()
    -- Lockout requires multiplayer opponent, so this is placeholder
    return false
end

---Check if rush (complete X objectives in Y time) is won
---@return boolean
function Game:checkRushWin()
    -- Rush is time-based, so check if we've completed the required objectives
    -- This is a placeholder - actual win condition depends on rush_objective_count
    return false
end

---Mark an objective as completed
---@param row number
---@param col number
function Game:completeObjective(row, col)
    local index = self.board:getIndex(row, col)
    if index then
        self.board.cleared[index] = true
        
        if self.mode == "rush" then
            self.rush_completed_count = (self.rush_completed_count or 0) + 1
            local obj = self.board:getObjective(row, col)
            if obj then
                table.insert(self.rush_completed_objectives, obj)
            end
        end
    end
end

---Pause the game
function Game:pause()
    self.is_paused = true
end

---Resume the game
function Game:resume()
    self.is_paused = false
end

---End the game
function Game:end_game()
    self.is_finished = true
end

BingoCore.Game = Game
