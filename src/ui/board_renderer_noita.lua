-- Board Renderer for Noita
-- Handles rendering of the bingo board using Noita's GUI API

---@class BoardRenderer
local BoardRenderer = {}
BoardRenderer.__index = BoardRenderer

function BoardRenderer.new()
    local self = setmetatable({}, BoardRenderer)
    
    -- Color values (0-1 range for Noita GUI)
    self.FRAME_COLOR = { r = 1, g = 1, b = 1, a = 1 }              -- White frame
    self.BACKGROUND_COLOR = { r = 0, g = 0, b = 0, a = 0.7 }       -- Semi-transparent black
    self.DIVIDER_COLOR = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 }    -- Gray dividers
    self.CLEARED_COLOR = { r = 0.2, g = 0.8, b = 0.2, a = 0.5 }    -- Green for cleared
    self.LOCKED_COLOR = { r = 0.8, g = 0.2, b = 0.2, a = 0.5 }     -- Red for locked
    self.TEXT_COLOR = { r = 1, g = 1, b = 1, a = 1 }               -- White text
    self.BUTTON_COLOR = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 }     -- Dark gray button
    self.BUTTON_HOVER_COLOR = { r = 0.3, g = 0.3, b = 0.3, a = 0.9 } -- Lighter gray hover
    
    self.FRAME_WIDTH = 3
    self.DIVIDER_WIDTH = 2
    self.PADDING = 10
    
    return self
end

---Get unique GUI ID (uses global ID manager)
function BoardRenderer:getID()
    -- Use global GUI ID manager if available
    if get_gui_id then
        return get_gui_id()
    else
        -- Fallback for testing
        if not self.next_id then
            self.next_id = 1000
        end
        self.next_id = self.next_id + 1
        return self.next_id
    end
end

---Set GUI color
---@param gui any
---@param color table
function BoardRenderer:setColor(gui, color)
    GuiColorSetForNextWidget(gui, color.r, color.g, color.b, color.a)
end

---Draw the bingo board at the specified position and size
---@param gui any
---@param board BingoBoard
---@param x number
---@param y number
---@param width number
---@param height number
function BoardRenderer:drawBoard(gui, board, x, y, width, height)
    if not gui or not board or not board.size then
        return
    end
    
    local size = board.size
    
    -- Draw background frame
    self:setColor(gui, self.BACKGROUND_COLOR)
    GuiImageNinePiece(gui, self:getID(), x, y, width, height, 0)
    
    -- Calculate cell dimensions
    local cell_width = width / size
    local cell_height = height / size
    
    -- Draw grid cells
    for row = 1, size do
        for col = 1, size do
            local cell_x = x + (col - 1) * cell_width
            local cell_y = y + (row - 1) * cell_height
            
            self:drawCell(gui, board, row, col, cell_x, cell_y, cell_width, cell_height)
        end
    end
    
    -- Draw border frame
    self:setColor(gui, self.FRAME_COLOR)
    GuiImageNinePiece(gui, self:getID(), x, y, width, height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
end

---Draw a single cell
---@param gui any
---@param board BingoBoard
---@param row number
---@param col number
---@param x number
---@param y number
---@param width number
---@param height number
function BoardRenderer:drawCell(gui, board, row, col, x, y, width, height)
    local objective = board:getObjective(row, col)
    
    if not objective then
        return
    end
    
    local cell_id = self:getID()
    
    -- Draw cell background based on state
    if board:isCleared(row, col) then
        if board:isLocked(row, col) then
            self:setColor(gui, self.LOCKED_COLOR)
        else
            self:setColor(gui, self.CLEARED_COLOR)
        end
    else
        self:setColor(gui, self.BACKGROUND_COLOR)
    end
    
    -- Make cell clickable for marking
    if GuiButton(gui, cell_id, x, y, "") then
        -- Toggle cleared state
        board:setClearedAt(row, col, not board:isCleared(row, col))
    end
    
    -- Draw objective text
    self:setColor(gui, self.TEXT_COLOR)
    
    -- Wrap text to fit in cell
    local text = objective.title
    local text_x = x + self.PADDING
    local text_y = y + self.PADDING
    local text_width = width - self.PADDING * 2
    
    GuiText(gui, text_x, text_y, text)
end

---Draw the hidden button (collapsed mode)
---@param gui any
---@param x number
---@param y number
---@param width number
---@param height number
---@return boolean clicked
function BoardRenderer:drawHiddenButton(gui, x, y, width, height)
    local button_id = self:getID()
    
    -- Draw button background
    self:setColor(gui, self.BUTTON_COLOR)
    
    -- Create clickable button
    local clicked = GuiButton(gui, button_id, x, y, "BINGO")
    
    return clicked
end

---Draw mode buttons above the board
---@param gui any
---@param mode string
---@param x number
---@param y number
---@param width number
---@param height number
---@return string|nil action
function BoardRenderer:drawModeButtons(gui, mode, x, y, width, height)
    local button_size = 30
    local button_y = y - button_size - 5
    local action = nil
    
    local buttons = {}
    
    if mode == "large" then
        buttons = {
            { label = "FS", action = "full_screen", x = x + width - button_size * 3.5 },
            { label = "S", action = "small", x = x + width - button_size * 2.2 },
            { label = "H", action = "hidden", x = x + width - button_size * 0.9 }
        }
    elseif mode == "small" then
        buttons = {
            { label = "H", action = "hidden", x = x + width - button_size * 0.3 }
        }
    elseif mode == "full_screen" then
        buttons = {
            { label = "L", action = "large", x = x + width - button_size * 1.6 },
            { label = "S", action = "small", x = x + width - button_size * 0.3 }
        }
    end
    
    for _, button in ipairs(buttons) do
        self:setColor(gui, self.BUTTON_COLOR)
        
        local button_id = self:getID()
        if GuiButton(gui, button_id, button.x, button_y, button.label) then
            action = button.action
        end
    end
    
    return action
end

---Check if small board was clicked (for single-click to expand)
---@param gui any
---@param x number
---@param y number
---@param width number
---@param height number
---@return boolean clicked
function BoardRenderer:checkBoardClick(gui, x, y, width, height)
    local click_id = self:getID()
    -- Create invisible clickable overlay
    GuiColorSetForNextWidget(gui, 0, 0, 0, 0)
    return GuiButton(gui, click_id, x, y, "")
end

BingoUI.BoardRenderer = BoardRenderer
