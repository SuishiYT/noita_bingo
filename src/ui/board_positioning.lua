-- Board Positioning System
-- Handles positioning, resizing, and display modes for the bingo board

---@class BoardPositioning
local BoardPositioning = {}
BoardPositioning.__index = BoardPositioning

---Display modes
BoardPositioning.DisplayMode = {
    FULL_SCREEN = "full_screen",
    LARGE = "large",
    SMALL = "small",
    HIDDEN = "hidden"
}

function BoardPositioning.new()
    local self = setmetatable({}, BoardPositioning)
    
    self.current_mode = BoardPositioning.DisplayMode.LARGE
    self.last_board_mode = BoardPositioning.DisplayMode.LARGE -- For remembering mode
    
    -- Positions for each mode
    self.positions = {
        large = {
            x = 100,
            y = 100,
            width = 500,
            height = 500,
            can_drag = true,
            can_resize = true
        },
        small = {
            x = 100,
            y = 100,
            width = 250,
            height = 250,
            can_drag = true,
            can_resize = true
        },
        hidden = {
            side = "right", -- "left" or "right"
            y_percent = 0.5, -- 0 to 1, representing percentage of screen height
            width = 60,
            height = 200,
            can_drag = true,
            can_resize = false
        }
    }
    
    -- Decouple boards setting (when false, large and small share position)
    self.decouple_boards = false
    
    -- Input state
    self.dragging = false
    self.dragging_mode = nil
    self.drag_start_x = 0
    self.drag_start_y = 0
    self.resizing = false
    self.resize_corner = nil -- "tl", "tr", "bl", "br"
    
    -- Hotkeys
    self.hotkeys = {
        full_screen = "f6",
        large = "f7",
        small = "f8",
        hidden = "f9"
    }
    
    return self
end

---Set the current display mode
---@param mode string
function BoardPositioning:setMode(mode)
    if mode ~= self.current_mode then
        -- Remember the last board mode (for hidden toggle)
        if mode ~= BoardPositioning.DisplayMode.HIDDEN then
            self.last_board_mode = mode
        end
        
        self.current_mode = mode
    end
end

---Get current position and size
---@return number, number, number, number
function BoardPositioning:getCurrentPosition()
    if self.current_mode == BoardPositioning.DisplayMode.FULL_SCREEN then
        return 0, 0, love.graphics.getWidth(), love.graphics.getHeight()
    elseif self.current_mode == BoardPositioning.DisplayMode.HIDDEN then
        local hidden = self.positions.hidden
        local screen_width = love.graphics.getWidth()
        local screen_height = love.graphics.getHeight()
        
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

---Update position for current mode
---@param x number
---@param y number
---@param width number|nil
---@param height number|nil
function BoardPositioning:setCurrentPosition(x, y, width, height)
    if self.current_mode == BoardPositioning.DisplayMode.FULL_SCREEN then
        -- Cannot move full screen
        return
    elseif self.current_mode == BoardPositioning.DisplayMode.HIDDEN then
        local hidden = self.positions.hidden
        local screen_height = love.graphics.getHeight()
        
        -- Update side and y position
        local screen_width = love.graphics.getWidth()
        if x < screen_width / 2 then
            hidden.side = "left"
        else
            hidden.side = "right"
        end
        
        -- Clamp y to 0-1 range
        hidden.y_percent = math.max(0, math.min(1, y / screen_height))
    else
        local pos = self.positions[self.current_mode]
        if pos then
            pos.x = x
            pos.y = y
            
            if width then
                pos.width = math.max(150, width) -- Minimum size
            end
            if height then
                pos.height = math.max(150, height)
            end
            
            -- Apply decouple boards setting
            if not self.decouple_boards then
                -- Copy position to other board size if they were the same
                if self.current_mode == BoardPositioning.DisplayMode.LARGE then
                    local small_pos = self.positions.small
                    small_pos.x = pos.x
                    small_pos.y = pos.y
                elseif self.current_mode == BoardPositioning.DisplayMode.SMALL then
                    local large_pos = self.positions.large
                    large_pos.x = pos.x
                    large_pos.y = pos.y
                end
            end
        end
    end
