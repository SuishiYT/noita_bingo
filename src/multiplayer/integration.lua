-- Multiplayer Integration for evaisa.mp framework
-- This file handles the integration between the bingo mod and evaisa.mp

BingoMultiplayer = BingoMultiplayer or {}

-- Initialize the network and sync systems
if not BingoMultiplayer.Network then
    dofile_once("mods/noita_bingo/src/multiplayer/network.lua")
end

if not BingoMultiplayer.Sync then 
    dofile_once("mods/noita_bingo/src/multiplayer/synchronization.lua")
end

-- Create instances
BingoMultiplayer.network = BingoMultiplayer.Network.new()
BingoMultiplayer.sync = BingoMultiplayer.Sync.new()

-- Check if evaisa.mp framework is available
function BingoMultiplayer.isFrameworkAvailable()
    local has_steamutils = steamutils ~= nil
    local has_steam = steam ~= nil
    local has_gamemodes = gamemodes ~= nil and type(gamemodes) == "table"
    local evaisa_mod_enabled = ModIsEnabled("evaisa.mp")
    
    -- Check if framework files exist even if not fully loaded
    local has_framework_files = false
    if evaisa_mod_enabled then
        -- Try to check if key framework functions exist globally
        has_framework_files = (type(_G.steam) == "table") or 
                             (type(_G.steamutils) == "table") or
                             ModTextFileGetContent("mods/evaisa.mp/lib/steamutils.lua") ~= ""
    end
    
    local gamemodes_count = has_gamemodes and #gamemodes or 0
    
    if GameGetFrameNum() % 300 == 0 then -- Debug every 5 seconds
        print("Bingo Debug: Framework check - mod enabled: " .. tostring(evaisa_mod_enabled) .. 
              ", files exist: " .. tostring(has_framework_files) .. 
              ", steamutils: " .. tostring(has_steamutils) .. 
              ", steam: " .. tostring(has_steam) .. 
              ", gamemodes: " .. tostring(has_gamemodes) .. " (count: " .. gamemodes_count .. ")")
    end
    
    -- Return true if we have the runtime objects AND gamemodes table is loaded
    return (has_steamutils and has_steam and has_gamemodes) or (evaisa_mod_enabled and has_framework_files)
end

-- Initialize multiplayer systems
function BingoMultiplayer.initialize()
    if BingoMultiplayer.isFrameworkAvailable() then
        print("Bingo Multiplayer: evaisa.mp framework detected")
        return BingoMultiplayer._setupFramework()
    else
        print("Bingo Multiplayer: evaisa.mp framework not available, using solo mode")
        return false
    end
end

-- Try to initialize framework later (called after world init)
function BingoMultiplayer.lateInitialize()
    if not BingoMultiplayer._framework_initialized and BingoMultiplayer.isFrameworkAvailable() then
        print("Bingo Multiplayer: Late initialization - evaisa.mp framework now available")
        local success = BingoMultiplayer._setupFramework()
        
        -- Also try to register gamemode again in case it wasn't picked up earlier
        if success then
            BingoMultiplayer.registerGamemode()
        end
        
        return success
    end
    return BingoMultiplayer._framework_initialized or false
end

-- Internal function to set up framework integration
function BingoMultiplayer._setupFramework()
    if BingoMultiplayer._framework_initialized then
        return true
    end
    
    -- Set up message handlers
    BingoMultiplayer.network:onMessage("board_state", function(event, message, user)
        BingoMultiplayer.sync:handleMessage(event, message, user)
    end)
    
    BingoMultiplayer.network:onMessage("square_clear", function(event, message, user)
        BingoMultiplayer.sync:handleMessage(event, message, user)
    end)
    
    BingoMultiplayer.network:onMessage("game_win", function(event, message, user)
        BingoMultiplayer.sync:handleMessage(event, message, user)
    end)
    
    BingoMultiplayer._framework_initialized = true
    print("Bingo Multiplayer: Framework integration setup complete")
    return true
