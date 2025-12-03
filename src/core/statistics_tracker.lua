-- Statistics Tracker
-- Tracks win/loss records, game stats, etc.

---@class StatisticsTracker
local StatisticsTracker = {}
StatisticsTracker.__index = StatisticsTracker

function StatisticsTracker.new()
    local self = setmetatable({}, StatisticsTracker)
    
    -- Session stats (reset when game closes)
    self.session_stats = {
        games_played = 0,
        games_won = 0,
        games_lost = 0,
        player_records = {} -- [player_name] = {wins, losses}
    }
    
    -- Lifetime stats (persisted, NT users only)
    self.lifetime_stats = {
        games_played = 0,
        games_won = 0,
        games_lost = 0,
        player_records = {} -- [nt_user_id] = {name, wins, losses}
    }
    
    -- Load lifetime stats
    self:loadLifetimeStats()
    
    return self
end

---Record a game result (session)
---@param won boolean
---@param opponent_name string|nil
function StatisticsTracker:recordSessionGame(won, opponent_name)
    self.session_stats.games_played = self.session_stats.games_played + 1
    
    if won then
        self.session_stats.games_won = self.session_stats.games_won + 1
    else
        self.session_stats.games_lost = self.session_stats.games_lost + 1
    end
    
    -- Record vs specific opponent
    if opponent_name then
        if not self.session_stats.player_records[opponent_name] then
            self.session_stats.player_records[opponent_name] = {wins = 0, losses = 0}
        end
        
        if won then
            self.session_stats.player_records[opponent_name].wins = 
                self.session_stats.player_records[opponent_name].wins + 1
        else
            self.session_stats.player_records[opponent_name].losses = 
                self.session_stats.player_records[opponent_name].losses + 1
        end
    end
end

---Record a game result (lifetime, NT only)
---@param won boolean
---@param opponent_nt_id string|nil
---@param opponent_name string|nil
function StatisticsTracker:recordLifetimeGame(won, opponent_nt_id, opponent_name)
    self.lifetime_stats.games_played = self.lifetime_stats.games_played + 1
    
    if won then
        self.lifetime_stats.games_won = self.lifetime_stats.games_won + 1
    else
        self.lifetime_stats.games_lost = self.lifetime_stats.games_lost + 1
    end
    
    -- Record vs specific opponent (by NT ID)
    if opponent_nt_id and opponent_name then
        if not self.lifetime_stats.player_records[opponent_nt_id] then
            self.lifetime_stats.player_records[opponent_nt_id] = {
                name = opponent_name,
                wins = 0,
                losses = 0
            }
        end
        
        -- Update name in case it changed
        self.lifetime_stats.player_records[opponent_nt_id].name = opponent_name
        
        if won then
            self.lifetime_stats.player_records[opponent_nt_id].wins = 
                self.lifetime_stats.player_records[opponent_nt_id].wins + 1
        else
            self.lifetime_stats.player_records[opponent_nt_id].losses = 
                self.lifetime_stats.player_records[opponent_nt_id].losses + 1
        end
    end
    
    -- Save after each game
    self:saveLifetimeStats()
end

---Get session record vs a player
---@param player_name string
---@return number, number wins, losses
function StatisticsTracker:getSessionRecord(player_name)
    local record = self.session_stats.player_records[player_name]
    if record then
        return record.wins, record.losses
    end
    return 0, 0
end

---Get lifetime record vs a player (NT ID)
---@param nt_user_id string
---@return number, number wins, losses
function StatisticsTracker:getLifetimeRecord(nt_user_id)
    local record = self.lifetime_stats.player_records[nt_user_id]
    if record then
        return record.wins, record.losses
    end
    return 0, 0
end

---Get formatted record string
---@param player_identifier string
---@param use_lifetime boolean
---@return string
function StatisticsTracker:getRecordString(player_identifier, use_lifetime)
    local session_wins, session_losses = 0, 0
    local lifetime_wins, lifetime_losses = 0, 0
    
    if use_lifetime then
        lifetime_wins, lifetime_losses = self:getLifetimeRecord(player_identifier)
    end
    session_wins, session_losses = self:getSessionRecord(player_identifier)
    
    if use_lifetime then
        return string.format("Session: %d-%d | Lifetime: %d-%d",
            session_wins, session_losses,
            lifetime_wins, lifetime_losses)
    else
        return string.format("Session: %d-%d", session_wins, session_losses)
    end
end

---Load lifetime stats from persistent storage
function StatisticsTracker:loadLifetimeStats()
    local games_played = ModSettingGet("noita_bingo.lifetime_games_played")
    self.lifetime_stats.games_played = tonumber(games_played) or 0
    
    local games_won = ModSettingGet("noita_bingo.lifetime_games_won")
    self.lifetime_stats.games_won = tonumber(games_won) or 0
    
    local games_lost = ModSettingGet("noita_bingo.lifetime_games_lost")
    self.lifetime_stats.games_lost = tonumber(games_lost) or 0
    
    -- Load player records
    local records_str = ModSettingGet("noita_bingo.lifetime_player_records")
    if records_str and records_str ~= "" then
        self.lifetime_stats.player_records = self:deserializePlayerRecords(records_str)
    end
end

---Save lifetime stats to persistent storage
function StatisticsTracker:saveLifetimeStats()
    ModSettingSet("noita_bingo.lifetime_games_played", tostring(self.lifetime_stats.games_played))
    ModSettingSet("noita_bingo.lifetime_games_won", tostring(self.lifetime_stats.games_won))
    ModSettingSet("noita_bingo.lifetime_games_lost", tostring(self.lifetime_stats.games_lost))
    
    -- Save player records
    local records_str = self:serializePlayerRecords(self.lifetime_stats.player_records)
    ModSettingSet("noita_bingo.lifetime_player_records", records_str)
end

---Serialize player records to string
---@param records table
---@return string
function StatisticsTracker:serializePlayerRecords(records)
    local parts = {}
    for nt_id, record in pairs(records) do
        local record_str = string.format("%s:%s:%d:%d",
            nt_id,
            record.name,
            record.wins,
            record.losses)
        table.insert(parts, record_str)
    end
    return table.concat(parts, "|")
end

---Deserialize player records from string
---@param str string
---@return table
function StatisticsTracker:deserializePlayerRecords(str)
    local records = {}
    for record_str in string.gmatch(str, "([^|]+)") do
        local nt_id, name, wins, losses = string.match(record_str, "([^:]+):([^:]+):([^:]+):([^:]+)")
        if nt_id and name and wins and losses then
            records[nt_id] = {
                name = name,
                wins = tonumber(wins) or 0,
                losses = tonumber(losses) or 0
            }
        end
    end
    return records
end

---Reset session stats
function StatisticsTracker:resetSession()
    self.session_stats = {
        games_played = 0,
        games_won = 0,
        games_lost = 0,
        player_records = {}
    }
end

BingoCore.StatisticsTracker = StatisticsTracker
