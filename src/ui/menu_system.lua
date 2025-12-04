-- Menu System for Noita Bingo
-- Handles all menu states, navigation, and UI rendering

---@class MenuSystem
local MenuSystem = {}
MenuSystem.__index = MenuSystem

-- Menu states
MenuSystem.State = {
    SPLASH = "splash",
    MAIN_MENU = "main_menu",
    SINGLEPLAYER_MODE_SELECT = "sp_mode_select",
    MULTIPLAYER_SETUP = "mp_setup",
    MULTIPLAYER_MODE_SELECT = "mp_mode_select",
    GAME_SETTINGS = "game_settings",
    SETTINGS = "settings",
    GAME_CONTROLS = "game_controls",
    WAITING_FOR_REVEAL = "waiting_for_reveal",
    GAME_OVER = "game_over",
    CLOSED = "closed"
}

-- Game modes
MenuSystem.GameMode = {
    TRADITIONAL = "traditional",
    BLACKOUT = "blackout",
    LOCKOUT = "lockout",
    RUSH = "rush"
}

-- Multiplayer types
MenuSystem.MultiplayerType = {
    NONE = "none",
    EVAISA_MP = "evaisa_mp",
    HTTP_FALLBACK = "http_fallback"
}

function MenuSystem.new()
    local self = setmetatable({}, MenuSystem)
    
    self.current_state = MenuSystem.State.CLOSED
    self.previous_state = nil
    self.state_stack = {} -- For back navigation
    
    -- Check if first time opening - show splash by default
    local splash_setting = ModSettingGet("noita_bingo.show_splash")
    -- On first run, splash_setting will be nil, so show splash
    -- Only hide splash if explicitly set to "false"
    self.show_splash = (splash_setting == nil or splash_setting ~= "false")
    
    -- Splash screen checkbox state
    self.dont_show_splash_again = false
    
    -- Menu data
    self.selected_mode = nil
    self.is_multiplayer = false
    self.multiplayer_type = MenuSystem.MultiplayerType.NONE
    self.is_host = false
    
    -- Game settings
    self.game_settings = {
        board_size = 5,
        category_limits = {
            bloodshed = nil,
            deaths = nil,
            wandbuilding = nil,
            inventory = nil,
            exploration = nil,
            events_misc = nil
        },
        enable_rewards = true,
        rewards_file = "default",
        timer_mode = "elapsed", -- "elapsed" or "countdown"
        timer_enabled = true,
        countdown_duration = 1800, -- 30 minutes in seconds
        reveal_countdown = true,
        reveal_countdown_duration = 3,
        rush_objective_count = 3
    }
    
    -- Current settings preset name
    self.current_preset_name = "default"
    self.settings_presets = {} -- Loaded from files
    
    return self
end

---Get unique GUI ID (uses global ID manager)
function MenuSystem:getID()
    -- Use global GUI ID manager if available
    if get_gui_id then
        return get_gui_id()
    else
        -- Fallback for testing
        if not self.gui_id then
            self.gui_id = 2000
        end
        self.gui_id = self.gui_id + 1
        return self.gui_id
    end
end

---Helper function for reliable button rendering
---@param gui any
---@param x number
---@param y number
---@param text string
---@return boolean
function MenuSystem:renderButton(gui, x, y, text)
    if not gui then
        GamePrint("ERROR: GUI is nil in renderButton!")
        return false
    end
    
    local button_id = self:getID()
    local clicked = false
    
    -- Wrap in pcall to catch any GUI errors
    local success, result = pcall(function()
        return GuiButton(gui, button_id, x, y, text)
    end)
    
    if success then
        clicked = result
    else
        GamePrint("ERROR in GuiButton: " .. tostring(result))
        return false
    end
    
    -- Debug output for button state (less frequent to avoid spam)
    if clicked then
        GamePrint("*** BUTTON CLICKED: '" .. text .. "' - ID: " .. button_id .. " ***")
    elseif GameGetFrameNum() % 120 == 0 then -- Debug every 2 seconds
        GamePrint("Button '" .. text .. "' - ID: " .. button_id .. ", Pos: " .. x .. "," .. y)
    end
    
    return clicked
end

---Open menu
function MenuSystem:open()
    if self.show_splash then
        self.current_state = MenuSystem.State.SPLASH
    else
        self.current_state = MenuSystem.State.MAIN_MENU
    end
    self.state_stack = {}
end

---Close menu
function MenuSystem:close()
    self.current_state = MenuSystem.State.CLOSED
    self.state_stack = {}
end

---Check if menu is open
function MenuSystem:isOpen()
    return self.current_state ~= MenuSystem.State.CLOSED
end

---Navigate to a new state
---@param new_state string
---@param add_to_stack boolean
function MenuSystem:navigate(new_state, add_to_stack)
    print("BINGO: Navigate called - from " .. tostring(self.current_state) .. " to " .. tostring(new_state))
    GamePrint("BINGO: Navigating to " .. tostring(new_state))
    
    if add_to_stack == nil then add_to_stack = true end
    
    if add_to_stack then
        table.insert(self.state_stack, self.current_state)
    end
    
    self.previous_state = self.current_state
    self.current_state = new_state
    
    print("BINGO: Navigation complete - current state is now " .. tostring(self.current_state))
end

---Go back to previous state
function MenuSystem:goBack()
    if #self.state_stack > 0 then
        self.current_state = table.remove(self.state_stack)
    else
        self:close()
    end
end

---Check if evaisa.mp framework is available
---@return boolean
function MenuSystem:isEvaisaMpAvailable()
    -- Check if evaisa.mp framework is loaded
    local has_bingo_mp = BingoMultiplayer ~= nil
    local has_framework_func = has_bingo_mp and BingoMultiplayer.isFrameworkAvailable ~= nil
    local framework_available = has_framework_func and BingoMultiplayer.isFrameworkAvailable()
    
    if GameGetFrameNum() % 300 == 0 then -- Debug every 5 seconds
        print("Menu Debug: BingoMultiplayer exists: " .. tostring(has_bingo_mp) .. 
              ", has function: " .. tostring(has_framework_func) .. 
              ", framework available: " .. tostring(framework_available))
    end
    
    return framework_available
end

---Update menu (handle input, etc)
---@param dt number
function MenuSystem:update(dt)
    -- Handle menu hotkey (check this in main update loop)
end

