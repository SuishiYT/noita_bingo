-- Noita Bingo Mod
-- Main entry point for the bingo mod

-- Force evaisa.mp to load first if it exists but failed
if ModIsEnabled("evaisa.mp") and not steam then
    print("Bingo: Attempting to force-load evaisa.mp framework")
    pcall(function()
        dofile_once("mods/evaisa.mp/init.lua")
    end)
end

-- Register gamemode with evaisa.mp if it's enabled
if ModIsEnabled("evaisa.mp") then
    print("Bingo: Attempting to register gamemode with evaisa.mp")
    
    -- Try to append our gamemode to the gamemodes file
    local success = pcall(function()
        ModLuaFileAppend("mods/evaisa.mp/data/gamemodes.lua", "mods/noita_bingo/src/multiplayer/bingo_gamemode_append.lua")
    end)
    
    -- Also append to lobby UI for gamemode selection
    local ui_success = pcall(function()
        ModLuaFileAppend("mods/evaisa.mp/files/scripts/lobby_ui.lua", "mods/noita_bingo/src/multiplayer/lobby_ui_append.lua")
    end)
    
    if success then
        print("Bingo: ModLuaFileAppend successful")
        GamePrint("Bingo: Gamemode registration attempted")
    else
        print("Bingo: ModLuaFileAppend failed")
        GamePrint("Bingo: Gamemode registration failed")
    end
    
    if ui_success then
        print("Bingo: Lobby UI modification successful")
        GamePrint("Bingo: UI integration added")
    else
        print("Bingo: Lobby UI modification failed")
    end
else
    print("Bingo: evaisa.mp not enabled - skipping gamemode registration")
    GamePrint("Bingo: evaisa.mp not detected")
end

print("=== NOITA BINGO MOD LOADING ===")
GamePrint("NOITA BINGO: Mod file executing!")

-- Get mod directory path
local mod_path = "mods/noita_bingo/"

-- Initialize namespaces
BingoBoardState = {}
BingoUI = {}
BingoConfig = {}
BingoMultiplayer = {}
BingoCore = {}

-- Load files in dependency order - core first, then configs that depend on core
local files_to_load = {
    -- Core classes first (no dependencies)
    "src/core/objective.lua",
    "src/core/bingo_board.lua", 
    "src/core/game_modes.lua",
    "src/core/persistence.lua",
    "src/core/board_generator.lua",
    "src/core/settings_preset_manager.lua",
    "src/core/statistics_tracker.lua",
    
    -- Config files (may depend on core)
    "src/config/settings.lua",
    "src/config/objectives.lua", 
    "src/config/rewards.lua",
    
    -- UI system
    "src/ui/board_positioning.lua",
    "src/ui/board_renderer_noita.lua",  -- Only load the Noita-specific version
    "src/ui/input_handler.lua",
    "src/ui/ui_manager_noita.lua",      -- Only load the Noita-specific version
    "src/ui/menu_system.lua",
    
    -- Multiplayer integration (will auto-detect evaisa.mp)
    "src/multiplayer/integration.lua"
}

local loaded_files = 0
local total_files = #files_to_load

for i, file_path in ipairs(files_to_load) do
    local success, err = pcall(function()
        dofile(mod_path .. file_path)
    end)
    
    if success then
        loaded_files = loaded_files + 1
        print("Loaded: " .. file_path)
    else
        print("=== FAILED TO LOAD: " .. file_path .. " ===")
        print("Error: " .. tostring(err))
    end
end

print("=== NOITA BINGO: Loaded " .. loaded_files .. "/" .. total_files .. " files ===")

-- Initialize multiplayer integration (after all files are loaded)
if BingoMultiplayer then
    print("BingoMultiplayer table found, calling initialize()")
    BingoMultiplayer.initialize()
else
    print("BingoMultiplayer table not found - integration.lua may have failed to load")
end

print("Noita Bingo initialization complete!")

-- GUI instance
local gui = nil

-- Menu system
local menu_system = nil

-- Centralized GUI ID Manager
local BingoGUIManager = {
    current_id = 1,
    button_test_counter = 0
}

function BingoGUIManager.getID()
    BingoGUIManager.current_id = BingoGUIManager.current_id + 1
    return BingoGUIManager.current_id
end

function BingoGUIManager.resetIDs()
    BingoGUIManager.current_id = 1
end

