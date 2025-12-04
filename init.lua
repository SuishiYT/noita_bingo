-- Noita Bingo Mod
-- Main entry point for the bingo mod

local init_success, init_error = pcall(function()

-- Register gamemode with evaisa.mp if it's enabled (for multiplayer support)
-- When Bingo is selected as a Noita gamemode, it automatically enables in evaisa.mp lobbies
if ModIsEnabled("evaisa.mp") then
    print("Bingo: evaisa.mp detected - setting up multiplayer integration")
    
    -- Try to append our gamemode to the evaisa.mp gamemodes file for multiplayer
    pcall(function()
        ModLuaFileAppend("mods/evaisa.mp/data/gamemodes.lua", "mods/noita_bingo/src/multiplayer/bingo_gamemode_append.lua")
    end)
else
    print("Bingo: evaisa.mp not enabled - multiplayer features unavailable")
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

print("Namespaces initialized successfully")

-- Load files in dependency order - core first, then configs that depend on core
local files_to_load = {
    -- Core classes first (no dependencies)
    "src/core/objective.lua",
    "src/core/bingo_board.lua",
    "src/core/game.lua",
    "src/core/game_modes.lua",
    "src/core/persistence.lua",
    "src/core/board_generator.lua",
    "src/core/settings_preset_manager.lua",
    "src/core/statistics_tracker.lua",
    "src/core/auto_tracker.lua",
    "src/core/event_hooks.lua",
    
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
local failed_files = {}

for i, file_path in ipairs(files_to_load) do
    local success, err = pcall(function()
        dofile(mod_path .. file_path)
    end)
    
    if success then
        loaded_files = loaded_files + 1
        print("Loaded: " .. file_path)
        -- Show GamePrint for critical files
        if file_path == "src/ui/menu_system.lua" then
            GamePrint("[BINGO LOADER] menu_system.lua loaded successfully")
        end
    else
        print("=== FAILED TO LOAD: " .. file_path .. " ===")
        print("Error: " .. tostring(err))
        GamePrint("[BINGO LOADER] FAILED: " .. file_path)
        GamePrint("Error: " .. tostring(err))
        table.insert(failed_files, file_path)
    end
end

print("=== NOITA BINGO: Loaded " .. loaded_files .. "/" .. total_files .. " files ===")
GamePrint("[BINGO LOADER] Loaded " .. loaded_files .. "/" .. total_files .. " files")

if #failed_files > 0 then
    GamePrint("[BINGO] Failed files: " .. table.concat(failed_files, ", "))
    for i, f in ipairs(failed_files) do
        print("  - " .. f)
    end
end

-- Initialize multiplayer integration (after all files are loaded)
if BingoMultiplayer then
    print("BingoMultiplayer table found, calling initialize()")
    BingoMultiplayer.initialize()
else
    print("BingoMultiplayer table not found - integration.lua may have failed to load")
end

print("Noita Bingo initialization complete!")

-- GUI instance (GLOBAL)
gui = nil

-- Menu system (GLOBAL)
menu_system = nil

-- Debug frame counter
local debug_frame_counter = 0

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
    GamePrint("=== NOITA BINGO: OnModInit called ===")
    print("=== NOITA BINGO: OnModInit called ===")
    GamePrint("NOITA BINGO: OnModInit executing")
    -- Ensure GUI is created if not already done
    if not gui then
        gui = GuiCreate()
    end
    
    -- Verify core modules loaded
    if not BingoCore.Objective then
        print("CRITICAL ERROR: BingoCore.Objective not loaded. Aborting initialization.")
        return
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
    print("\n=== LOADING OBJECTIVES ===")
    print("BingoConfig exists: " .. tostring(BingoConfig ~= nil))
    print("BingoConfig.loadObjectives exists: " .. tostring(BingoConfig and BingoConfig.loadObjectives ~= nil))
    print("BingoCore.Objective exists: " .. tostring(BingoCore and BingoCore.Objective ~= nil))
    
    if BingoConfig.loadObjectives then
        local objectives = BingoConfig.loadObjectives()
        print("Init: loadObjectives returned " .. #objectives .. " objectives")
        if objectives and BingoConfig.category_system.registerObjective then
            for _, obj in ipairs(objectives) do
                BingoConfig.category_system:registerObjective(obj)
                print("Init: Registered objective: " .. tostring(obj.id))
            end
            print("Init: Successfully registered all objectives")
        else
            print("Init: ERROR - objectives list empty or registerObjective not available")
        end
    else
        print("Init: ERROR - BingoConfig.loadObjectives not found!")
    end
    print("=== END LOADING OBJECTIVES ===\n")
    
    -- Initialize UI Manager
    if BingoUI.UIManager then
        BingoUI.manager = BingoUI.UIManager.new()
        if BingoUI.manager.initialize then
            BingoUI.manager:initialize()
        end
        print("UI Manager initialized successfully")
    else
        print("ERROR: BingoUI.UIManager not loaded! Creating fallback...")
        BingoUI.manager = { 
            update = function() end,
            render = function(self, game, gui)
                -- Fallback render - just draw text so something shows
                if game and game.board then
                    GuiText(gui, 100, 100, "BINGO BOARD")
                    GuiText(gui, 100, 120, "Size: " .. tostring(game.board.size))
                    GuiText(gui, 100, 140, "Objectives: " .. tostring(#game.board.objectives or 0))
                end
            end,
            savePositions = function() end
        }
    end
    
    -- Initialize auto-tracker
    if BingoCore.AutoTracker then
        BingoBoardState.auto_tracker = BingoCore.AutoTracker.new()
        print("AutoTracker initialized successfully")
    else
        print("ERROR: BingoCore.AutoTracker not loaded!")
        BingoBoardState.auto_tracker = {
            update = function() end,
            checkObjective = function() return false end,
            autoCheckBoard = function() return {} end,
            recordEvent = function() end,
            recordKill = function() end,
            recordDeath = function() end
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
    
    debug_frame_counter = debug_frame_counter + 1
    
    -- Handle input
    if menu_system then
        -- Try multiple key codes for F6 and T
        -- F6 is typically 63, but we'll check other variations too
        local f6_pressed = InputIsKeyJustDown(63) or InputIsKeyJustDown(118) -- F6 or alternative
        local t_pressed = InputIsKeyJustDown(23) or InputIsKeyJustDown(84) -- T or alternative
        
        if f6_pressed or t_pressed then
            GamePrint("[BINGO] Menu key pressed!")
            if menu_system:isOpen() then
                menu_system:close()
                GamePrint("[BINGO] Menu CLOSED")
            else
                menu_system:open()
                GamePrint("[BINGO] Menu OPENED")
            end
        end
        
        -- Debug output every 120 frames (2 seconds)
        if debug_frame_counter % 120 == 0 then
            GamePrint("[BINGO DEBUG] menu_system exists, state: " .. tostring(menu_system.current_state))
        end
        
        -- Update systems
        if BingoUI.manager then
            BingoUI.manager:update(1 / 60)
        end
        
        if BingoMultiplayer.sync then
            BingoMultiplayer.sync:update(1 / 60)
        end
    else
        if debug_frame_counter % 120 == 0 then
            GamePrint("[BINGO] ERROR: menu_system is nil!")
        end
    end
    
    if BingoBoardState.current_game then
        local dt = 1 / 60 -- Approximate delta time
        
        -- Don't update game time if timer is paused
        if not BingoBoardState.timer_paused then
            BingoBoardState.current_game:update(dt)
        end
        
        -- Update auto-tracker
        if BingoBoardState.auto_tracker then
            BingoBoardState.auto_tracker:update(dt)
            
            -- Update event tracking (detects kills, deaths, events)
            if BingoCore.EventHooks then
                BingoCore.EventHooks.updateEventTracking()
            end
            
            -- Auto-check board objectives every frame
            local board = BingoBoardState.current_game.board
            if board and BingoBoardState.current_game.objectives then
                local cleared = BingoBoardState.auto_tracker:autoCheckBoard(board, BingoBoardState.current_game.objectives)
                
                -- Broadcast cleared squares to multiplayer if any were cleared
                if #cleared > 0 and BingoMultiplayer and BingoMultiplayer.isMultiplayer() then
                    for _, pos in ipairs(cleared) do
                        BingoMultiplayer.clearSquare(pos.row, pos.col)
                    end
                end
            end
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
        
        local screen_width, screen_height = GuiGetScreenDimensions(gui)
        
        -- Debug info - always visible
        GuiColorSetForNextWidget(gui, 1, 1, 0, 1) -- Yellow
        GuiText(gui, screen_width - 400, screen_height - 70, "[BINGO] Menu State: " .. tostring(menu_system and menu_system.current_state or "nil"))
        
        -- Show if menu is open or closed
        if menu_system then
            local is_open = menu_system:isOpen()
            if is_open then
                GuiColorSetForNextWidget(gui, 0, 1, 0, 1) -- Green
                GuiText(gui, screen_width - 400, screen_height - 50, "[BINGO] Menu is OPEN")
            else
                GuiColorSetForNextWidget(gui, 1, 0, 0, 1) -- Red
                GuiText(gui, screen_width - 400, screen_height - 50, "[BINGO] Menu is CLOSED (Press F6/T)")
            end
        else
            GuiColorSetForNextWidget(gui, 1, 0, 0, 1) -- Red
            GuiText(gui, screen_width - 400, screen_height - 50, "[BINGO] ERROR: menu_system is nil!")
        end
        
        -- Render menu system
        if menu_system and menu_system:isOpen() then
            -- Try to render the actual menu
            if menu_system.render then
                menu_system:render(gui)
            else
                -- Fallback: render a simple test menu
                GuiColorSetForNextWidget(gui, 0.2, 0.2, 0.2, 0.8)
                GuiImage(gui, BingoGUIManager.getID(), 100, 100, "data/ui_gfx/1x1_white.png", 1, 500, 300)
                
                GuiColorSetForNextWidget(gui, 1, 1, 1, 1)
                GuiText(gui, 120, 120, "TEST MENU - render() failed")
                GuiText(gui, 120, 150, "menu_system.render = " .. tostring(menu_system.render))
            end
        end
        
        -- Render the bingo board
        if BingoBoardState.current_game then
            GamePrint("[BINGO] Rendering board, game exists")
            
            -- Ensure manager exists (create fallback if needed)
            if not BingoUI.manager then
                GamePrint("[BINGO] Creating fallback UI manager...")
                BingoUI.manager = { 
                    update = function() end,
                    render = function(self, game, gui)
                        -- Fallback render - just draw text so something shows
                        if game and game.board then
                            GuiText(gui, 100, 100, "BINGO BOARD")
                            GuiText(gui, 100, 120, "Size: " .. tostring(game.board.size))
                            GuiText(gui, 100, 140, "Objectives: " .. tostring(#game.board.objectives or 0))
                        end
                    end,
                    savePositions = function() end
                }
            end
            
            if not BingoUI.manager.render then
                GamePrint("[BINGO] ERROR: BingoUI.manager.render is nil!")
            else
                GamePrint("[BINGO] Calling BingoUI.manager:render()")
                BingoUI.manager:render(BingoBoardState.current_game, gui)
            end
        else
            if GameGetFrameNum() % 120 == 0 then
                GamePrint("[BINGO] No current_game to render")
            end
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
    print("Bingo: OnWorldInitialized - Bingo gamemode activated!")
    GamePrint("Bingo: Game mode activated - Press F6 or T to open menu")
    
    -- Initialize menu system if not already done
    if not menu_system or menu_system.current_state == "error" then
        GamePrint("[BINGO] Initializing menu system now...")
        if BingoUI and BingoUI.MenuSystem then
            menu_system = BingoUI.MenuSystem.new()
            GamePrint("[BINGO] Menu system created!")
        else
            GamePrint("[BINGO] ERROR: BingoUI.MenuSystem not found!")
            GamePrint("[BINGO] BingoUI exists: " .. tostring(BingoUI ~= nil))
            if BingoUI then
                local count = 0
                for k, v in pairs(BingoUI) do
                    GamePrint("[BINGO] BingoUI." .. k)
                    count = count + 1
                end
                GamePrint("[BINGO] BingoUI has " .. count .. " entries")
            end
        end
    end
    
    -- Auto-open the menu on game start
    if menu_system and not menu_system:isOpen() then
        menu_system:open()
        GamePrint("Bingo: Opening menu...")
        print("Bingo: Menu auto-opened on world initialization")
    end
end

end) -- End of pcall wrapper

if not init_success then
    print("=== CRITICAL ERROR IN BINGO MOD INITIALIZATION ===")
    print("Error: " .. tostring(init_error))
    GamePrint("Bingo Mod: FAILED TO INITIALIZE - Check console for error")
else
    print("=== BINGO MOD INITIALIZATION SUCCESSFUL ===")
end
