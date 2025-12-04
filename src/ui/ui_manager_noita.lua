-- UI Manager for Noita
-- Orchestrates all UI components using Noita's GUI API

-- Key constants (from data/scripts/debug/keycodes.lua)
local Key_Z = 29      -- Full Screen
local Key_X = 27      -- Large Board
local Key_C = 6       -- Small Board
local Key_R = 21      -- Hidden/Toggle

---@class UIManager
local UIManager = {}
UIManager.__index = UIManager

function UIManager.new()
    local self = setmetatable({}, UIManager)
    
    self.renderer = BingoUI.BoardRenderer.new()
    self.current_mode = "large"
    self.last_board_mode = "large"
    
    -- Positions for each mode
    self.positions = {
        large = { x = 100, y = 100, width = 500, height = 500 },
        small = { x = 100, y = 100, width = 250, height = 250 },
        hidden = {
            side = "right",
            y_percent = 0.5,
            width = 60,
            height = 200
        }
    }
    
    -- Decouple boards setting
    self.decouple_boards = false
    
    -- Mouse state for dragging
    self.is_dragging = false
    self.drag_offset_x = 0
    self.drag_offset_y = 0
    
    -- Hotkeys
    self.hotkeys = {
        full_screen = "z",
        large = "x",
        small = "c",
        hidden = "r"
    }
    
    return self
end

---Initialize UI
function UIManager:initialize()
    -- Load saved positions if available
    self:loadPositions()
end

---Set display mode
---@param mode string
function UIManager:setMode(mode)
    if mode ~= self.current_mode then
        if mode ~= "hidden" then
            self.last_board_mode = mode
        end
        self.current_mode = mode
    end
end

---Get current position and size
---@return number, number, number, number
function UIManager:getCurrentPosition()
    if self.current_mode == "full_screen" then
        local screen_width, screen_height = GuiGetScreenDimensions(GuiCreate())
        return 0, 0, screen_width, screen_height
    elseif self.current_mode == "hidden" then
        local screen_width, screen_height = GuiGetScreenDimensions(GuiCreate())
        local hidden = self.positions.hidden
        local x = hidden.side == "left" and 0 or (screen_width - hidden.width)
        local y = (screen_height * hidden.y_percent) - (hidden.height / 2)
        return x, y, hidden.width, hidden.height
    else
        local pos = self.positions[self.current_mode]
        if pos then
            return pos.x, pos.y, pos.width, pos.height
        end
    end
    
    return 0, 0, 500, 500
end

---Update UI state
---@param dt number
function UIManager:update(dt)
    -- Handle hotkeys
    if InputIsKeyJustDown(Key_Z) then
        self:setMode("full_screen")
    elseif InputIsKeyJustDown(Key_X) then
        self:setMode("large")
    elseif InputIsKeyJustDown(Key_C) then
        self:setMode("small")
    elseif InputIsKeyJustDown(Key_R) then
        if self.current_mode == "hidden" then
            self:setMode(self.last_board_mode)
        else
            self:setMode("hidden")
        end
    end
end

---Render the bingo board
---@param game_mode GameMode
---@param gui any
function UIManager:render(game_mode, gui)
    if not game_mode or not game_mode.board then
        return
    end
    
    local x, y, w, h = self:getCurrentPosition()
    
    if self.current_mode == "hidden" then
        -- Draw hidden button
        if self.renderer:drawHiddenButton(gui, x, y, w, h) then
            self:setMode(self.last_board_mode)
        end
    elseif self.current_mode == "small" then
        -- Small board: click anywhere to expand to large
        self.renderer:drawBoard(gui, game_mode.board, x, y, w, h)
        
        -- Draw mode button
        local action = self.renderer:drawModeButtons(gui, self.current_mode, x, y, w, h)
        if action then
            self:setMode(action)
        end
        
        -- Check for click on board itself to expand to large
        if self.renderer:checkBoardClick(gui, x, y, w, h) then
            self:setMode("large")
        end
    else
        -- Draw the board
        self.renderer:drawBoard(gui, game_mode.board, x, y, w, h)
        
        -- Draw mode buttons and handle clicks
        local action = self.renderer:drawModeButtons(gui, self.current_mode, x, y, w, h)
        if action then
            self:setMode(action)
        end
    end
end

---Save positions to persistent storage
function UIManager:savePositions()
    -- Noita's ModSettingSet can be used for persistence
    ModSettingSet("noita_bingo.large_x", self.positions.large.x)
    ModSettingSet("noita_bingo.large_y", self.positions.large.y)
    ModSettingSet("noita_bingo.large_width", self.positions.large.width)
    ModSettingSet("noita_bingo.large_height", self.positions.large.height)
    
    ModSettingSet("noita_bingo.small_x", self.positions.small.x)
    ModSettingSet("noita_bingo.small_y", self.positions.small.y)
    ModSettingSet("noita_bingo.small_width", self.positions.small.width)
    ModSettingSet("noita_bingo.small_height", self.positions.small.height)
    
    ModSettingSet("noita_bingo.hidden_side", self.positions.hidden.side)
    ModSettingSet("noita_bingo.hidden_y_percent", self.positions.hidden.y_percent)
    
    ModSettingSet("noita_bingo.current_mode", self.current_mode)
    ModSettingSet("noita_bingo.decouple_boards", self.decouple_boards and "true" or "false")
end

---Load positions from persistent storage
function UIManager:loadPositions()
    -- Load saved positions
    self.positions.large.x = ModSettingGet("noita_bingo.large_x") or 100
    self.positions.large.y = ModSettingGet("noita_bingo.large_y") or 100
    self.positions.large.width = ModSettingGet("noita_bingo.large_width") or 500
    self.positions.large.height = ModSettingGet("noita_bingo.large_height") or 500
    
    self.positions.small.x = ModSettingGet("noita_bingo.small_x") or 100
    self.positions.small.y = ModSettingGet("noita_bingo.small_y") or 100
    self.positions.small.width = ModSettingGet("noita_bingo.small_width") or 250
    self.positions.small.height = ModSettingGet("noita_bingo.small_height") or 250
    
    self.positions.hidden.side = ModSettingGet("noita_bingo.hidden_side") or "right"
    self.positions.hidden.y_percent = ModSettingGet("noita_bingo.hidden_y_percent") or 0.5
    
    self.current_mode = ModSettingGet("noita_bingo.current_mode") or "large"
    local decouple = ModSettingGet("noita_bingo.decouple_boards")
    self.decouple_boards = decouple == "true"
end

BingoUI.UIManager = UIManager