end

-- Gamemode event handlers for evaisa.mp integration
function BingoMultiplayer.onLobbyEnter(lobby)
    print("Bingo Multiplayer: Entered lobby " .. tostring(lobby))
    BingoMultiplayer.network:initialize(lobby)
    BingoMultiplayer.sync:initialize(lobby)
    
    -- Load existing board data if it exists
    if steam and steam.matchmaking then
        local board_data = steam.matchmaking.getLobbyData(lobby, "board_data")
        if board_data and board_data ~= "" then
            local success, deserialized = pcall(smallfolk.loads, board_data)
            if success and BingoBoardState and BingoBoardState.loadBoard then
                BingoBoardState.loadBoard(deserialized)
                print("Bingo Multiplayer: Loaded existing board from lobby")
            end
        end
    end
end

function BingoMultiplayer.onLobbyLeave(lobby)
    print("Bingo Multiplayer: Left lobby " .. tostring(lobby))
    BingoMultiplayer.network:cleanup()
    BingoMultiplayer.sync:cleanup()
end

function BingoMultiplayer.onGameStart(lobby)
    print("Bingo Multiplayer: Game started in lobby " .. tostring(lobby))
    
    -- If we're the host, generate and sync the board
    if BingoMultiplayer.sync.is_host then
        if BingoBoardState and BingoBoardState.generateBoard then
            BingoBoardState.generateBoard()
            local board_data = BingoBoardState.exportBoard()
            BingoMultiplayer.sync:syncBoardState(board_data)
            print("Bingo Multiplayer: Host generated and synced new board")
        end
    end
end

function BingoMultiplayer.onSpectate(lobby)
    print("Bingo Multiplayer: Spectating in lobby " .. tostring(lobby))
    -- Spectators just receive updates, no special handling needed
end

function BingoMultiplayer.onUpdate(lobby)
    -- Update sync system
    if BingoMultiplayer.sync then
        BingoMultiplayer.sync:update()
    end
end

function BingoMultiplayer.onLateUpdate(lobby)
    -- Any late frame updates if needed
end

function BingoMultiplayer.onLobbyRefresh(lobby)
    print("Bingo Multiplayer: Lobby settings refreshed")
    -- Handle lobby setting changes
end

function BingoMultiplayer.onPlayerDisconnected(lobby, user)
    print("Bingo Multiplayer: Player " .. tostring(user) .. " disconnected")
    if BingoMultiplayer.sync then
        BingoMultiplayer.sync:removePlayer(tostring(user))
    end
end

function BingoMultiplayer.onMessageReceived(lobby, event, message, user)
    if BingoMultiplayer.network then
        BingoMultiplayer.network:_handleMessage(lobby, event, message, user)
    end
end

-- Helper functions for the bingo mod to use

-- Clear a square and sync it
function BingoMultiplayer.clearSquare(row, col)
    if BingoMultiplayer.sync and BingoMultiplayer.sync.is_multiplayer then
        BingoMultiplayer.sync:syncSquareClear(row, col)
    end
end

-- Announce a win
function BingoMultiplayer.announceWin(win_type)
    if BingoMultiplayer.sync and BingoMultiplayer.sync.is_multiplayer then
        BingoMultiplayer.sync:broadcastWin(nil, win_type)
    end
end

-- Get multiplayer status
function BingoMultiplayer.isMultiplayer()
    return BingoMultiplayer.sync and BingoMultiplayer.sync.is_multiplayer or false
end

-- Get player list
function BingoMultiplayer.getPlayers()
    if BingoMultiplayer.sync then
        return BingoMultiplayer.sync.players
    end
    return {}
end

