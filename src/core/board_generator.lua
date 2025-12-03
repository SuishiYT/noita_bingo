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
    math.randomseed(GameGetFrameNum() + os.time())
    
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
    -- Get category system and settings
    local category_system = BingoConfig.category_system
    local settings = BingoConfig.settings
    
    -- Generate board
    local board = BoardGenerator.generateBoard(game_type, category_system, settings)
    
    -- Create appropriate game mode
    local game = nil
    
    if game_type == "traditional" then
        game = BingoCore.TraditionalBingo.new(board.objectives, is_multiplayer)
        game.board = board
    elseif game_type == "lockout" then
        game = BingoCore.Lockout.new(board.objectives)
        game.board = board
    elseif game_type == "blackout" then
        game = BingoCore.Blackout.new(board.objectives)
        game.board = board
    elseif game_type == "rush" then
        local time_limit = settings:get("rush_time_limit", 600)
        game = BingoCore.Rush.new(board.objectives, time_limit)
        game.board = board
    else
        -- Default to traditional
        game = BingoCore.TraditionalBingo.new(board.objectives, is_multiplayer)
        game.board = board
    end
    
    return game
end

BingoCore.BoardGenerator = BoardGenerator
