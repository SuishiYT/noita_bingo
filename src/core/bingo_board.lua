-- Bingo Board class
-- Manages the state of the bingo board and objective clearing

---@class BingoBoard
---@field objectives table<number, Objective>
---@field cleared table<number, boolean>
---@field size number
---@field game_type string
---@field locked table<number, boolean>
local BingoBoard = {}
BingoBoard.__index = BingoBoard

---Create a new bingo board
---@param objectives table
---@param size number
---@param game_type string
---@return BingoBoard
function BingoBoard.new(objectives, size, game_type)
    local self = setmetatable({}, BingoBoard)
    
    self.size = size or 5
    self.objectives = objectives or {}
    self.game_type = game_type or "traditional"
    self.cleared = {}
    self.locked = {} -- For lockout mode
    
    -- Initialize cleared/locked arrays
    for i = 1, self.size * self.size do
        self.cleared[i] = false
        self.locked[i] = false
    end
    
    -- Center square is always cleared in 5x5 traditional bingo
    if self.size == 5 and self.game_type == "traditional" then
        self.cleared[13] = true -- Center square (row 3, col 3 = index 13)
    end
    
    return self
end

---Get objective at board position
---@param row number
---@param col number
---@return Objective|nil
function BingoBoard:getObjective(row, col)
    if row < 1 or row > self.size or col < 1 or col > self.size then
        return nil
    end
    
    local index = (row - 1) * self.size + col
    return self.objectives[index]
end

---Get the index for a row/column position
---@param row number
---@param col number
---@return number
function BingoBoard:getIndex(row, col)
    if row < 1 or row > self.size or col < 1 or col > self.size then
        return nil
    end
    return (row - 1) * self.size + col
end

---Get row and column from index
---@param index number
---@return number, number
function BingoBoard:getRowCol(index)
    local row = math.floor((index - 1) / self.size) + 1
    local col = ((index - 1) % self.size) + 1
    return row, col
end

---Mark or unmark a square as cleared
---@param row number
---@param col number
---@param cleared boolean
function BingoBoard:setClearedAt(row, col, cleared)
    local index = self:getIndex(row, col)
    
    if index and self.game_type ~= "lockout" then
        self.cleared[index] = cleared or false
    elseif index and self.game_type == "lockout" then
        -- In lockout mode, once locked cannot be unlocked
        if cleared and not self.locked[index] then
            self.cleared[index] = true
            self.locked[index] = true
        elseif not cleared then
            self.cleared[index] = false
            -- Note: don't unlock in lockout mode
        end
    end
end

---Check if a square is cleared
---@param row number
---@param col number
---@return boolean
function BingoBoard:isCleared(row, col)
    local index = self:getIndex(row, col)
    if index then
        return self.cleared[index] or false
    end
    return false
end

---Check if a square is locked (lockout mode)
---@param row number
---@param col number
---@return boolean
function BingoBoard:isLocked(row, col)
    local index = self:getIndex(row, col)
    if index then
        return self.locked[index] or false
    end
    return false
end

---Check for a winning condition
---@return boolean
function BingoBoard:checkWin()
    if self.game_type == "traditional" or self.game_type == "lockout" then
        return self:checkBingo()
    elseif self.game_type == "blackout" then
        return self:checkBlackout()
    elseif self.game_type == "rush" then
        -- Rush win condition is typically time-based, handled by game logic
        return false
    end
    
    return false
end

---Check for traditional bingo (5 in a row, column, or diagonal)
---@return boolean
function BingoBoard:checkBingo()
    -- Check rows
    for row = 1, self.size do
        local all_cleared = true
        for col = 1, self.size do
            if not self:isCleared(row, col) then
                all_cleared = false
                break
            end
        end
        if all_cleared then return true end
    end
    
    -- Check columns
    for col = 1, self.size do
        local all_cleared = true
        for row = 1, self.size do
            if not self:isCleared(row, col) then
                all_cleared = false
                break
            end
        end
        if all_cleared then return true end
    end
    
    -- Check diagonals
    local diag1_clear = true
    for i = 1, self.size do
        if not self:isCleared(i, i) then
            diag1_clear = false
            break
        end
    end
    if diag1_clear then return true end
    
    local diag2_clear = true
    for i = 1, self.size do
        if not self:isCleared(i, self.size - i + 1) then
            diag2_clear = false
            break
        end
    end
    if diag2_clear then return true end
    
    return false
end

---Check for blackout (all squares cleared)
---@return boolean
function BingoBoard:checkBlackout()
    for row = 1, self.size do
        for col = 1, self.size do
            if not self:isCleared(row, col) then
                return false
            end
        end
    end
    return true
end

---Get board state as a string (for debugging)
---@return string
function BingoBoard:toString()
    local output = ""
    for row = 1, self.size do
        for col = 1, self.size do
            if self:isCleared(row, col) then
                output = output .. "X "
            else
                output = output .. "_ "
            end
        end
        output = output .. "\n"
    end
    return output
end

---Export board data for multiplayer synchronization
---@return table
function BingoBoard:exportData()
    return {
        objectives = self.objectives,
        cleared = self.cleared,
        locked = self.locked,
        size = self.size,
        game_type = self.game_type
    }
end

---Import board data from multiplayer synchronization
---@param data table
function BingoBoard:importData(data)
    if data.objectives then self.objectives = data.objectives end
    if data.cleared then self.cleared = data.cleared end
    if data.locked then self.locked = data.locked end
    if data.size then self.size = data.size end
    if data.game_type then self.game_type = data.game_type end
end

BingoCore.BingoBoard = BingoBoard