end

---Handle mouse press
---@param x number
---@param y number
---@param button number
function BoardPositioning:onMousePress(x, y, button)
    if button ~= 1 then
        return -- Only left click
    end
    
    local bx, by, bw, bh = self:getCurrentPosition()
    
    -- Check if click is in board area
    if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
        if self.current_mode == BoardPositioning.DisplayMode.HIDDEN or
           self.current_mode == BoardPositioning.DisplayMode.FULL_SCREEN then
            self.dragging = true
            self.dragging_mode = self.current_mode
            self.drag_start_x = x - bx
            self.drag_start_y = y - by
        else
            -- Check if dragging from corner (resize) or body (drag)
            local corner_size = 20
            
            -- Check corners for resize
            if (x >= bx + bw - corner_size and x <= bx + bw) then
                if (y >= by and y <= by + corner_size) then
                    self.resizing = true
                    self.resize_corner = "tr"
                    self.drag_start_x = x
                    self.drag_start_y = y
                    return
                elseif (y >= by + bh - corner_size and y <= by + bh) then
                    self.resizing = true
                    self.resize_corner = "br"
                    self.drag_start_x = x
                    self.drag_start_y = y
                    return
                end
            elseif (x >= bx and x <= bx + corner_size) then
                if (y >= by and y <= by + corner_size) then
                    self.resizing = true
                    self.resize_corner = "tl"
                    self.drag_start_x = x
                    self.drag_start_y = y
                    return
                elseif (y >= by + bh - corner_size and y <= by + bh) then
                    self.resizing = true
                    self.resize_corner = "bl"
                    self.drag_start_x = x
                    self.drag_start_y = y
                    return
                end
            end
            
            -- Not a corner, so drag the whole board
            self.dragging = true
            self.dragging_mode = self.current_mode
            self.drag_start_x = x - bx
            self.drag_start_y = y - by
        end
    end
end

---Handle mouse release
---@param x number
---@param y number
---@param button number
function BoardPositioning:onMouseRelease(x, y, button)
    if button ~= 1 then
        return
    end
    
    self.dragging = false
    self.dragging_mode = nil
    self.resizing = false
    self.resize_corner = nil
end

---Handle mouse movement while dragging
---@param x number
---@param y number
function BoardPositioning:onMouseMove(x, y)
    if self.dragging then
        local new_x = x - self.drag_start_x
        local new_y = y - self.drag_start_y
        self:setCurrentPosition(new_x, new_y)
    elseif self.resizing then
        local bx, by, bw, bh = self:getCurrentPosition()
        local dx = x - self.drag_start_x
        local dy = y - self.drag_start_y
        
        if self.resize_corner == "br" then
            self:setCurrentPosition(bx, by, bw + dx, bh + dy)
        elseif self.resize_corner == "tr" then
            self:setCurrentPosition(bx, by + dy, bw + dx, bh - dy)
        elseif self.resize_corner == "bl" then
            self:setCurrentPosition(bx + dx, by, bw - dx, bh + dy)
        elseif self.resize_corner == "tl" then
            self:setCurrentPosition(bx + dx, by + dy, bw - dx, bh - dy)
        end
        
        self.drag_start_x = x
        self.drag_start_y = y
    end
end

---Toggle to last board mode or full screen
function BoardPositioning:toggleFromHidden()
    if self.current_mode == BoardPositioning.DisplayMode.HIDDEN then
        self:setMode(self.last_board_mode)
    end
end

---Set decouple boards setting
---@param decouple boolean
function BoardPositioning:setDecoupleBoardsSetting(decouple)
    self.decouple_boards = decouple
end

BingoUI.BoardPositioning = BoardPositioning