-- Test function to verify GUI button functionality
function BingoGUIManager.testButton(gui, x, y, text)
    local id = BingoGUIManager.getID()
    local clicked = GuiButton(gui, id, x, y, text or "Test Button")
    
    if clicked then
        BingoGUIManager.button_test_counter = BingoGUIManager.button_test_counter + 1
        GamePrint("Test button clicked! Count: " .. BingoGUIManager.button_test_counter)
    end
    
    return clicked, id
end

-- Expose globally for use by all modules
get_gui_id = BingoGUIManager.getID

-- Pre-initialization (runs very early, even in main menu)
function OnModPreInit()
    print("=== NOITA BINGO: OnModPreInit called ===")
    GamePrint("NOITA BINGO: OnModPreInit executing")
    -- Create GUI instance early so it works in main menu
    gui = GuiCreate()
    BingoGUIManager.resetIDs()
end

-- Initialize the mod
function OnModInit()
    print("=== NOITA BINGO: OnModInit called ===")
    GamePrint("NOITA BINGO: OnModInit executing")
    -- Ensure GUI is created if not already done
    if not gui then
        gui = GuiCreate()
    end
    
    -- Initialize game state
    BingoBoardState.current_game = nil
    BingoBoardState.display_mode = "large"
    BingoBoardState.board_positions = {
        large = { x = 100, y = 100, width = 400, height = 400 },
        small = { x = 100, y = 100, width = 200, height = 200 },
        hidden_side = "right", -- "left" or "right"
        hidden_y = 0.5 -- 0 to 1, representing percentage of screen height
    }
    
    -- Initialize core systems first (after all files are loaded)
    if BingoCore.CategorySystem then
        BingoConfig.category_system = BingoCore.CategorySystem.new()
    else
        print("ERROR: BingoCore.CategorySystem not loaded!")
        BingoConfig.category_system = { registerObjective = function() end, categories = {} }
    end
    
    -- Initialize settings
    if BingoConfig.Settings then
        BingoConfig.settings = BingoConfig.Settings.new()
    else
        print("ERROR: BingoConfig.Settings not loaded!")
        BingoConfig.settings = { data = {} }
    end
    
    -- Initialize rewards manager
    if BingoConfig.RewardsManager then
        BingoConfig.rewards_manager = BingoConfig.RewardsManager.new()
    else
        print("ERROR: BingoConfig.RewardsManager not loaded!")
        BingoConfig.rewards_manager = { getReward = function() return nil end }
    end
    
    -- Load objectives into category system
    if BingoConfig.loadObjectives then
        local objectives = BingoConfig.loadObjectives()
        if objectives and BingoConfig.category_system.registerObjective then
            for _, obj in ipairs(objectives) do
                BingoConfig.category_system:registerObjective(obj)
            end
        end
    end
    
    -- Initialize UI Manager
    if BingoUI.UIManager then
        BingoUI.manager = BingoUI.UIManager.new()
        if BingoUI.manager.initialize then
            BingoUI.manager:initialize()
        end
    else
        print("ERROR: BingoUI.UIManager not loaded!")
        BingoUI.manager = { 
            update = function() end,
            render = function() end,
            savePositions = function() end
        }
    end
    
    -- Initialize multiplayer systems
    if BingoMultiplayer.Sync then
        BingoMultiplayer.sync = BingoMultiplayer.Sync.new()
        if BingoMultiplayer.sync.initialize then
            BingoMultiplayer.sync:initialize()
        end
    else
        print("ERROR: BingoMultiplayer.Sync not loaded!")
        BingoMultiplayer.sync = { update = function() end }
    end
    
    -- Initialize network (if needed)
    if BingoMultiplayer.Network then
        BingoMultiplayer.network = BingoMultiplayer.Network.new()
    else
        print("ERROR: BingoMultiplayer.Network not loaded!")
        BingoMultiplayer.network = { send = function() end, receive = function() end }
    end
    
    -- Load custom objectives if they exist
    local custom_objectives_path = mod_path .. "objectives/custom.lua"
    local custom_objectives = ModTextFileGetContent(custom_objectives_path)
    if custom_objectives and custom_objectives ~= "" then
        -- Try to load custom objectives file directly
        local success, err = pcall(function()
            dofile(custom_objectives_path)
            -- If the file defines a global CUSTOM_OBJECTIVES table, use it
            if CUSTOM_OBJECTIVES then
                for _, obj_data in ipairs(CUSTOM_OBJECTIVES) do
                    if BingoCore.Objective then
                        local obj = BingoCore.Objective.new(obj_data)
                        BingoConfig.category_system:registerObjective(obj)
                    end
                end
                print("Loaded " .. #CUSTOM_OBJECTIVES .. " custom objectives")
            end
        end)
        
        if not success then
            print("Failed to load custom objectives: " .. tostring(err))
        end
    end
    
    -- Initialize menu system (ensure it exists even if some files failed)
    if BingoUI and BingoUI.MenuSystem then
        menu_system = BingoUI.MenuSystem.new()
        print("Menu system initialized successfully")
    else
        print("ERROR: BingoUI.MenuSystem not available - creating fallback")
        -- Create a minimal fallback menu system
        menu_system = {
            isOpen = function() return false end,
            open = function() GamePrint("Menu system not loaded properly!") end,
            close = function() end,
            render = function() end,
            current_state = "error"
        }
    end
    
    -- Don't auto-open menu during initialization
    -- Let the user open it manually with F6/T key
    -- The splash screen logic is handled in MenuSystem:open()
    
    -- Try to load saved game (don't auto-generate anymore)
    local saved_game = BingoCore.GameStatePersistence.loadGame()
    if saved_game then
        BingoBoardState.current_game = saved_game
        print("Loaded saved bingo game")
    else
        print("No saved game - open menu (F5) to start a new game")
    end
    
    print("Noita Bingo Mod initialized successfully!")
end

-- Post-initialization (runs after all mods are loaded)
function OnModPostInit()
    print("=== NOITA BINGO: OnModPostInit called ===")
    GamePrint("NOITA BINGO: Post init complete - try starting a new game to access menu")
    -- Final setup that needs to happen after all mods load
end

-- Update function called every frame (only during gameplay)
function OnWorldPreUpdate()
    -- Gamemode is now registered via ModLuaFileAppend, no manual registration needed
    
    -- Handle input
    if menu_system then
        -- Use proper key codes for menu toggle: F6 (63) and T (23)
        if InputIsKeyJustDown(63) or InputIsKeyJustDown(23) then -- F6 or T key
            if menu_system:isOpen() then
                menu_system:close()
            else
                menu_system:open()
            end
        end
        
        -- Update systems
        if BingoUI.manager then
            BingoUI.manager:update(1 / 60)
        end
        
        if BingoMultiplayer.sync then
            BingoMultiplayer.sync:update(1 / 60)
        end
    end
    
    if BingoBoardState.current_game then
        local dt = 1 / 60 -- Approximate delta time
        
        -- Don't update game time if timer is paused
        if not BingoBoardState.timer_paused then
            BingoBoardState.current_game:update(dt)
        end
        
        -- Auto-save every 5 seconds
        if not BingoBoardState.save_timer then
            BingoBoardState.save_timer = 0
        end
        BingoBoardState.save_timer = BingoBoardState.save_timer + dt
        
        if BingoBoardState.save_timer >= 5.0 then
            BingoCore.GameStatePersistence.saveGame(BingoBoardState.current_game)
            BingoUI.manager:savePositions()
            BingoBoardState.save_timer = 0
        end
    end
end

-- Draw function called every frame (during gameplay)
function OnWorldPostUpdate()
    if gui then
        -- Reset GUI IDs and start frame
        BingoGUIManager.resetIDs()
        GuiStartFrame(gui)
        
        -- Debug: Show menu state in bottom right (relative to screen size)
        if menu_system then
            local screen_width, screen_height = GuiGetScreenDimensions(gui)
            GuiColorSetForNextWidget(gui, 1, 1, 0, 1) -- Yellow text
            GuiText(gui, screen_width - 200, screen_height - 50, "Menu State: " .. tostring(menu_system.current_state))
        end
        
        -- Render menu system
        if menu_system and menu_system:isOpen() then
            menu_system:render(gui)
        end
        
        -- Render the bingo board
        if BingoBoardState.current_game and BingoUI.manager and BingoUI.manager.render then
            BingoUI.manager:render(BingoBoardState.current_game, gui)
        end
        
        -- Render pause overlay if needed
        if menu_system and menu_system.show_pause_overlay and BingoBoardState.current_game then
            local is_multiplayer = BingoBoardState.current_game.is_multiplayer or BingoMultiplayer.isMultiplayer()
            local is_host = true
            
            -- Get actual host status from evaisa.mp framework
            if BingoMultiplayer and BingoMultiplayer.sync and BingoMultiplayer.sync.is_multiplayer then
                is_host = BingoMultiplayer.sync.is_host
                is_multiplayer = true
            end
            
            menu_system:renderGameControlsOverlay(gui, is_host, is_multiplayer)
        end
    end
end



-- Pause menu draw (for when game is paused) - only for pause-specific overlays
function OnPausedChanged(is_paused, is_inventory_pause)
    -- Show game controls overlay when ESC menu is open during active game
    if is_paused and not is_inventory_pause and BingoBoardState.current_game then
        if menu_system then
            menu_system.show_pause_overlay = true
        end
    else
        if menu_system then
            menu_system.show_pause_overlay = false
        end
    end
end

-- Helper functions for multiplayer integration
function BingoBoardState.exportBoard()
    if BingoBoardState.current_game and BingoBoardState.current_game.board then
        return BingoBoardState.current_game.board:exportData()
    end
    return nil
end

function BingoBoardState.loadBoard(board_data)
    if BingoBoardState.current_game and BingoBoardState.current_game.board and board_data then
        BingoBoardState.current_game.board:importData(board_data)
        print("BingoBoardState: Imported board data from multiplayer")
    end
end

function BingoBoardState.clearSquare(row, col, player_id)
    if BingoBoardState.current_game and BingoBoardState.current_game.board then
        local was_cleared = BingoBoardState.current_game.board:isCleared(row, col)
        if not was_cleared then
            BingoBoardState.current_game.board:clearSquare(row, col)
            print("BingoBoardState: Square " .. row .. "," .. col .. " cleared by " .. tostring(player_id))
            
            -- Notify multiplayer system if this was our action
            if BingoMultiplayer and BingoMultiplayer.isMultiplayer() then
                local our_id = BingoMultiplayer.sync and BingoMultiplayer.sync.player_id
                if tostring(player_id) == tostring(our_id) then
                    BingoMultiplayer.clearSquare(row, col)
                end
            end
        end
    end
end

function BingoBoardState.generateBoard()
    -- This should trigger board generation based on current lobby settings
    if menu_system then
        -- Get settings from lobby if in multiplayer
        local settings = {}
        
        if BingoMultiplayer and BingoMultiplayer.isFrameworkAvailable() and BingoMultiplayer.sync then
            local lobby = BingoMultiplayer.sync.lobby_code
            if lobby and steam and steam.matchmaking then
                settings.board_size = steam.matchmaking.getLobbyData(lobby, "setting_board_size") or "5x5"
                settings.game_mode = steam.matchmaking.getLobbyData(lobby, "setting_game_mode") or "traditional"
                settings.difficulty = steam.matchmaking.getLobbyData(lobby, "setting_difficulty") or "normal"
                settings.seed = steam.matchmaking.getLobbyData(lobby, "setting_seed") or ""
            end
        end
        
        -- Use default settings if no lobby settings
        if not next(settings) then
            settings = {
                board_size = "5x5",
                game_mode = "traditional", 
                difficulty = "normal",
                seed = ""
            }
        end
        
        -- Create the game through menu system
        menu_system:createGame(settings)
        print("BingoBoardState: Generated new board for multiplayer")
    end
end

-- Late initialization after all mods are loaded (for evaisa.mp integration)
function OnMagicNumbersAndWorldSeedInitialized()
    -- This runs after all mods are loaded, so evaisa.mp should be available if installed
    if BingoMultiplayer and BingoMultiplayer.lateInitialize() then
        print("Bingo Multiplayer: Late initialization successful")
    else
        print("Bingo Multiplayer: evaisa.mp framework still not available after late initialization")
        
        -- Check if the mod is enabled but failed to load
        if ModIsEnabled("evaisa.mp") then
            print("Bingo Multiplayer: evaisa.mp mod is enabled but failed to initialize properly")
            print("Bingo Multiplayer: This may be due to missing files or version mismatch")
        else
            print("Bingo Multiplayer: evaisa.mp mod is not enabled")
        end
    end
end

-- World initialization - this runs AFTER OnMagicNumbersAndWorldSeedInitialized
-- This is where evaisa.mp loads its gamemodes table, so we register here
function OnWorldInitialized()
    print("Bingo: OnWorldInitialized - attempting gamemode registration")
    
    -- Wait a few frames to ensure evaisa.mp has fully loaded
    BingoBoardState.gamemode_registration_attempts = 0
    BingoBoardState.gamemode_registered = false
end
