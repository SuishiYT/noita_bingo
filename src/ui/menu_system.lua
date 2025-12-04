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
    
    -- Initialize Noita theme
    self.theme = BingoUI.NoitaTheme.new()
    
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
    
    if not gui then
        GamePrint("[BINGO] ERROR: GUI is nil in MenuSystem:render()")
        return
    end
    
    -- Debug: Print current state every frame (every 60 frames to avoid spam)
    if GameGetFrameNum() % 60 == 0 then
        GamePrint("[BINGO] RENDER: Current state = " .. tostring(self.current_state))
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
        -- Game controls overlay is rendered differently during gameplay
        -- This is handled by renderGameControlsOverlay which takes additional parameters
        -- For now, just go back to main menu if accessed this way
        self:goBack()
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
    local menu_height = math.min(450, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Draw themed panel background
    self.theme:drawPanel(gui, self:getID(), menu_x, menu_y, menu_width, menu_height, "NOITA BINGO v0.1.0")
    
    local current_y = menu_y + 50
    
    -- Welcome message
    self.theme:setColor(gui, self.theme.Colors.text_accent)
    GuiText(gui, menu_x + 30, current_y, "Welcome to Noita Bingo!")
    current_y = current_y + 30
    
    -- Features section
    self.theme:setColor(gui, self.theme.Colors.text_title)
    GuiText(gui, menu_x + 30, current_y, "Features:")
    current_y = current_y + 18
    
    self.theme:setColor(gui, self.theme.Colors.text_secondary)
    GuiText(gui, menu_x + 40, current_y, "• Solo and multiplayer bingo games")
    current_y = current_y + 15
    GuiText(gui, menu_x + 40, current_y, "• Customizable objectives and categories")
    current_y = current_y + 15
    GuiText(gui, menu_x + 40, current_y, "• Multiple game modes (Traditional, Lockout, Rush)")
    current_y = current_y + 15
    GuiText(gui, menu_x + 40, current_y, "• Flexible board positioning")
    current_y = current_y + 25
    
    -- Controls section
    self.theme:setColor(gui, self.theme.Colors.text_title)
    GuiText(gui, menu_x + 30, current_y, "Controls:")
    current_y = current_y + 18
    
    self.theme:setColor(gui, self.theme.Colors.text_secondary)
    GuiText(gui, menu_x + 40, current_y, "• T - Toggle this menu")
    current_y = current_y + 12
    GuiText(gui, menu_x + 40, current_y, "• Z - Full screen board")
    current_y = current_y + 12
    GuiText(gui, menu_x + 40, current_y, "• X - Large board")
    current_y = current_y + 12
    GuiText(gui, menu_x + 40, current_y, "• C - Small board")
    current_y = current_y + 12
    GuiText(gui, menu_x + 40, current_y, "• R - Hide/show board")
    current_y = current_y + 25
    
    -- Multiplayer note
    if not self:isEvaisaMpAvailable() then
        self.theme:setColor(gui, self.theme.Colors.text_warning)
        GuiText(gui, menu_x + 30, current_y, "Install 'Noita Online' mod for multiplayer!")
        current_y = current_y + 20
    end
    
    -- "Don't show again" checkbox
    local checkbox_x = menu_x + 30
    local checkbox_y = menu_y + menu_height - 60
    local checkbox_id = self:getID()
    local checkbox_text = self.dont_show_splash_again and "[X] Don't show again" or "[ ] Don't show again"
    
    if GuiButton(gui, checkbox_id, checkbox_x, checkbox_y, checkbox_text) then
        self.dont_show_splash_again = not self.dont_show_splash_again
    end
    
    -- Continue button
    local button_id = self:getID()
    local button_x = menu_x + menu_width - 140
    local button_y = menu_y + menu_height - 50
    
    local button_clicked = GuiButton(gui, button_id, button_x, button_y, "Continue")
    local enter_pressed = InputIsKeyJustDown(40) -- Enter key
    
    if button_clicked or enter_pressed then
        -- Only disable splash screen if checkbox is checked
        if self.dont_show_splash_again then
            ModSettingSet("noita_bingo.show_splash", "false")
            self.show_splash = false
        end
        
        self:navigate(MenuSystem.State.MAIN_MENU, false)
    end
end

---Render main menu
function MenuSystem:renderMainMenu(gui, screen_width, screen_height)
    local menu_x = screen_width / 2 - 150
    local menu_y = screen_height / 2 - 180
    local menu_width = 300
    local menu_height = 360
    
    -- Get base GUI ID for this frame
    local base_id = self:getID()
    
    -- Draw themed panel
    self.theme:drawPanel(gui, base_id, menu_x, menu_y, menu_width, menu_height, "MAIN MENU")
    
    local button_x = menu_x + 30
    local button_y = menu_y + 60
    local button_spacing = 50
    
    -- Singleplayer button
    if GuiButton(gui, base_id + 10, button_x, button_y, "Singleplayer") then
        GamePrint("[BINGO] Singleplayer button clicked")
        self:navigate(MenuSystem.State.SINGLEPLAYER_MODE_SELECT, true)
    end
    button_y = button_y + button_spacing
    
    -- Multiplayer button
    if GuiButton(gui, base_id + 20, button_x, button_y, "Multiplayer") then
        GamePrint("[BINGO] Multiplayer button clicked")
        if self:isEvaisaMpAvailable() then
            self:navigate(MenuSystem.State.MULTIPLAYER_SETUP, true)
        else
            self:navigate(MenuSystem.State.MULTIPLAYER_MODE_SELECT, true)
        end
    end
    button_y = button_y + button_spacing
    
    -- Settings button
    if GuiButton(gui, base_id + 30, button_x, button_y, "Settings") then
        GamePrint("[BINGO] Settings button clicked")
        self:navigate(MenuSystem.State.SETTINGS, true)
    end
    button_y = button_y + button_spacing
    
    -- Close Menu button
    if GuiButton(gui, base_id + 40, button_x, button_y, "Close Menu") then
        GamePrint("[BINGO] Close Menu button clicked")
        self:close()
    end
end

---Render singleplayer mode selection
function MenuSystem:renderSingleplayerModeSelect(gui, screen_width, screen_height)
    local menu_width = math.min(450, screen_width - 100)
    local menu_height = math.min(420, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Draw panel title
    GuiColorSetForNextWidget(gui, 1, 0.9, 0.3, 1) -- Golden
    GuiText(gui, menu_x + 30, menu_y + 20, "SELECT GAME MODE")
    
    local current_y = menu_y + 60
    local button_x = menu_x + 30
    local base_id = self:getID()
    
    -- Traditional Bingo button
    if GuiButton(gui, base_id + 10, button_x, current_y, "Traditional Bingo") then
        self.selected_mode = MenuSystem.GameMode.TRADITIONAL
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, button_x + 10, current_y + 35, "Get 5 in a row (horizontal, vertical, or diagonal)")
    current_y = current_y + 70
    
    -- Blackout button
    if GuiButton(gui, base_id + 20, button_x, current_y, "Blackout") then
        self.selected_mode = MenuSystem.GameMode.BLACKOUT
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, button_x + 10, current_y + 35, "Complete all squares on the board")
    current_y = current_y + 70
    
    -- Rush button
    if GuiButton(gui, base_id + 30, button_x, current_y, "Rush") then
        self.selected_mode = MenuSystem.GameMode.RUSH
        self:navigate(MenuSystem.State.GAME_SETTINGS)
    end
    
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, button_x + 10, current_y + 35, "Complete objectives before time runs out")
    
    -- Back button
    if GuiButton(gui, base_id + 40, button_x, menu_y + menu_height - 50, "Back") then
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
    print(string.format("Bingo: Game has %d objectives", game.objectives and #game.objectives or 0))
    GamePrint("[BINGO] Game started!")
    
    -- Set the global game state
    BingoBoardState.current_game = game
    print(string.format("Bingo: After assignment, game has %d objectives", BingoBoardState.current_game.objectives and #BingoBoardState.current_game.objectives or 0))
    
    -- Initialize auto-tracker for objective tracking
    if BingoCore.AutoTracker then
        BingoBoardState.auto_tracker = BingoCore.AutoTracker.new()
        GamePrint("[BINGO] Auto-tracker initialized")
    else
        GamePrint("[BINGO] WARNING: AutoTracker not available")
    end
    
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
    local menu_width = math.min(700, screen_width - 100)
    local menu_height = math.min(550, screen_height - 100)
    local menu_x = (screen_width - menu_width) / 2
    local menu_y = (screen_height - menu_height) / 2
    
    -- Title
    GuiColorSetForNextWidget(gui, 1, 0.9, 0.3, 1)
    GuiText(gui, menu_x + 200, menu_y + 20, "GAME SETTINGS")
    
    local content_y = menu_y + 60
    local left_col = menu_x + 20
    local base_id = self:getID()
    
    -- Game Mode Display
    local mode_name = self.selected_mode == MenuSystem.GameMode.TRADITIONAL and "Traditional Bingo" or 
                      self.selected_mode == MenuSystem.GameMode.BLACKOUT and "Blackout" or
                      self.selected_mode == MenuSystem.GameMode.RUSH and "Rush" or "Unknown"
    
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, left_col, content_y, "Game Mode: " .. mode_name)
    content_y = content_y + 30
    
    -- Board Size
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, left_col, content_y, "Board Size:")
    
    if GuiButton(gui, base_id + 10, left_col + 130, content_y - 5, "5x5") then
        self.game_settings.board_size = 5
    end
    
    if GuiButton(gui, base_id + 20, left_col + 200, content_y - 5, "6x6") then
        self.game_settings.board_size = 6
    end
    
    if GuiButton(gui, base_id + 30, left_col + 270, content_y - 5, "7x7") then
        self.game_settings.board_size = 7
    end
    
    GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
    GuiText(gui, left_col + 350, content_y, "Current: " .. self.game_settings.board_size .. "x" .. self.game_settings.board_size)
    
    content_y = content_y + 50
    
    -- Rewards
    GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
    GuiText(gui, left_col, content_y, "Enable Rewards:")
    
    local reward_text = self.game_settings.enable_rewards and "ON" or "OFF"
    
    if GuiButton(gui, base_id + 40, left_col + 130, content_y - 5, "Toggle") then
        self.game_settings.enable_rewards = not self.game_settings.enable_rewards
    end
    
    local reward_color = self.game_settings.enable_rewards and 0x00FF00FF or 0xFF0000FF
    local r = bit.band(bit.rshift(reward_color, 16), 0xFF) / 255
    local g = bit.band(bit.rshift(reward_color, 8), 0xFF) / 255
    local b = bit.band(reward_color, 0xFF) / 255
    GuiColorSetForNextWidget(gui, r, g, b, 1)
    GuiText(gui, left_col + 210, content_y, reward_text)
    
    content_y = content_y + 50
    
    -- Start and Back buttons
    if GuiButton(gui, base_id + 50, menu_x + menu_width - 280, menu_y + menu_height - 50, "Start Game") then
        self:startGame()
    end
    
    if GuiButton(gui, base_id + 60, menu_x + menu_width - 160, menu_y + menu_height - 50, "Back") then
        self:goBack()
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
    GuiText(gui, menu_x + 30, content_y, "Open Menu: T (Toggle)")
    content_y = content_y + 20
    GuiText(gui, menu_x + 30, content_y, "Full Screen: Z")
    content_y = current_y + 15
    GuiText(gui, menu_x + 30, content_y, "Large Board: X")
    content_y = current_y + 15
    GuiText(gui, menu_x + 30, content_y, "Small Board: C")
    content_y = current_y + 15
    GuiText(gui, menu_x + 30, content_y, "Hide/Show: R (Toggle)")
    
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
