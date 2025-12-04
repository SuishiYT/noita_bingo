-- Board Renderer for Noita
-- Handles rendering of the bingo board using Noita's GUI API with Noita theme

---@class BoardRenderer
local BoardRenderer = {}
BoardRenderer.__index = BoardRenderer

function BoardRenderer.new()
    local self = setmetatable({}, BoardRenderer)
    
    -- Use Noita theme for colors
    self.theme = BingoUI.NoitaTheme.new()
    
    self.FRAME_WIDTH = 3
    self.DIVIDER_WIDTH = 1
    self.PADDING = 10
    self.CELL_PADDING = 5
    
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
    if color then
        self.theme:setColor(gui, color)
    end
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
    
    -- Draw background panel with theme
    self.theme:drawPanel(gui, self:getID(), x, y, width, height)
    
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
    
    -- Determine cell color based on state
    local cell_color
    if board:isCleared(row, col) then
        if board:isLocked(row, col) then
            cell_color = self.theme.Colors.square_locked
        else
            cell_color = self.theme.Colors.square_cleared
        end
    else
        cell_color = self.theme.Colors.square_empty
    end
    
    -- Draw cell background
    self:setColor(gui, cell_color)
    GuiImage(gui, cell_id, x, y, self.theme.Textures.white_1x1, 1, width, height)
    
    -- Draw cell border
    self:setColor(gui, self.theme.Colors.border_subtle)
    GuiImage(gui, cell_id + 1, x, y, self.theme.Textures.white_1px, 1, width, 1)
    GuiImage(gui, cell_id + 2, x, y + height - 1, self.theme.Textures.white_1px, 1, width, 1)
    GuiImage(gui, cell_id + 3, x, y, self.theme.Textures.white_1px, 1, 1, height)
    GuiImage(gui, cell_id + 4, x + width - 1, y, self.theme.Textures.white_1px, 1, 1, height)
    
    -- Make cell clickable for marking
    if GuiButton(gui, cell_id + 5, x, y, "") then
        -- Toggle cleared state
        board:setClearedAt(row, col, not board:isCleared(row, col))
    end
    
    -- Draw objective text (abbreviated if needed)
    self:setColor(gui, self.theme.Colors.text_primary)
    
    -- Wrap text to fit in cell
    local text = objective.title
    -- Truncate text if too long
    if #text > 20 then
        text = text:sub(1, 17) .. "..."
    end
    
    local text_x = x + self.CELL_PADDING
    local text_y = y + self.CELL_PADDING
    
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
