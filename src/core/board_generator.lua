-- Board Generator
-- Creates new bingo boards with proper objective selection

---@class BoardGenerator
local BoardGenerator = {}
BoardGenerator.__index = BoardGenerator

---Generate a new bingo board
---@param game_type string
---@param category_system CategorySystem
---@param settings Settings
---@return BingoBoard
function BoardGenerator.generateBoard(game_type, category_system, settings)
    local board_size = settings:get("board_size", 5)
    local objective_count = board_size * board_size
    
    -- Apply category weights and limits from settings
    local weights = settings:get("category_weights", {})
    local limits = settings:get("category_limits", {})
    
    for category, weight in pairs(weights) do
        category_system:setWeight(category, weight)
    end
    
    for category, limit in pairs(limits) do
        category_system:setLimit(category, limit)
    end
    
    -- Select objectives based on weights and limits
    local selected_objectives = category_system:selectObjectives(objective_count)
    
    -- Shuffle objectives for randomness
    BoardGenerator.shuffleTable(selected_objectives)
    
    -- Create board
    local board = BingoCore.BingoBoard.new(selected_objectives, board_size, game_type)
    
    return board
end

---Shuffle a table in place
---@param t table
function BoardGenerator.shuffleTable(t)
    -- Use GameGetFrameNum() as seed (os library not available in Noita)
    math.randomseed(GameGetFrameNum())
    
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

---Create a new game with a generated board
---@param game_type string "traditional", "lockout", "blackout", "rush"
---@param is_multiplayer boolean
---@return GameMode
function BoardGenerator.createNewGame(game_type, is_multiplayer)
    GamePrint("[BoardGen] createNewGame called with type=" .. tostring(game_type))
    
    -- Get category system and settings
    local category_system = BingoConfig.category_system
    local settings = BingoConfig.settings
    
    if not category_system then
        GamePrint("[BoardGen] ERROR: BingoConfig.category_system is nil!")
        return nil
    end
    if not settings then
        GamePrint("[BoardGen] ERROR: BingoConfig.settings is nil!")
        return nil
    end
    
    GamePrint("[BoardGen] Calling generateBoard...")
    
    -- Generate board
    local board = BoardGenerator.generateBoard(game_type, category_system, settings)
    
    if not board then
        GamePrint("[BoardGen] ERROR: generateBoard returned nil!")
        return nil
    end
    
    GamePrint("[BoardGen] Board generated successfully with " .. #board.objectives .. " objectives")
    
    -- Create appropriate game mode
    local game = nil
    
    if game_type == "traditional" then
        GamePrint("[BoardGen] Creating TraditionalBingo game...")
        if BingoCore.TraditionalBingo then
            game = BingoCore.TraditionalBingo.new(board.objectives, is_multiplayer)
            game.board = board
        else
            GamePrint("[BoardGen] ERROR: BingoCore.TraditionalBingo not found!")
        end
    elseif game_type == "lockout" then
        GamePrint("[BoardGen] Creating Lockout game...")
        if BingoCore.Lockout then
            game = BingoCore.Lockout.new(board.objectives)
            game.board = board
        else
            GamePrint("[BoardGen] ERROR: BingoCore.Lockout not found!")
        end
    elseif game_type == "blackout" then
        GamePrint("[BoardGen] Creating Blackout game...")
        if BingoCore.Blackout then
            game = BingoCore.Blackout.new(board.objectives)
            game.board = board
        else
            GamePrint("[BoardGen] ERROR: BingoCore.Blackout not found!")
        end
    elseif game_type == "rush" then
        GamePrint("[BoardGen] Creating Rush game...")
        if BingoCore.Rush then
            local time_limit = settings:get("rush_time_limit", 600)
            game = BingoCore.Rush.new(board.objectives, time_limit)
            game.board = board
        else
            GamePrint("[BoardGen] ERROR: BingoCore.Rush not found!")
        end
    else
        GamePrint("[BoardGen] Unknown game type, defaulting to traditional")
        -- Default to traditional
        if BingoCore.TraditionalBingo then
            game = BingoCore.TraditionalBingo.new(board.objectives, is_multiplayer)
            game.board = board
        else
            GamePrint("[BoardGen] ERROR: BingoCore.TraditionalBingo not found even for fallback!")
        end
    end
    
    if game then
        GamePrint("[BoardGen] Game created successfully!")
    else
        GamePrint("[BoardGen] ERROR: Game object was never created!")
    end
    
    return game
end

BingoCore.BoardGenerator = BoardGenerator
