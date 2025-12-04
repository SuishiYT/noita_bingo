-- Noita Theme System
-- Provides themed GUI components that match Noita's visual style

---@class NoitaTheme
local NoitaTheme = {}
NoitaTheme.__index = NoitaTheme

-- Color palette matching Noita's UI
NoitaTheme.Colors = {
    -- Backgrounds
    background_dark = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 },
    background_transparent = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 },
    background_panel = { r = 0.08, g = 0.08, b = 0.08, a = 0.85 },
    
    -- Text colors
    text_primary = { r = 1, g = 1, b = 1, a = 1 },           -- White
    text_secondary = { r = 0.8, g = 0.8, b = 0.8, a = 1 },    -- Light gray
    text_title = { r = 1, g = 0.9, b = 0.3, a = 1 },           -- Golden yellow
    text_accent = { r = 0.4, g = 1, b = 0.6, a = 1 },          -- Green accent
    text_warning = { r = 1, g = 0.6, b = 0.2, a = 1 },         -- Orange warning
    text_error = { r = 1, g = 0.3, b = 0.3, a = 1 },           -- Red error
    
    -- Button states
    button_normal = { r = 0.15, g = 0.15, b = 0.15, a = 0.8 },
    button_hover = { r = 0.25, g = 0.25, b = 0.25, a = 0.9 },
    button_active = { r = 0.35, g = 0.35, b = 0.35, a = 1 },
    
    -- Bingo board states
    square_empty = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 },
    square_cleared = { r = 0.2, g = 0.7, b = 0.4, a = 0.8 },   -- Green
    square_locked = { r = 0.7, g = 0.2, b = 0.2, a = 0.8 },    -- Red
    square_hover = { r = 0.2, g = 0.2, b = 0.35, a = 0.8 },    -- Slightly blue
    
    -- Borders and frames
    border_primary = { r = 1, g = 0.9, b = 0.3, a = 1 },        -- Golden yellow
    border_secondary = { r = 0.5, g = 0.5, b = 0.5, a = 0.8 },  -- Gray
    border_subtle = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 },     -- Dark gray
    
    -- Status colors
    multiplayer_connected = { r = 0.3, g = 1, b = 0.3, a = 1 },
    multiplayer_disconnected = { r = 1, g = 0.3, b = 0.3, a = 1 },
    multiplayer_waiting = { r = 1, g = 0.8, b = 0.2, a = 1 },
}

-- Textures used by Noita
NoitaTheme.Textures = {
    white_1px = "data/ui_gfx/1px_white.png",
    white_1x1 = "data/ui_gfx/1x1_white.png",
    
    -- 9-piece decorative borders
    border_9piece = "data/ui_gfx/decorations/9piece0.png",
    border_9piece_gray = "data/ui_gfx/decorations/9piece0_gray.png",
    border_3piece_fungal = "data/ui_gfx/decorations/3piece_fungal_shift.png",
    
    -- Noita logo
    logo = "data/ui_gfx/pause_menu/noita_logo.png",
    
    -- Tabs
    tab_normal = "data/ui_gfx/decorations/tab.png",
    tab_hover = "data/ui_gfx/decorations/tab_hovered.png",
    tab_selected = "data/ui_gfx/decorations/tab_selected.png",
}

function NoitaTheme.new()
    local self = setmetatable({}, NoitaTheme)
    return self
end

---Set color for next GUI widget
---@param gui any
---@param color_table table
function NoitaTheme:setColor(gui, color_table)
    if color_table then
        GuiColorSetForNextWidget(gui, color_table.r, color_table.g, color_table.b, color_table.a)
    end
end

---Draw a panel with Noita theme
---@param gui any
---@param gui_id number
---@param x number
---@param y number
---@param width number
---@param height number
---@param title? string Optional title to display
function NoitaTheme:drawPanel(gui, gui_id, x, y, width, height, title)
    -- Draw semi-transparent background
    self:setColor(gui, self.Colors.background_panel)
    GuiImage(gui, gui_id, x, y, self.Textures.white_1x1, 1, width, height)
    
    -- Draw border
    local border_width = 2
    self:setColor(gui, self.Colors.border_primary)
    -- Top border
    GuiImage(gui, gui_id + 1, x, y, self.Textures.white_1px, 1, width, border_width)
    -- Bottom border
    GuiImage(gui, gui_id + 2, x, y + height - border_width, self.Textures.white_1px, 1, width, border_width)
    -- Left border
    GuiImage(gui, gui_id + 3, x, y, self.Textures.white_1px, 1, border_width, height)
    -- Right border
    GuiImage(gui, gui_id + 4, x + width - border_width, y, self.Textures.white_1px, 1, border_width, height)
    
    -- Draw title if provided
    if title then
        self:setColor(gui, self.Colors.text_title)
        GuiText(gui, x + 15, y + 8, title)
    end
end