-- Diagnostic function to help troubleshoot evaisa.mp issues
function BingoMultiplayer.diagnoseFramework()
    print("=== Bingo Multiplayer Framework Diagnosis ===")
    print("ModIsEnabled('evaisa.mp'): " .. tostring(ModIsEnabled("evaisa.mp")))
    
    -- Check if key files exist
    local files_to_check = {
        "mods/evaisa.mp/init.lua",
        "mods/evaisa.mp/version.lua", 
        "mods/evaisa.mp/lib/steamutils.lua",
        "mods/evaisa.mp/bin/NoitaPatcher/load.lua",
        "mods/evaisa.mp/data/gamemodes.lua"
    }
    
    for _, file in ipairs(files_to_check) do
        local content = ModTextFileGetContent(file)
        print("File " .. file .. ": " .. (content ~= "" and "EXISTS (" .. #content .. " bytes)" or "MISSING"))
    end
    
    -- Check global variables
    print("Global 'steam' type: " .. type(_G.steam))
    print("Global 'steamutils' type: " .. type(_G.steamutils))
    print("Global 'gamemodes' type: " .. type(_G.gamemodes))
    print("Global 'lobby_code' type: " .. type(_G.lobby_code))
    print("Global 'np' (NoitaPatcher) type: " .. type(_G.np))
    
    -- Check if gamemodes table has content
    if _G.gamemodes and type(_G.gamemodes) == "table" then
        print("Gamemodes count: " .. #_G.gamemodes)
        for i, gm in ipairs(_G.gamemodes) do
            print("  [" .. i .. "] " .. tostring(gm.id or "no_id") .. " v" .. tostring(gm.version or "?"))
        end
    end
    
    -- Try to detect why evaisa.mp might have failed
    if ModIsEnabled("evaisa.mp") and not _G.steam then
        print("ISSUE DETECTED: evaisa.mp is enabled but steam global is nil")
        print("Possible causes:")
        print("  - NoitaPatcher version mismatch")
        print("  - Missing msvcp140.dll or Visual C++ Redistributable")
        print("  - Corrupted evaisa.mp files")
        print("  - evaisa.mp initialization failed")
        
        -- Try to check the version file
        local version_content = ModTextFileGetContent("mods/evaisa.mp/version.lua")
        if version_content ~= "" then
            print("evaisa.mp version file exists, trying to load...")
            local success, err = pcall(function()
                loadstring(version_content)()
            end)
            if success then
                print("Version loaded successfully")
                if _G.MP_VERSION then
                    print("MP_VERSION: " .. tostring(_G.MP_VERSION))
                end
            else
                print("Failed to load version: " .. tostring(err))
            end
        end
    end
    
    print("=== End Diagnosis ===")
end

print("Bingo Multiplayer: Integration module loaded")

-- Run diagnostics
BingoMultiplayer.diagnoseFramework()

-- Register gamemode with evaisa.mp framework
function BingoMultiplayer.registerGamemode()
    local bingo_gamemode = dofile_once("mods/noita_bingo/src/multiplayer/bingo_gamemode.lua")
    
    if gamemodes and type(gamemodes) == "table" then
        -- Check if already registered
        local already_registered = false
        for _, gamemode in ipairs(gamemodes) do
            if gamemode.id == "noita_bingo" then
                already_registered = true
                print("Bingo Multiplayer: Gamemode already registered")
                break
            end
        end
        
        if not already_registered then
            table.insert(gamemodes, bingo_gamemode)
            print("Bingo Multiplayer: Successfully registered gamemode with evaisa.mp")
            print("Bingo Multiplayer: Gamemode count now: " .. #gamemodes)
            return true
        end
        return true
    else
        print("Bingo Multiplayer: Could not register gamemode - gamemodes table not found")
        print("Bingo Multiplayer: Global gamemodes type: " .. type(_G.gamemodes))
        return false
    end
end

-- Try to register immediately if framework is available
if BingoMultiplayer.isFrameworkAvailable() then
    BingoMultiplayer.registerGamemode()
else
    print("Bingo Multiplayer: Framework not available yet, will try again later")
end