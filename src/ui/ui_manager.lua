-- UI Manager
-- Orchestrates all UI components

---@class UIManager
local UIManager = {}
UIManager.__index = UIManager

function UIManager.new()
    local self = setmetatable({}, UIManager)
    
    -- Don't instantiate dependent classes here - do it in initialize
    self.renderer = nil
    self.positioning = nil
    self.input = nil
    
    return self
end

---Initialize UI (called after all modules are loaded)
function UIManager:initialize()
    -- Now it's safe to instantiate dependent classes
    if BingoUI.BoardRenderer then
        self.renderer = BingoUI.BoardRenderer.new()
    else
        print("ERROR: BingoUI.BoardRenderer not available")
        self.renderer = { drawBoard = function() end }
    end
    
    if BingoUI.BoardPositioning then
        self.positioning = BingoUI.BoardPositioning.new()
    else
        print("ERROR: BingoUI.BoardPositioning not available")
        self.positioning = { 
            current_mode = "large",
            getCurrentPosition = function() return 100, 100, 400, 400 end
        }
    end
    
    if BingoUI.InputHandler and self.positioning then
        self.input = BingoUI.InputHandler.new(self.positioning)
    else
        print("ERROR: BingoUI.InputHandler not available")
        self.input = { 
            update = function() end,
            handleKeyPress = function() end
        }
    end
end

---Update UI
---@param dt number
function UIManager:update(dt)
    self.input:update(dt)
end

---Render the bingo board
---@param game_mode GameMode
function UIManager:render(game_mode)
    if not game_mode or not game_mode.board then
        return
    end
    
    local mode = self.positioning.current_mode
    
    if mode == BingoUI.BoardPositioning.DisplayMode.FULL_SCREEN then
        local x, y, w, h = self.positioning:getCurrentPosition()
        self.renderer:drawBoard(game_mode.board, x, y, w, h)
        self:drawModeButtons("full_screen", x, y, w, h)
    elseif mode == BingoUI.BoardPositioning.DisplayMode.LARGE then
        local x, y, w, h = self.positioning:getCurrentPosition()
        self.renderer:drawBoard(game_mode.board, x, y, w, h)
        self:drawModeButtons("large", x, y, w, h)
        self:drawResizeCorners(x, y, w, h)
    elseif mode == BingoUI.BoardPositioning.DisplayMode.SMALL then
        local x, y, w, h = self.positioning:getCurrentPosition()
        self.renderer:drawBoard(game_mode.board, x, y, w, h)
        self:drawModeButtons("small", x, y, w, h)
        self:drawResizeCorners(x, y, w, h)
    elseif mode == BingoUI.BoardPositioning.DisplayMode.HIDDEN then
        local x, y, w, h = self.positioning:getCurrentPosition()
        self.renderer:drawHiddenButton(x, y, w, h)
    end
end

---Draw mode switching buttons above the board
---@param mode string
---@param x number
---@param y number
---@param width number
---@param height number
function UIManager:drawModeButtons(mode, x, y, width, height)
    local button_size = 30
    local button_y = y - button_size - 5
    local button_color = { 0.2, 0.2, 0.2, 0.8 }
    local hover_color = { 0.3, 0.3, 0.3, 0.9 }
    local text_color = { 1, 1, 1, 1 }
    
    local buttons = {}
    
    if mode == "large" then
        buttons = {
            { label = "FS", action = "full_screen", x = x + width - button_size * 3.5 },
            { label = "S", action = "small", x = x + width - button_size * 2.2 },
            { label = "H", action = "hidden", x = x + width - button_size * 0.9 }
        }
    elseif mode == "small" then
        buttons = {
            { label = "L", action = "large", x = x + width - button_size * 1.6 },
            { label = "H", action = "hidden", x = x + width - button_size * 0.3 }
        }
    elseif mode == "full_screen" then
        buttons = {
            { label = "L", action = "large", x = x + width - button_size * 1.6 },
            { label = "S", action = "small", x = x + width - button_size * 0.3 }
        }
    end
    
    for _, button in ipairs(buttons) do
        love.graphics.setColor(button_color)
        love.graphics.rectangle("fill", button.x, button_y, button_size, button_size)
        
        love.graphics.setColor(text_color)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", button.x, button_y, button_size, button_size)
        
        -- Draw button text
        local font = love.graphics.getFont()
        local text_x = button.x + (button_size - font:getWidth(button.label)) / 2
        local text_y = button_y + (button_size - font:getHeight()) / 2
        love.graphics.print(button.label, text_x, text_y)
    end
end

---Draw resize corner indicators
---@param x number
---@param y number
---@param width number
---@param height number
function UIManager:drawResizeCorners(x, y, width, height)
    local corner_size = 10
    local color = { 1, 1, 1, 0.5 }
    
    love.graphics.setColor(color)
    
    -- Top-left
    love.graphics.rectangle("fill", x, y, corner_size, corner_size)
    -- Top-right
    love.graphics.rectangle("fill", x + width - corner_size, y, corner_size, corner_size)
    -- Bottom-left
    love.graphics.rectangle("fill", x, y + height - corner_size, corner_size, corner_size)
    -- Bottom-right
    love.graphics.rectangle("fill", x + width - corner_size, y + height - corner_size, corner_size, corner_size)
end

---Handle input
---@param key string
function UIManager:handleInput(key)
    self.input:handleKeyPress(key)
end

BingoUI.UIManager = UIManager