---Render the menu
---@param gui any
function MenuSystem:render(gui)
    if self.current_state == MenuSystem.State.CLOSED then
        return
    end
    
    -- Note: GuiStartFrame is handled by the main update loop, not here
    -- Calling it twice breaks button functionality!
    
    -- Get screen dimensions
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    
    -- Render current state
    if self.current_state == MenuSystem.State.SPLASH then
        self:renderSplash(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.MAIN_MENU then
        self:renderMainMenu(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.SINGLEPLAYER_MODE_SELECT then
        self:renderSingleplayerModeSelect(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.MULTIPLAYER_SETUP then
        self:renderMultiplayerSetup(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.MULTIPLAYER_MODE_SELECT then
        self:renderMultiplayerModeSelect(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.GAME_SETTINGS then
        self:renderGameSettings(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.SETTINGS then
        self:renderSettings(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.GAME_CONTROLS then
        self:renderGameControls(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.WAITING_FOR_REVEAL then
        self:renderWaitingForReveal(gui, screen_width, screen_height)
    elseif self.current_state == MenuSystem.State.GAME_OVER then
        self:renderGameOver(gui, screen_width, screen_height)
    end
end

---Render info screen (first-time help)
function MenuSystem:renderSplash(gui, screen_width, screen_height)
    -- Make splash screen responsive to screen size
    local menu_width = math.min(600, screen_width - 100)
    local menu_height = math.min(400, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Draw background using multiple overlapping rectangles for visibility
    for i = 0, 4 do
        GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.2)
        GuiImage(gui, self:getID(), menu_x - i, menu_y - i, "data/ui_gfx/1x1_white.png", 1, menu_width + i*2, menu_height + i*2)
    end
    
    -- Draw border
    GuiColorSetForNextWidget(gui, 0.8, 0.8, 0.8, 1)
    GuiImage(gui, self:getID(), menu_x - 2, menu_y - 2, "data/ui_gfx/1x1_white.png", 1, menu_width + 4, 2) -- Top
    GuiImage(gui, self:getID(), menu_x - 2, menu_y + menu_height, "data/ui_gfx/1x1_white.png", 1, menu_width + 4, 2) -- Bottom
    GuiImage(gui, self:getID(), menu_x - 2, menu_y, "data/ui_gfx/1x1_white.png", 1, 2, menu_height) -- Left
    GuiImage(gui, self:getID(), menu_x + menu_width, menu_y, "data/ui_gfx/1x1_white.png", 1, 2, menu_height) -- Right
    
    local current_y = menu_y + 20
    
    -- Title
    GuiColorSetForNextWidget(gui, 1, 1, 0.2, 1) -- Yellow title
    GuiText(gui, 0, 0, "NOITA BINGO v0.1.0")
    
    
    -- Title
    GuiColorSetForNextWidget(gui, 1, 1, 0.2, 1) -- Yellow title
    GuiText(gui, menu_x + 200, current_y, "NOITA BINGO v0.1.0")
    current_y = current_y + 30
    
    -- Welcome message
    GuiColorSetForNextWidget(gui, 0.8, 1, 0.8, 1) -- Light green
    GuiText(gui, menu_x + 20, current_y, "Welcome to Noita Bingo!")
    current_y = current_y + 25
    
    -- Features
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1) -- White
    GuiText(gui, menu_x + 20, current_y, "Features:")
    current_y = current_y + 15
    GuiText(gui, menu_x + 30, current_y, "• Solo and multiplayer bingo games")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• Customizable objectives and categories")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• Multiple game modes (Traditional, Lockout, Rush)")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• Flexible board positioning")
    current_y = current_y + 20
    
    -- Controls
    GuiColorSetForNextWidget(gui, 1, 1, 0.2, 1) -- Yellow
    GuiText(gui, menu_x + 20, current_y, "Controls:")
    current_y = current_y + 15
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1) -- White
    GuiText(gui, menu_x + 30, current_y, "• F6 or T - Toggle this menu")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• F7 - Full screen board")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• F8 - Large board")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• F9 - Small board")
    current_y = current_y + 12
    GuiText(gui, menu_x + 30, current_y, "• F10 - Hide/show board")
    current_y = current_y + 20
    
    -- Multiplayer note
    if not self:isEvaisaMpAvailable() then
        GuiColorSetForNextWidget(gui, 1, 0.8, 0.2, 1) -- Orange
        GuiText(gui, menu_x + 20, current_y, "Install 'Noita Online' mod for multiplayer!")
        current_y = current_y + 20
    end
    
    -- "Don't show again" checkbox
    local checkbox_x = menu_x + 20
    local checkbox_y = menu_y + menu_height - 80
    
    local checkbox_id = self:getID()
    local checkbox_text = self.dont_show_splash_again and "[X] Don't show again" or "[ ] Don't show again"
    local checkbox_clicked = GuiButton(gui, checkbox_id, checkbox_x, checkbox_y, checkbox_text)
    
    if checkbox_clicked then
        self.dont_show_splash_again = not self.dont_show_splash_again
    end
    
    -- Continue button
    local continue_id = self:getID()
    local continue_button = GuiButton(gui, continue_id, menu_x + 200, menu_y + menu_height - 80, "Continue")
    local enter_pressed = InputIsKeyJustDown(40) -- Enter key (key code 40)
    
    if continue_button or enter_pressed then
        -- Only disable splash screen if checkbox is checked
        if self.dont_show_splash_again then
            ModSettingSet("noita_bingo.show_splash", "false")
            self.show_splash = false
        end
        
        self:navigate(MenuSystem.State.MAIN_MENU, false)
    end
    
    -- Instructions
    GuiColorSetForNextWidget(gui, 0.2, 1, 0.2, 1) -- Bright green
    GuiText(gui, menu_x + 160, menu_y + menu_height - 60, "Click Continue or press ENTER")
end

---Render main menu
function MenuSystem:renderMainMenu(gui, screen_width, screen_height)
    -- Make main menu responsive to screen size
    local menu_width = math.min(400, screen_width - 100)
    local menu_height = math.min(300, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Draw background using multiple overlapping rectangles
    for i = 0, 4 do
        GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.2)
        GuiImage(gui, self:getID(), menu_x - i, menu_y - i, "data/ui_gfx/1x1_white.png", 1, menu_width + i*2, menu_height + i*2)
    end
    
    -- Draw border
    GuiColorSetForNextWidget(gui, 0.8, 0.8, 0.8, 1)
    GuiImage(gui, self:getID(), menu_x - 2, menu_y - 2, "data/ui_gfx/1x1_white.png", 1, menu_width + 4, 2) -- Top
    GuiImage(gui, self:getID(), menu_x - 2, menu_y + menu_height, "data/ui_gfx/1x1_white.png", 1, menu_width + 4, 2) -- Bottom
    GuiImage(gui, self:getID(), menu_x - 2, menu_y, "data/ui_gfx/1x1_white.png", 1, 2, menu_height) -- Left
    GuiImage(gui, self:getID(), menu_x + menu_width, menu_y, "data/ui_gfx/1x1_white.png", 1, 2, menu_height) -- Right
    
    -- Title
    GuiColorSetForNextWidget(gui, 1, 1, 0.2, 1) -- Yellow
    GuiText(gui, menu_x + 130, menu_y + 20, "NOITA BINGO")
    
    local button_y = menu_y + 80
    local button_spacing = 50
    
    -- Menu buttons
    local sp_id = get_gui_id()
    local sp_clicked = GuiButton(gui, sp_id, menu_x + 130, button_y, "Singleplayer")
    if sp_clicked then
        self.is_multiplayer = false
        self:navigate(MenuSystem.State.SINGLEPLAYER_MODE_SELECT)
    end
    
    button_y = button_y + button_spacing
    local mp_id = get_gui_id()
    local mp_clicked = GuiButton(gui, mp_id, menu_x + 130, button_y, "Multiplayer")
    if mp_clicked then
        self.is_multiplayer = true
        self:navigate(MenuSystem.State.MULTIPLAYER_SETUP)
    end
    
    button_y = button_y + button_spacing
    local settings_id = get_gui_id()
    local settings_clicked = GuiButton(gui, settings_id, menu_x + 130, button_y, "Settings")
    if settings_clicked then
        self:navigate(MenuSystem.State.SETTINGS)
    end
end

---Render singleplayer mode selection
function MenuSystem:renderSingleplayerModeSelect(gui, screen_width, screen_height)
    local menu_width = math.min(400, screen_width - 100)
    local menu_height = math.min(400, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    
    -- Title
    GuiText(gui, menu_x + 120, menu_y + 20, "Select Game Mode")
    
    -- Mode buttons
    local button_y = menu_y + 60
    local button_spacing = 70
    
    if self:renderButton(gui, menu_x + 100, button_y, "Traditional Bingo") then
        self.selected_mode = MenuSystem.GameMode.TRADITIONAL
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    GuiText(gui, menu_x + 100, button_y + 20, "Get 5 in a row (horizontal, vertical, or diagonal)")
    
    button_y = button_y + button_spacing
    if self:renderButton(gui, menu_x + 100, button_y, "Blackout") then
        self.selected_mode = MenuSystem.GameMode.BLACKOUT
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    GuiText(gui, menu_x + 100, button_y + 20, "Complete all squares on the board")
    
    button_y = button_y + button_spacing
    if self:renderButton(gui, menu_x + 100, button_y, "Rush") then
        self.selected_mode = MenuSystem.GameMode.RUSH
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    GuiText(gui, menu_x + 100, button_y + 20, "Complete objectives before time runs out")
    
    -- Back button
    if self:renderButton(gui, menu_x + 20, menu_y + menu_height - 40, "Back") then
        self:goBack()
    end
end

---Start a bingo game
function MenuSystem:startGame()
    GamePrint("[BINGO] Starting game with " .. self.game_settings.board_size .. "x" .. self.game_settings.board_size .. " board")
    print("Bingo: Starting game...")
    
    -- Check if required systems are loaded
    if not BingoCore or not BingoCore.BingoBoard then
        GamePrint("[BINGO] ERROR: BingoCore.BingoBoard not loaded!")
        return
    end
    
    if not BingoConfig or not BingoConfig.category_system then
        GamePrint("[BINGO] ERROR: BingoConfig.category_system not loaded!")
        return
    end
    
    if not BingoCore.Game then
        GamePrint("[BINGO] ERROR: BingoCore.Game not loaded!")
        return
    end
    
    -- Select objectives first
    local num_objectives = self.game_settings.board_size * self.game_settings.board_size
    local objectives = BingoConfig.category_system:selectObjectives(num_objectives)
    print("Bingo: Selected " .. #objectives .. " objectives")
    GamePrint("[BINGO] Selected " .. #objectives .. " objectives")
    
    if #objectives == 0 then
        GamePrint("[BINGO] ERROR: No objectives selected!")
        return
    end
    
    -- Create game state (Game constructor handles board creation)
    local game = BingoCore.Game.new({
        objectives = objectives,
        mode = self.selected_mode or "traditional",
        size = self.game_settings.board_size,
        enable_rewards = self.game_settings.enable_rewards
    })
    
    print("Bingo: Game created successfully")
    GamePrint("[BINGO] Game started!")
    
    -- Set the global game state
    BingoBoardState.current_game = game
    
    -- Close the menu to show the board
    self:close()
end

---Render multiplayer setup
function MenuSystem:renderMultiplayerSetup(gui, screen_width, screen_height)
    local menu_width = math.min(500, screen_width - 100)
    local menu_height = math.min(400, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    
    -- Title
    GuiText(gui, menu_x + 150, menu_y + 20, "Multiplayer Setup")
    
    local content_y = menu_y + 60
    
    -- Check for evaisa.mp framework
    local has_evaisa_mp = self:isEvaisaMpAvailable()
    local evaisa_mod_enabled = ModIsEnabled("evaisa.mp")
    
    -- Debug info
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, menu_x + 20, content_y, "Debug: evaisa.mp mod enabled: " .. tostring(evaisa_mod_enabled))
    content_y = content_y + 15
    GuiText(gui, menu_x + 20, content_y, "Debug: Framework available: " .. tostring(has_evaisa_mp))
    content_y = content_y + 20
    
    if has_evaisa_mp then
        GuiColorSetForNextWidget(gui, 0.2, 1, 0.2, 1)
        GuiText(gui, menu_x + 20, content_y, "evaisa.mp framework detected!")
        content_y = content_y + 20
        
        -- Auto-select evaisa.mp as the multiplayer type
        self.multiplayer_type = MenuSystem.MultiplayerType.EVAISA_MP
        
        -- Check if already in a lobby
        if self:checkEvaisaMpConnection() then
            GuiColorSetForNextWidget(gui, 0.2, 1, 0.2, 1)
            GuiText(gui, menu_x + 20, content_y, "Connected to lobby! You can proceed to game mode selection.")
            content_y = content_y + 30
            
            if GuiButton(gui, self:getID(), menu_x + 120, content_y, "Continue to Game Mode Selection") then
                self:navigate(MenuSystem.State.MULTIPLAYER_MODE_SELECT)
            end
            content_y = content_y + 60
        else
            GuiColorSetForNextWidget(gui, 1, 0.8, 0.2, 1)
            GuiText(gui, menu_x + 20, content_y, "To play multiplayer:")
            content_y = content_y + 20
            GuiText(gui, menu_x + 30, content_y, "1. Press ESC to open the pause menu")
            content_y = content_y + 15
            GuiText(gui, menu_x + 30, content_y, "2. Use 'Noita Online' to create/join a lobby")
            content_y = content_y + 15
            GuiText(gui, menu_x + 30, content_y, "3. Select 'Noita Bingo' as the gamemode")
            content_y = content_y + 15
            GuiText(gui, menu_x + 30, content_y, "4. Configure settings and start the game")
            content_y = content_y + 25
            
            GuiColorSetForNextWidget(gui, 0.8, 0.8, 1, 1)
            GuiText(gui, menu_x + 20, content_y, "Note: Multiplayer bingo is managed through Noita Online lobbies.")
            content_y = content_y + 15
            GuiText(gui, menu_x + 20, content_y, "This menu is for singleplayer configuration only.")
            content_y = content_y + 30
        end
        content_y = content_y + 20
    elseif evaisa_mod_enabled then
        GuiColorSetForNextWidget(gui, 1, 0.8, 0.2, 1)
        GuiText(gui, menu_x + 20, content_y, "evaisa.mp mod enabled but framework failed to initialize")
        content_y = content_y + 15
        GuiColorSetForNextWidget(gui, 0.8, 0.8, 0.8, 1)
        GuiText(gui, menu_x + 20, content_y, "Common causes: NoitaPatcher version mismatch, corrupted files")
        content_y = content_y + 15
        GuiText(gui, menu_x + 20, content_y, "Check console for 'Couldn't find version string' error")
        content_y = content_y + 25
        
        -- Offer manual workaround for testing
        if GuiButton(gui, self:getID(), menu_x + 80, content_y, "Enable Manual Multiplayer Mode") then
            GuiText(gui, menu_x + 20, content_y + 30, "This enables multiplayer UI without framework validation.")
            GuiText(gui, menu_x + 20, content_y + 45, "Use this to test the bingo mod's multiplayer interface.")
            self.multiplayer_type = MenuSystem.MultiplayerType.EVAISA_MP
            self:navigate(MenuSystem.State.MULTIPLAYER_MODE_SELECT)
        end
        
        content_y = content_y + 80
        GuiColorSetForNextWidget(gui, 0.6, 0.6, 0.6, 1)
        GuiText(gui, menu_x + 20, content_y, "Troubleshooting steps:")
        content_y = content_y + 15
        GuiText(gui, menu_x + 30, content_y, "1. Restart Noita completely")
        content_y = content_y + 12
        GuiText(gui, menu_x + 30, content_y, "2. Check evaisa.mp mod version compatibility")
        content_y = content_y + 12
        GuiText(gui, menu_x + 30, content_y, "3. Verify all files are present in mods/evaisa.mp/")
        
        content_y = content_y + 25
        if GuiButton(gui, self:getID(), menu_x + 120, content_y, "Enable Manual Multiplayer Mode") then
            GuiText(gui, menu_x + 20, content_y + 30, "This enables multiplayer UI without framework validation.")
            GuiText(gui, menu_x + 20, content_y + 45, "Use this to test the bingo mod's multiplayer interface.")
            self.multiplayer_type = MenuSystem.MultiplayerType.EVAISA_MP
            self:navigate(MenuSystem.State.MULTIPLAYER_MODE_SELECT)
        end
        content_y = content_y + 80
    else
        GuiColorSetForNextWidget(gui, 1, 0.6, 0.2, 1)
        GuiText(gui, menu_x + 20, content_y, "evaisa.mp framework not detected")
        content_y = content_y + 20
        GuiColorSetForNextWidget(gui, 0.8, 0.8, 0.8, 1)
        GuiText(gui, menu_x + 20, content_y, "Install 'Noita Online' mod for multiplayer support")
        content_y = content_y + 25
    end
    
    -- HTTP Fallback option (only show if evaisa.mp not available)
    if not has_evaisa_mp then
        GuiColorSetForNextWidget(gui, 0.8, 0.8, 0.8, 1)
        GuiText(gui, menu_x + 20, content_y, "Alternative Option:")
        content_y = content_y + 20
    end
    
    if GuiButton(gui, self:getID(), menu_x + 120, content_y, has_evaisa_mp and "Use HTTP Server (Advanced)" or "Use HTTP Server (Fallback)") then
        self.multiplayer_type = MenuSystem.MultiplayerType.HTTP_FALLBACK
        
        -- Check if server is configured
        local server_url = ModSettingGet("noita_bingo.http_server_url")
        if server_url and server_url ~= "" then
            -- TODO: Test connection to server
            self:navigate(MenuSystem.State.MULTIPLAYER_MODE_SELECT)
        else
            -- Show setup instructions
            content_y = content_y + 60
            GuiColorSetForNextWidget(gui, 1, 0.8, 0.2, 1)
            GuiText(gui, menu_x + 20, content_y, "HTTP Server Setup Required:")
            content_y = content_y + 20
            GuiText(gui, menu_x + 30, content_y, "1. Set up your own server (see GitHub docs)")
            content_y = content_y + 15
            GuiText(gui, menu_x + 30, content_y, "2. Enter server URL in Settings")
            content_y = content_y + 15
            GuiText(gui, menu_x + 30, content_y, "3. Return here once configured")
        end
    end
    
    -- Add spacing and tip
    content_y = content_y + 30
    
    -- Show preference info
    if has_evaisa_mp then
        GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
        GuiText(gui, menu_x + 20, content_y, "Tip: Noita Online is the recommended multiplayer method.")
        content_y = content_y + 15
        GuiText(gui, menu_x + 20, content_y, "HTTP fallback is for advanced users or custom servers.")
    end
    
    -- Back button
    if GuiButton(gui, self:getID(), menu_x + 20, menu_y + menu_height - 40, "Back") then
        self:goBack()
    end
end

---Check if connected to evaisa.mp lobby
---@return boolean
function MenuSystem:checkEvaisaMpConnection()
    -- Check if connected to evaisa.mp lobby
    if not self:isEvaisaMpAvailable() then
        return false
    end
    
    -- Check if we're in an active lobby
    return lobby_code ~= nil
end

---Render multiplayer mode selection
function MenuSystem:renderMultiplayerModeSelect(gui, screen_width, screen_height)
    local menu_width = math.min(500, screen_width - 100)
    local menu_height = math.min(450, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    
    -- Title
    GuiText(gui, menu_x + 150, menu_y + 20, "Select Game Mode")
    
    -- Set competitive mode (co-op planned for post-release)
    self.mp_mode_type = "compete"
    
    -- Show multiplayer info
    local content_y = menu_y + 60
    GuiColorSetForNextWidget(gui, 0.8, 0.8, 1, 1)
    GuiText(gui, menu_x + 20, content_y, "Multiplayer Mode: Competitive")
    content_y = content_y + 20
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, menu_x + 20, content_y, "Race to complete objectives in separate runs")
    content_y = content_y + 30
    
    GuiColorSetForNextWidget(gui, 0.6, 0.6, 0.6, 1)
    GuiText(gui, menu_x + 20, content_y, "Note: Co-op mode is planned for a future update")
    content_y = content_y + 40
    GuiText(gui, menu_x + 20, content_y, "Game Mode:")
    content_y = content_y + 25
    
    -- Game mode buttons
    local button_spacing = 70
    
    if GuiButton(gui, self:getID(), menu_x + 100, content_y, "Traditional Bingo") then
        self.selected_mode = MenuSystem.GameMode.TRADITIONAL
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    GuiText(gui, menu_x + 100, content_y + 20, "Get 5 in a row (horizontal, vertical, or diagonal)")
    
    content_y = content_y + button_spacing
    if GuiButton(gui, self:getID(), menu_x + 100, content_y, "Lockout") then
        self.selected_mode = MenuSystem.GameMode.LOCKOUT
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    GuiText(gui, menu_x + 100, content_y + 20, "Compete - once claimed, others can't claim it")
    
    -- Back button
    if GuiButton(gui, self:getID(), menu_x + 20, menu_y + menu_height - 40, "Back") then
        self:goBack()
    end
end

---Render game settings
function MenuSystem:renderGameSettings(gui, screen_width, screen_height)
    if GameGetFrameNum() % 120 == 0 then
        GamePrint("[BINGO] renderGameSettings is being called")
    end
    
    -- Make menu responsive to screen size with constraints
    local menu_width = math.min(700, screen_width - 100)  -- Leave 100px margin
    local menu_height = math.min(500, screen_height - 100) -- Leave 100px margin
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    
    -- Title
    GuiText(gui, menu_x + 250, menu_y + 20, "Game Settings")
    
    local content_y = menu_y + 50
    local left_col = menu_x + 20
    local right_col = menu_x + 360
    
    -- Preset selection
    GuiText(gui, left_col, content_y, "Settings Preset:")
    -- TODO: Implement dropdown for presets
    GuiText(gui, left_col + 120, content_y, self.current_preset_name)
    
    if GuiButton(gui, self:getID(), left_col + 250, content_y - 5, "Save As...") then
        -- TODO: Open save preset dialog
    end
    
    if GuiButton(gui, self:getID(), left_col + 340, content_y - 5, "Rename") then
        -- TODO: Open rename dialog
    end
    
    content_y = content_y + 35
    
    -- Category Limits (only for non-Rush modes)
    if self.selected_mode ~= MenuSystem.GameMode.RUSH then
        GuiText(gui, left_col, content_y, "Category Limits:")
        content_y = content_y + 20
        
        local max_limit = self.game_settings.board_size * self.game_settings.board_size
        local categories = {"bloodshed", "deaths", "wandbuilding", "inventory", "exploration", "events_misc"}
        local total_limits = 0
        
        for _, category in ipairs(categories) do
            local limit = self.game_settings.category_limits[category]
            if limit then
                total_limits = total_limits + limit
            end
        end
        
        for _, category in ipairs(categories) do
            GuiText(gui, left_col + 10, content_y, category:sub(1,1):upper() .. category:sub(2) .. ":")
            
            local limit = self.game_settings.category_limits[category]
            local limit_str = limit and tostring(limit) or "No Limit"
            
            -- Decrement button
            if GuiButton(gui, self:getID(), left_col + 120, content_y - 5, "-") then
                if limit and limit > 0 then
                    self.game_settings.category_limits[category] = limit - 1
                end
            end
            
            GuiText(gui, left_col + 145, content_y, limit_str)
            
            -- Increment button
            if GuiButton(gui, self:getID(), left_col + 220, content_y - 5, "+") then
                if not limit then
                    self.game_settings.category_limits[category] = 1
                elseif total_limits < max_limit then
                    self.game_settings.category_limits[category] = limit + 1
                end
            end
            
            -- No limit button
            if GuiButton(gui, self:getID(), left_col + 250, content_y - 5, "No Limit") then
                self.game_settings.category_limits[category] = nil
            end
            
            content_y = content_y + 25
        end
        
        GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
        GuiText(gui, left_col + 10, content_y, string.format("Total: %d / %d", total_limits, max_limit))
        content_y = content_y + 30
    end
    
    -- Right column - Timer settings
    content_y = menu_y + 85
    
    GuiText(gui, right_col, content_y, "Timer Settings:")
    content_y = content_y + 25
    
    -- Timer mode (Elapsed/Countdown)
    if self.selected_mode == MenuSystem.GameMode.RUSH then
        GuiText(gui, right_col + 10, content_y, "Mode: Countdown (Rush)")
        self.game_settings.timer_mode = "countdown"
        content_y = content_y + 25
    else
        GuiText(gui, right_col + 10, content_y, "Mode:")
        
        if GuiButton(gui, self:getID(), right_col + 70, content_y - 5, 
            self.game_settings.timer_mode == "elapsed" and "[X] Elapsed" or "[ ] Elapsed") then
            self.game_settings.timer_mode = "elapsed"
        end
        
        if GuiButton(gui, self:getID(), right_col + 170, content_y - 5,
            self.game_settings.timer_mode == "countdown" and "[X] Countdown" or "[ ] Countdown") then
            self.game_settings.timer_mode = "countdown"
        end
        content_y = content_y + 25
    end
    
    -- Timer enable/disable (Elapsed only)
    if self.game_settings.timer_mode == "elapsed" then
        if GuiButton(gui, self:getID(), right_col + 10, content_y - 5,
            self.game_settings.timer_enabled and "[X] Timer Enabled" or "[ ] Timer Disabled") then
            self.game_settings.timer_enabled = not self.game_settings.timer_enabled
        end
        content_y = content_y + 25
    end
    
    -- Countdown duration (Countdown only)
    if self.game_settings.timer_mode == "countdown" then
        GuiText(gui, right_col + 10, content_y, "Duration:")
        content_y = content_y + 20
        
        local durations = {
            {label = "1 Hour", seconds = 3600},
            {label = "45 Minutes", seconds = 2700},
            {label = "30 Minutes", seconds = 1800},
            {label = "15 Minutes", seconds = 900},
            {label = "Unlimited", seconds = 0},
            {label = "Custom", seconds = -1}
        }
        
        for _, duration in ipairs(durations) do
            local selected = false
            if duration.seconds == -1 then
                -- Custom check
                selected = not (self.game_settings.countdown_duration == 0 or
                    self.game_settings.countdown_duration == 3600 or
                    self.game_settings.countdown_duration == 2700 or
                    self.game_settings.countdown_duration == 1800 or
                    self.game_settings.countdown_duration == 900)
            else
                selected = self.game_settings.countdown_duration == duration.seconds
            end
            
            if GuiButton(gui, self:getID(), right_col + 20, content_y - 5,
                selected and "[X] " .. duration.label or "[ ] " .. duration.label) then
                if duration.seconds == -1 then
                    -- Custom - open input
                    -- TODO: Text input for custom duration
                    self.game_settings.countdown_duration = 600 -- 10 min default
                elseif duration.seconds == 0 then
                    -- Unlimited - disable timer
                    self.game_settings.countdown_duration = 0
                    self.game_settings.timer_enabled = false
                else
                    self.game_settings.countdown_duration = duration.seconds
                    self.game_settings.timer_enabled = true
                end
            end
            content_y = content_y + 20
        end
    end
    
    content_y = content_y + 20
    
    -- Reveal countdown
    if GuiButton(gui, self:getID(), right_col + 10, content_y - 5,
        self.game_settings.reveal_countdown and "[X] Reveal Countdown" or "[ ] Reveal Countdown") then
        self.game_settings.reveal_countdown = not self.game_settings.reveal_countdown
    end
    content_y = content_y + 25
    
    if self.game_settings.reveal_countdown then
        GuiText(gui, right_col + 20, content_y, "Countdown: " .. tostring(self.game_settings.reveal_countdown_duration) .. "s")
        -- TODO: Add increment/decrement buttons
        content_y = content_y + 25
    end
    
    -- Rush-specific settings
    if self.selected_mode == MenuSystem.GameMode.RUSH then
        content_y = content_y + 10
        GuiText(gui, right_col, content_y, "Rush Settings:")
        content_y = content_y + 25
        
        GuiText(gui, right_col + 10, content_y, "Objectives at once:")
        
        if GuiButton(gui, self:getID(), right_col + 180, content_y - 5, "-") then
            if self.game_settings.rush_objective_count > 3 then
                self.game_settings.rush_objective_count = self.game_settings.rush_objective_count - 1
            end
        end
        
        GuiText(gui, right_col + 205, content_y, tostring(self.game_settings.rush_objective_count))
        
        if GuiButton(gui, self:getID(), right_col + 230, content_y - 5, "+") then
            if self.game_settings.rush_objective_count < 9 then
                self.game_settings.rush_objective_count = self.game_settings.rush_objective_count + 1
            end
        end
    end
    
    -- Start/Back buttons - make them more visible
    local button_y = menu_y + menu_height - 50
    
    -- Debug: Show where buttons should be
    GuiColorSetForNextWidget(gui, 1, 1, 0, 1) -- Yellow debug text
    GuiText(gui, menu_x + 200, button_y - 30, "Button area: " .. button_y .. " (menu_y=" .. menu_y .. ", height=" .. menu_height .. ")")
    
    -- Draw button areas for debugging
    GuiColorSetForNextWidget(gui, 1, 0, 0, 0.3) -- Semi-transparent red
    GuiImage(gui, self:getID(), menu_x + 15, button_y - 5, "data/ui_gfx/1x1_white.png", 1, 80, 30)
    GuiColorSetForNextWidget(gui, 0, 1, 0, 0.3) -- Semi-transparent green  
    GuiImage(gui, self:getID(), menu_x + menu_width - 125, button_y - 5, "data/ui_gfx/1x1_white.png", 1, 100, 30)
    
    -- Back button
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1) -- White text
    if GuiButton(gui, self:getID(), menu_x + 20, button_y, "Back") then
        self:goBack()
    end
    
    -- Start Game button  
    GuiColorSetForNextWidget(gui, 0.2, 1, 0.2, 1) -- Bright green
    if self:renderButton(gui, menu_x + menu_width - 120, button_y, "Start Game") then
        GamePrint("[BINGO] *** START GAME BUTTON CLICKED ***")
        self:startGame()
    end
end

---Start the game with current settings
function MenuSystem:startGame()
    GamePrint("[BINGO] MenuSystem:startGame() called!")
    print("DEBUG: MenuSystem:startGame() called")
    
    local success, err = pcall(function()
        GamePrint("[BINGO] About to call createGame with board_size=" .. tostring(self.game_settings.board_size))
        self:createGame(self.game_settings)
        GamePrint("[BINGO] createGame completed successfully")
    end)
    
    if not success then
        GamePrint("[BINGO] ERROR in createGame: " .. tostring(err))
        print("ERROR in createGame: " .. tostring(err))
        return
    end
    
    -- Check if game was created
    if not BingoBoardState.current_game then
        GamePrint("[BINGO] ERROR: current_game was not set!")
        print("ERROR: current_game was not set after createGame")
        return
    end
    
    GamePrint("[BINGO] Game created successfully, closing menu...")
    print("DEBUG: Game created successfully")
    
    -- Close menu to show the board
    self:close()
    
    -- Verify menu is closed
    if self:isOpen() then
        GamePrint("[BINGO] WARNING: Menu is still open after close()")
    else
        GamePrint("[BINGO] Menu closed successfully")
    end
end

---Create a game with specified settings (used by multiplayer integration)
---@param settings table Game settings
function MenuSystem:createGame(settings)
    GamePrint("[BINGO] MenuSystem:createGame() called")
    print("DEBUG: createGame started")
    
    -- Parse settings
    local board_size = 5
    if settings.board_size then
        if settings.board_size == "3x3" then board_size = 3
        elseif settings.board_size == "4x4" then board_size = 4
        elseif settings.board_size == "5x5" then board_size = 5
        elseif settings.board_size == "6x6" then board_size = 6
        else board_size = tonumber(string.match(settings.board_size, "(%d+)")) or 5 end
    elseif settings.board_size_num then
        board_size = settings.board_size_num
    end
    
    GamePrint("[BINGO] Board size: " .. board_size)
    
    local game_mode = settings.game_mode or settings.selected_mode or self.selected_mode or "traditional"
    GamePrint("[BINGO] Game mode: " .. game_mode)
    
    local is_multiplayer = settings.is_multiplayer
    if is_multiplayer == nil then
        is_multiplayer = self.is_multiplayer and self.multiplayer_type == MenuSystem.MultiplayerType.EVAISA_MP
    end
    GamePrint("[BINGO] Is multiplayer: " .. tostring(is_multiplayer))
    
    -- Check if required systems exist
    if not BingoCore or not BingoCore.BoardGenerator then
        GamePrint("[BINGO] ERROR: BingoCore.BoardGenerator not available!")
        print("ERROR: BingoCore.BoardGenerator is nil")
        return nil
    end
    
    -- IMPORTANT: Update the global settings before board generation!
    if BingoConfig and BingoConfig.settings then
        GamePrint("[BINGO] Updating BingoConfig.settings with board_size=" .. board_size)
        BingoConfig.settings:set("board_size", board_size)
        
        -- Also update category limits if provided
        if settings.category_limits then
            for category, limit in pairs(settings.category_limits) do
                BingoConfig.settings:set("category_limits." .. category, limit)
            end
        end
    else
        GamePrint("[BINGO] WARNING: BingoConfig.settings not available!")
    end
    
    GamePrint("[BINGO] About to call BoardGenerator.createNewGame")
    
    -- Generate board based on settings
    local game = BingoCore.BoardGenerator.createNewGame(
        game_mode,
        is_multiplayer
    )
    
    if not game then
        GamePrint("[BINGO] ERROR: BoardGenerator returned nil!")
        print("ERROR: BoardGenerator.createNewGame returned nil")
        return nil
    end
    
    GamePrint("[BINGO] Game object created, verifying board...")
    
    -- Verify board was created
    if game.board then
        GamePrint("[BINGO] Board exists, size=" .. tostring(game.board.size))
    else
        GamePrint("[BINGO] WARNING: game.board is nil!")
    end
    
    -- Apply additional settings to game
    if settings.difficulty then
        game.difficulty = settings.difficulty
    end
    if settings.seed and settings.seed ~= "" then
        game.seed = settings.seed
    end
    
    -- Set current game
    BingoBoardState.current_game = game
    GamePrint("[BINGO] Game set in BingoBoardState.current_game")
    
    print("MenuSystem: Created game - Mode: " .. game_mode .. ", Size: " .. board_size .. "x" .. board_size .. ", Multiplayer: " .. tostring(is_multiplayer))
end

---Render settings menu
function MenuSystem:renderSettings(gui, screen_width, screen_height)
    local menu_width = math.min(500, screen_width - 100)
    local menu_height = math.min(400, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    
    -- Title
    GuiText(gui, menu_x + 200, menu_y + 20, "Settings")
    
    local content_y = menu_y + 60
    
    -- Disable splash screen
    if GuiButton(gui, self:getID(), menu_x + 20, content_y - 5,
        self.show_splash and "[ ] Disable Info Splash Screen" or "[X] Disable Info Splash Screen") then
        self.show_splash = not self.show_splash
        ModSettingSet("noita_bingo.show_splash", self.show_splash and "true" or "false")
    end
    content_y = content_y + 35
    
    -- Decouple boards
    local decouple = ModSettingGet("noita_bingo.decouple_boards") == "true"
    if GuiButton(gui, self:getID(), menu_x + 20, content_y - 5,
        decouple and "[X] Decouple Boards" or "[ ] Decouple Boards") then
        ModSettingSet("noita_bingo.decouple_boards", decouple and "false" or "true")
    end
    GuiText(gui, menu_x + 30, content_y + 15, "Separate positions for Large/Small boards")
    content_y = content_y + 50
    
    -- HTTP Server URL (for fallback multiplayer)
    GuiText(gui, menu_x + 20, content_y, "HTTP Server URL:")
    content_y = content_y + 20
    local server_url = ModSettingGet("noita_bingo.http_server_url") or ""
    GuiText(gui, menu_x + 30, content_y, server_url ~= "" and server_url or "(Not configured)")
    -- TODO: Text input for URL
    content_y = content_y + 35
    
    -- Multiplayer preference
    GuiText(gui, menu_x + 20, content_y, "Preferred Multiplayer:")
    content_y = content_y + 20
    
    local mp_pref = ModSettingGet("noita_bingo.mp_preference") or "evaisa_mp"
    
    if GuiButton(gui, self:getID(), menu_x + 30, content_y - 5,
        mp_pref == "evaisa_mp" and "[X] Noita Online (evaisa.mp)" or "[ ] Noita Online (evaisa.mp)") then
        ModSettingSet("noita_bingo.mp_preference", "evaisa_mp")
    end
    
    content_y = content_y + 25
    if GuiButton(gui, self:getID(), menu_x + 30, content_y - 5,
        mp_pref == "http" and "[X] HTTP Server" or "[ ] HTTP Server") then
        ModSettingSet("noita_bingo.mp_preference", "http")
    end
    
    content_y = content_y + 40
    
    -- Hotkeys section
    GuiText(gui, menu_x + 20, content_y, "Hotkeys:")
    content_y = content_y + 20
    GuiText(gui, menu_x + 30, content_y, "Open Menu: F6 (not rebindable)")
    content_y = content_y + 20
    GuiText(gui, menu_x + 30, content_y, "Pause Timer: (configure in-game)")
    
    -- Back button
    if GuiButton(gui, self:getID(), menu_x + 20, menu_y + menu_height - 40, "Back") then
        self:goBack()
    end
end

---Render game controls overlay (shown when ESC menu is open during game)
---@param gui any
---@param is_host boolean
---@param is_multiplayer boolean
function MenuSystem:renderGameControlsOverlay(gui, is_host, is_multiplayer)
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    
    -- Position in corner
    local box_width = 200
    local box_height = is_multiplayer and 150 or 100
    local box_x = screen_width - box_width - 20
    local box_y = 20
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), box_x, box_y, box_width, box_height, 0)
    
    -- Title
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
    GuiText(gui, box_x + 60, box_y + 10, "Bingo Controls")
    
    local button_y = box_y + 35
    local button_spacing = 35
    
    -- Pause/Resume Timer (host only in MP)
    if not is_multiplayer or is_host then
        local timer_paused = BingoBoardState.timer_paused or false
        if GuiButton(gui, self:getID(), box_x + 20, button_y, 
            timer_paused and "Resume Timer" or "Pause Timer") then
            BingoBoardState.timer_paused = not timer_paused
        end
        button_y = button_y + button_spacing
    end
    
    -- Concede (with confirmation)
    if is_multiplayer then
        if GuiButton(gui, self:getID(), box_x + 20, button_y, "Concede") then
            self.show_concede_confirm = true
        end
        button_y = button_y + button_spacing
        
        -- Concede confirmation
        if self.show_concede_confirm then
            GuiColorSetForNextWidget(gui, 0.8, 0.2, 0.2, 0.95)
            GuiImageNinePiece(gui, self:getID(), box_x - 50, button_y, 300, 80, 0)
            
            GuiText(gui, box_x, button_y + 10, "Concede the Match")
            GuiText(gui, box_x + 20, button_y + 30, "(You will lose)")
            
            if GuiButton(gui, self:getID(), box_x + 10, button_y + 50, "Concede") then
                self:concedeGame()
                self.show_concede_confirm = false
            end
            
            if GuiButton(gui, self:getID(), box_x + 120, button_y + 50, "Cancel") then
                self.show_concede_confirm = false
            end
        end
    end
    
    -- End Game (host only)
    if not is_multiplayer or is_host then
        if GuiButton(gui, self:getID(), box_x + 20, button_y, "End Game (Tie)") then
            self:endGameTie()
        end
    end
end

---Concede the current game
function MenuSystem:concedeGame()
    if BingoBoardState.current_game then
        BingoBoardState.current_game.completed = true
        -- TODO: Set winner as opponent
        self:navigate(MenuSystem.State.GAME_OVER, false)
    end
end

---End game as a tie
function MenuSystem:endGameTie()
    if BingoBoardState.current_game then
        BingoBoardState.current_game.completed = true
        -- TODO: Set as tie
        self:navigate(MenuSystem.State.GAME_OVER, false)
    end
end

---Render waiting for reveal screen
function MenuSystem:renderWaitingForReveal(gui, screen_width, screen_height)
    -- This is handled by the board renderer with blur overlay
    -- Only show message for non-host players in multiplayer
    if self.is_multiplayer and not self.is_host then
        local msg_width = 300
        local msg_height = 80
        local msg_x = (screen_width - msg_width) / 2
        local msg_y = (screen_height - msg_height) / 2
        
        GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.9)
        GuiImageNinePiece(gui, self:getID(), msg_x, msg_y, msg_width, msg_height, 0)
        
        GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
        GuiText(gui, msg_x + 40, msg_y + 20, "Waiting for host to")
        GuiText(gui, msg_x + 60, msg_y + 40, "reveal the board...")
    end
end

---Render game over screen
function MenuSystem:renderGameOver(gui, screen_width, screen_height)
    local menu_width = math.min(600, screen_width - 100)
    local menu_height = math.min(500, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Background
    GuiColorSetForNextWidget(gui, 0.1, 0.1, 0.1, 0.95)
    GuiImageNinePiece(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, 0, "data/ui_gfx/decorations/9piece0_gray.png")
    
    -- Title
    GuiColorSetForNextWidget(gui, 1, 0.8, 0.2, 1)
    GuiText(gui, menu_x + 230, menu_y + 20, "GAME OVER")
    
    local content_y = menu_y + 60
    local game = BingoBoardState.current_game
    
    if not game then
        GuiText(gui, menu_x + 200, content_y, "No game data")
        return
    end
    
    -- Display stats based on game mode
    if self.selected_mode == MenuSystem.GameMode.TRADITIONAL then
        self:renderTraditionalStats(gui, menu_x, content_y, game)
    elseif self.selected_mode == MenuSystem.GameMode.BLACKOUT then
        self:renderBlackoutStats(gui, menu_x, content_y, game)
    elseif self.selected_mode == MenuSystem.GameMode.LOCKOUT then
        self:renderLockoutStats(gui, menu_x, content_y, game)
    elseif self.selected_mode == MenuSystem.GameMode.RUSH then
        self:renderRushStats(gui, menu_x, content_y, game)
    end
    
    -- Buttons (host only in MP)
    if not self.is_multiplayer or self.is_host then
        local button_y = menu_y + menu_height - 100
        
        if GuiButton(gui, self:getID(), menu_x + 50, button_y, "Change Game Mode") then
            self:navigate(self.is_multiplayer and MenuSystem.State.MULTIPLAYER_MODE_SELECT or MenuSystem.State.SINGLEPLAYER_MODE_SELECT, false)
        end
        
        if GuiButton(gui, self:getID(), menu_x + 220, button_y, "Change Settings") then
            self:navigate(MenuSystem.State.GAME_SETTINGS, false)
        end
        
        if GuiButton(gui, self:getID(), menu_x + 400, button_y, "Run It Back") then
            self:startGame()
        end
        
        button_y = button_y + 40
        if GuiButton(gui, self:getID(), menu_x + 220, button_y, "Main Menu") then
            self:navigate(MenuSystem.State.MAIN_MENU, false)
        end
    else
        -- Non-host just waits
        GuiText(gui, menu_x + 180, menu_y + menu_height - 80, "Waiting for host...")
    end
end

---Render traditional bingo stats
function MenuSystem:renderTraditionalStats(gui, menu_x, content_y, game)
    GuiText(gui, menu_x + 20, content_y, "Winner: " .. (game.winner or "You!"))
    content_y = content_y + 25
    
    local elapsed_time = game.elapsed_time or 0
    GuiText(gui, menu_x + 20, content_y, string.format("Time: %02d:%02d", 
        math.floor(elapsed_time / 60), elapsed_time % 60))
    content_y = content_y + 25
    
    -- Count lines completed
    local lines = self:countCompletedLines(game.board)
    GuiText(gui, menu_x + 20, content_y, "Lines Completed: " .. tostring(lines))
    content_y = content_y + 40
    
    -- Win/Loss record
    if self.is_multiplayer then
        self:renderWinLossRecord(gui, menu_x + 20, content_y)
    end
end

---Render blackout stats
function MenuSystem:renderBlackoutStats(gui, menu_x, content_y, game)
    local elapsed_time = game.elapsed_time or 0
    GuiText(gui, menu_x + 20, content_y, string.format("Time: %02d:%02d",
        math.floor(elapsed_time / 60), elapsed_time % 60))
    content_y = content_y + 25
    
    local completed = self:countCompletedSquares(game.board)
    local total = game.board.size * game.board.size
    GuiText(gui, menu_x + 20, content_y, string.format("Objectives: %d / %d", completed, total))
    content_y = content_y + 25
    
    local lines = self:countCompletedLines(game.board)
    GuiText(gui, menu_x + 20, content_y, "Lines Completed: " .. tostring(lines))
end

---Render lockout stats
function MenuSystem:renderLockoutStats(gui, menu_x, content_y, game)
    GuiText(gui, menu_x + 20, content_y, "Winner: " .. (game.winner or "Tie"))
    content_y = content_y + 25
    
    local elapsed_time = game.elapsed_time or 0
    GuiText(gui, menu_x + 20, content_y, string.format("Time: %02d:%02d",
        math.floor(elapsed_time / 60), elapsed_time % 60))
    content_y = content_y + 35
    
    GuiText(gui, menu_x + 20, content_y, "Squares Claimed:")
    content_y = content_y + 20
    
    -- Show each player's score
    if game.player_scores then
        for player_id, score in pairs(game.player_scores) do
            GuiText(gui, menu_x + 30, content_y, string.format("%s: %d", player_id, score))
            content_y = content_y + 20
        end
    end
    
    content_y = content_y + 20
    if self.is_multiplayer then
        self:renderWinLossRecord(gui, menu_x + 20, content_y)
    end
end

---Render rush stats
function MenuSystem:renderRushStats(gui, menu_x, content_y, game)
    local elapsed_time = game.elapsed_time or 0
    GuiText(gui, menu_x + 20, content_y, string.format("Time: %02d:%02d",
        math.floor(elapsed_time / 60), elapsed_time % 60))
    content_y = content_y + 25
    
    local completed = game.rush_completed_count or 0
    GuiText(gui, menu_x + 20, content_y, "Objectives Completed: " .. tostring(completed))
    content_y = content_y + 35
    
    GuiText(gui, menu_x + 20, content_y, "Completed Objectives:")
    content_y = content_y + 20
    
    -- List completed objectives
    if game.rush_completed_objectives then
        for _, obj in ipairs(game.rush_completed_objectives) do
            GuiText(gui, menu_x + 30, content_y, "- " .. obj.title)
            content_y = content_y + 15
        end
    end
end

---Render win/loss record
function MenuSystem:renderWinLossRecord(gui, x, y)
    -- TODO: Get opponent info and display record
    GuiText(gui, x, y, "Win-Loss Record:")
    GuiText(gui, x + 10, y + 20, "Session: 0-0")
    GuiText(gui, x + 10, y + 35, "Lifetime: 0-0")
end

---Count completed lines on board
function MenuSystem:countCompletedLines(board)
    local count = 0
    local size = board.size
    
    -- Check rows
    for row = 1, size do
        local all_cleared = true
        for col = 1, size do
            if not board:isCleared(row, col) then
                all_cleared = false
                break
            end
        end
        if all_cleared then count = count + 1 end
    end
    
    -- Check columns
    for col = 1, size do
        local all_cleared = true
        for row = 1, size do
            if not board:isCleared(row, col) then
                all_cleared = false
                break
            end
        end
        if all_cleared then count = count + 1 end
    end
    
    -- Check diagonals
    local diag1_clear = true
    for i = 1, size do
        if not board:isCleared(i, i) then
            diag1_clear = false
            break
        end
    end
    if diag1_clear then count = count + 1 end
    
    local diag2_clear = true
    for i = 1, size do
        if not board:isCleared(i, size - i + 1) then
            diag2_clear = false
            break
        end
    end
    if diag2_clear then count = count + 1 end
    
    return count
end

---Count completed squares
function MenuSystem:countCompletedSquares(board)
    local count = 0
    for i = 1, #board.cleared do
        if board.cleared[i] then
            count = count + 1
        end
    end
    return count
end

BingoUI.MenuSystem = MenuSystem
