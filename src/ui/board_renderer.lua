-- Board Renderer
-- Handles rendering of the bingo board in various display modes

---@class BoardRenderer
local BoardRenderer = {}
BoardRenderer.__index = BoardRenderer

function BoardRenderer.new()
    local self = setmetatable({}, BoardRenderer)
    
    self.FRAME_COLOR = { 1, 1, 1, 1 }           -- White frame
    self.BACKGROUND_COLOR = { 0, 0, 0, 0.7 }    -- Semi-transparent black
    self.DIVIDER_COLOR = { 0.5, 0.5, 0.5, 0.5 } -- Gray dividers
    self.CLEARED_COLOR = { 0.2, 0.8, 0.2, 0.5 } -- Green for cleared
    self.LOCKED_COLOR = { 0.8, 0.2, 0.2, 0.5 }  -- Red for locked
    self.TEXT_COLOR = { 1, 1, 1, 1 }             -- White text
    
    self.FRAME_WIDTH = 3
    self.DIVIDER_WIDTH = 2
    self.PADDING = 10
    
    return self
end

---Draw the bingo board at the specified position and size
---@param board BingoBoard
---@param x number
---@param y number
---@param width number
---@param height number
function BoardRenderer:drawBoard(board, x, y, width, height)
    local size = board.size
    
    -- Draw background frame
    love.graphics.setColor(self.BACKGROUND_COLOR)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw border frame
    love.graphics.setColor(self.FRAME_COLOR)
    love.graphics.setLineWidth(self.FRAME_WIDTH)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Calculate cell dimensions
    local cell_width = width / size
    local cell_height = height / size
    
    -- Draw grid
    for row = 1, size do
        for col = 1, size do
            local cell_x = x + (col - 1) * cell_width
            local cell_y = y + (row - 1) * cell_height
            
            self:drawCell(board, row, col, cell_x, cell_y, cell_width, cell_height)
        end
    end
    
    -- Draw divider lines
    love.graphics.setColor(self.DIVIDER_COLOR)
    love.graphics.setLineWidth(self.DIVIDER_WIDTH)
    
    -- Vertical dividers
    for col = 1, size - 1 do
        local line_x = x + col * cell_width
        love.graphics.line(line_x, y, line_x, y + height)
    end
    
    -- Horizontal dividers
    for row = 1, size - 1 do
        local line_y = y + row * cell_height
        love.graphics.line(x, line_y, x + width, line_y)
    end
    
    love.graphics.setLineWidth(1)
end

---Draw a single cell
---@param board BingoBoard
---@param row number
---@param col number
---@param x number
---@param y number
---@param width number
---@param height number
function BoardRenderer:drawCell(board, row, col, x, y, width, height)
    local objective = board:getObjective(row, col)
    
    if not objective then
        return
    end
    
    -- Draw cell background based on state
    if board:isCleared(row, col) then
        if board:isLocked(row, col) then
            love.graphics.setColor(self.LOCKED_COLOR)
        else
            love.graphics.setColor(self.CLEARED_COLOR)
        end
        love.graphics.rectangle("fill", x, y, width, height)
    else
        love.graphics.setColor(self.BACKGROUND_COLOR)
        love.graphics.rectangle("fill", x, y, width, height)
    end
    
    -- Draw cell border
    love.graphics.setColor(self.FRAME_COLOR)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw objective text
    love.graphics.setColor(self.TEXT_COLOR)
    
    -- Use a smaller font for the text
    local font = love.graphics.getFont()
    local old_font = font
    
    -- Wrap text to fit in cell
    local wrapped_text = self:wrapText(objective.title, width - self.PADDING * 2)
    local text_height = font:getHeight() * #wrapped_text
    
    local text_y = y + (height - text_height) / 2
    
    for i, line in ipairs(wrapped_text) do
        local text_x = x + (width - font:getWidth(line)) / 2
        love.graphics.print(line, text_x, text_y + (i - 1) * font:getHeight())
    end
end

---Wrap text to fit within a specified width
---@param text string
---@param max_width number
---@return table
function BoardRenderer:wrapText(text, max_width)
    local font = love.graphics.getFont()
    local lines = {}
    local current_line = ""
    
    for word in text:gmatch("%S+") do
        local test_line = current_line .. (current_line == "" and "" or " ") .. word
        
        if font:getWidth(test_line) > max_width then
            if current_line ~= "" then
                table.insert(lines, current_line)
            end
            current_line = word
        else
            current_line = test_line
        end
    end
    
    if current_line ~= "" then
        table.insert(lines, current_line)
    end
    
    return lines
end

---Draw the hidden button (collapsed mode)
---@param x number
---@param y number
---@param width number
---@param height number
function BoardRenderer:drawHiddenButton(x, y, width, height)
    -- Draw button background
    love.graphics.setColor(self.BACKGROUND_COLOR)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw button border
    love.graphics.setColor(self.FRAME_COLOR)
    love.graphics.setLineWidth(self.FRAME_WIDTH)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw button text
    love.graphics.setColor(self.TEXT_COLOR)
    local text = "BINGO"
    local font = love.graphics.getFont()
    local text_x = x + (width - font:getWidth(text)) / 2
    local text_y = y + (height - font:getHeight()) / 2
    love.graphics.print(text, text_x, text_y)
end

BingoUI.BoardRenderer = BoardRenderer
