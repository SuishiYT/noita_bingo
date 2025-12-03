-- Input Handler
-- Handles keyboard input and mouse interactions

---@class InputHandler
local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new(board_positioning)
    local self = setmetatable({}, InputHandler)
    
    self.board_positioning = board_positioning
    self.double_click_timer = 0
    self.double_click_threshold = 0.3 -- seconds
    self.last_click_pos = { x = 0, y = 0 }
    
    return self
end

---Handle keyboard input
---@param key string
function InputHandler:handleKeyPress(key)
    local hotkeys = self.board_positioning.hotkeys
    
    if key == hotkeys.full_screen then
        self.board_positioning:setMode(BingoUI.BoardPositioning.DisplayMode.FULL_SCREEN)
    elseif key == hotkeys.large then
        self.board_positioning:setMode(BingoUI.BoardPositioning.DisplayMode.LARGE)
    elseif key == hotkeys.small then
        self.board_positioning:setMode(BingoUI.BoardPositioning.DisplayMode.SMALL)
    elseif key == hotkeys.hidden then
        self.board_positioning:setMode(BingoUI.BoardPositioning.DisplayMode.HIDDEN)
    end
end

---Handle mouse press
---@param x number
---@param y number
---@param button number
function InputHandler:handleMousePress(x, y, button)
    if button == 1 then
        -- Check for double click
        local dist_x = x - self.last_click_pos.x
        local dist_y = y - self.last_click_pos.y
        local dist = math.sqrt(dist_x * dist_x + dist_y * dist_y)
        
        if self.double_click_timer > 0 and dist < 10 then
            -- This is a double click
            self:handleDoubleClick(x, y)
            self.double_click_timer = 0
        else
            -- Single click
            self.board_positioning:onMousePress(x, y, button)
            self.last_click_pos = { x = x, y = y }
            self.double_click_timer = self.double_click_threshold
        end
    end
end

---Handle mouse release
---@param x number
---@param y number
---@param button number
function InputHandler:handleMouseRelease(x, y, button)
    self.board_positioning:onMouseRelease(x, y, button)
end

---Handle mouse movement
---@param x number
---@param y number
function InputHandler:handleMouseMove(x, y)
    self.board_positioning:onMouseMove(x, y)
end

---Handle double click
---@param x number
---@param y number
function InputHandler:handleDoubleClick(x, y)
    local mode = self.board_positioning.current_mode
    
    if mode == BingoUI.BoardPositioning.DisplayMode.SMALL then
        -- Small double-click goes to full screen
        self.board_positioning:setMode(BingoUI.BoardPositioning.DisplayMode.FULL_SCREEN)
    elseif mode == BingoUI.BoardPositioning.DisplayMode.HIDDEN then
        -- Hidden double-click goes to full screen
        self.board_positioning:setMode(BingoUI.BoardPositioning.DisplayMode.FULL_SCREEN)
    end
end

---Update timer
---@param dt number
function InputHandler:update(dt)
    if self.double_click_timer > 0 then
        self.double_click_timer = self.double_click_timer - dt
    end
end

BingoUI.InputHandler = InputHandler
