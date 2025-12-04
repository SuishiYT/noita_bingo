-- Game State Persistence
-- Handles saving and loading game state

---@class GameStatePersistence
local GameStatePersistence = {}

---Save current game state
---@param game GameMode
function GameStatePersistence.saveGame(game)
    if not game or not game.board then
        return
    end
    
    -- Save board state
    local board = game.board
    
    -- Convert cleared array to string
    local cleared_data = {}
    for i = 1, #board.cleared do
        cleared_data[i] = board.cleared[i] and "1" or "0"
    end
    local cleared_str = table.concat(cleared_data, "")
    
    -- Convert locked array to string
    local locked_data = {}
    for i = 1, #board.locked do
        locked_data[i] = board.locked[i] and "1" or "0"
    end
    local locked_str = table.concat(locked_data, "")
    
    -- Save objective IDs
    local objective_ids = {}
    for i = 1, #board.objectives do
        if board.objectives[i] then
            objective_ids[i] = board.objectives[i].id
        else
            objective_ids[i] = ""
        end
    end
    local objectives_str = table.concat(objective_ids, ",")
    
    -- Save to Noita settings
    ModSettingSet("noita_bingo.game_type", board.game_type)
    ModSettingSet("noita_bingo.board_size", board.size)
    ModSettingSet("noita_bingo.cleared", cleared_str)
    ModSettingSet("noita_bingo.locked", locked_str)
    ModSettingSet("noita_bingo.objectives", objectives_str)
    ModSettingSet("noita_bingo.completed", game.completed and "true" or "false")
    ModSettingSet("noita_bingo.start_time", tostring(game.start_time))
    
    -- Save multiplayer state if applicable
    if game.is_multiplayer then
        ModSettingSet("noita_bingo.is_multiplayer", "true")
    else
        ModSettingSet("noita_bingo.is_multiplayer", "false")
    end
end

---Load saved game state
---@return GameMode|nil
function GameStatePersistence.loadGame()
    local game_type = ModSettingGet("noita_bingo.game_type")
    if not game_type or game_type == "" then
        return nil
    end
    
    local board_size = tonumber(ModSettingGet("noita_bingo.board_size")) or 5
    local cleared_str = ModSettingGet("noita_bingo.cleared") or ""
    local locked_str = ModSettingGet("noita_bingo.locked") or ""
    local objectives_str = ModSettingGet("noita_bingo.objectives") or ""
    local is_multiplayer = ModSettingGet("noita_bingo.is_multiplayer") == "true"
    
    -- Parse objective IDs
    local objective_ids = {}
    for id in string.gmatch(objectives_str, "([^,]+)") do
        table.insert(objective_ids, id)
    end
    
    -- Reconstruct objectives from IDs
    local objectives = {}
    for i, obj_id in ipairs(objective_ids) do
        if obj_id ~= "" then
            -- Find objective in category system
            local found_obj = nil
            for category, data in pairs(BingoConfig.category_system.categories) do
                for _, obj in ipairs(data.objectives) do
                    if obj.id == obj_id then
                        found_obj = obj
                        break
                    end
                end
                if found_obj then break end
            end
            
            if found_obj then
                objectives[i] = found_obj
            end
        end
    end
    
    -- Create board
    local board = BingoCore.BingoBoard.new(objectives, board_size, game_type)
    
    -- Restore cleared state
    for i = 1, math.min(#cleared_str, board_size * board_size) do
        board.cleared[i] = cleared_str:sub(i, i) == "1"
    end
    
    -- Restore locked state
    for i = 1, math.min(#locked_str, board_size * board_size) do
        board.locked[i] = locked_str:sub(i, i) == "1"
    end
    
    -- Create game mode
    local game = nil
    if game_type == "traditional" then
        game = BingoCore.TraditionalBingo.new(objectives, is_multiplayer)
    elseif game_type == "lockout" then
        game = BingoCore.Lockout.new(objectives)
    elseif game_type == "blackout" then
        game = BingoCore.Blackout.new(objectives)
    elseif game_type == "rush" then
        game = BingoCore.Rush.new(objectives, 600)
    end
    
    if game then
        game.board = board
        game.completed = ModSettingGet("noita_bingo.completed") == "true"
        game.start_time = tonumber(ModSettingGet("noita_bingo.start_time")) or GameGetFrameNum()
    end
    
    return game
end

---Clear saved game
function GameStatePersistence.clearSave()
    ModSettingSet("noita_bingo.game_type", "")
    ModSettingSet("noita_bingo.board_size", "")
    ModSettingSet("noita_bingo.cleared", "")
    ModSettingSet("noita_bingo.locked", "")
    ModSettingSet("noita_bingo.objectives", "")
    ModSettingSet("noita_bingo.completed", "")
    ModSettingSet("noita_bingo.start_time", "")
    ModSettingSet("noita_bingo.is_multiplayer", "")
end

BingoCore.GameStatePersistence = GameStatePersistence