---Draw a button with Noita theme
---@param gui any
---@param gui_id number
---@param x number
---@param y number
---@param text string
---@param is_hover? boolean Whether button is being hovered
---@return boolean clicked
function NoitaTheme:drawButton(gui, gui_id, x, y, text, is_hover)
    local button_width = 120
    local button_height = 35
    
    -- Draw button background
    local bg_color = is_hover and self.Colors.button_hover or self.Colors.button_normal
    self:setColor(gui, bg_color)
    GuiImage(gui, gui_id, x, y, self.Textures.white_1x1, 1, button_width, button_height)
    
    -- Draw button border
    self:setColor(gui, self.Colors.border_primary)
    local border = 1
    GuiImage(gui, gui_id + 1, x, y, self.Textures.white_1px, 1, button_width, border)
    GuiImage(gui, gui_id + 2, x, y + button_height - border, self.Textures.white_1px, 1, button_width, border)
    GuiImage(gui, gui_id + 3, x, y, self.Textures.white_1px, 1, border, button_height)
    GuiImage(gui, gui_id + 4, x + button_width - border, y, self.Textures.white_1px, 1, border, button_height)
    
    -- Draw button text
    self:setColor(gui, self.Colors.text_primary)
    GuiText(gui, x + 10, y + 8, text)
    
    -- Return if clicked
    return GuiButton(gui, gui_id + 5, x, y, "")
end

---Draw a titled section with subtitle
---@param gui any
---@param gui_id number
---@param x number
---@param y number
---@param title string
---@param subtitle? string
---@return number next_y
function NoitaTheme:drawSection(gui, gui_id, x, y, title, subtitle)
    -- Title
    self:setColor(gui, self.Colors.text_title)
    GuiText(gui, x, y, title)
    
    local next_y = y + 25
    
    -- Subtitle if provided
    if subtitle then
        self:setColor(gui, self.Colors.text_secondary)
        GuiText(gui, x + 15, next_y, subtitle)
        next_y = next_y + 18
    end
    
    -- Divider line
    self:setColor(gui, self.Colors.border_subtle)
    GuiImage(gui, gui_id, x, next_y - 5, self.Textures.white_1px, 1, 300, 1)
    
    return next_y + 5
end

---Draw a stat display (label + value)
---@param gui any
---@param gui_id number
---@param x number
---@param y number
---@param label string
---@param value string
---@return number next_y
function NoitaTheme:drawStat(gui, gui_id, x, y, label, value)
    -- Label
    self:setColor(gui, self.Colors.text_secondary)
    GuiText(gui, x, y, label .. ":")
    
    -- Value
    self:setColor(gui, self.Colors.text_accent)
    GuiText(gui, x + 150, y, value)
    
    return y + 20
end

---Draw a menu item (like a row in a list)
---@param gui any
---@param gui_id number
---@param x number
---@param y number
---@param text string
---@param is_selected? boolean
---@param is_hover? boolean
---@return boolean clicked
function NoitaTheme:drawMenuItem(gui, gui_id, x, y, text, is_selected, is_hover)
    local width = 200
    local height = 30
    
    -- Background
    if is_selected then
        self:setColor(gui, self.Colors.button_active)
    elseif is_hover then
        self:setColor(gui, self.Colors.button_hover)
    else
        self:setColor(gui, self.Colors.button_normal)
    end
    GuiImage(gui, gui_id, x, y, self.Textures.white_1x1, 1, width, height)
    
    -- Left border if selected
    if is_selected then
        self:setColor(gui, self.Colors.border_primary)
        GuiImage(gui, gui_id + 1, x, y, self.Textures.white_1px, 1, 3, height)
    end
    
    -- Text
    if is_selected then
        self:setColor(gui, self.Colors.text_title)
    else
        self:setColor(gui, self.Colors.text_primary)
    end
    GuiText(gui, x + 10, y + 5, text)
    
    -- Clickable area
    return GuiButton(gui, gui_id + 2, x, y, "")
end

---Draw a status indicator (connected/disconnected/warning)
---@param gui any
---@param gui_id number
---@param x number
---@param y number
---@param status "connected" | "disconnected" | "waiting"
---@param label string
function NoitaTheme:drawStatusIndicator(gui, gui_id, x, y, status, label)
    local color
    if status == "connected" then
        color = self.Colors.multiplayer_connected
    elseif status == "disconnected" then
        color = self.Colors.multiplayer_disconnected
    elseif status == "waiting" then
        color = self.Colors.multiplayer_waiting
    end
    
    -- Indicator dot
    self:setColor(gui, color)
    GuiImage(gui, gui_id, x, y, self.Textures.white_1x1, 1, 12, 12)
    
    -- Label
    self:setColor(gui, self.Colors.text_secondary)
    GuiText(gui, x + 18, y - 2, label .. ": ")
    
    -- Status text
    self:setColor(gui, color)
    GuiText(gui, x + 140, y - 2, status)
end

---Draw a header for a menu screen
---@param gui any
---@param screen_width number
---@param screen_height number
---@param title string
---@param subtitle? string
function NoitaTheme:drawHeader(gui, screen_width, screen_height, title, subtitle)
    local header_height = subtitle and 80 or 60
    
    -- Background panel
    self:setColor(gui, self.Colors.background_panel)
    GuiImage(gui, 0, 0, 0, self.Textures.white_1x1, 1, screen_width, header_height)
    
    -- Top border
    self:setColor(gui, self.Colors.border_primary)
    GuiImage(gui, 1, 0, 0, self.Textures.white_1px, 1, screen_width, 3)
    
    -- Title
    self:setColor(gui, self.Colors.text_title)
    GuiText(gui, 20, 15, title)
    
    -- Subtitle if provided
    if subtitle then
        self:setColor(gui, self.Colors.text_secondary)
        GuiText(gui, 20, 40, subtitle)
    end
    
    return header_height
end

BingoUI.NoitaTheme = NoitaTheme
