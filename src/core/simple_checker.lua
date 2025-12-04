-- Simple Objective Checker
-- Direct, straightforward checks without complex detector patterns

local function checkObjectiveCompletion(objective)
    if not objective or not objective.auto_track then
        return false
    end
    
    local auto_track = objective.auto_track
    local player = EntityGetWithTag("player_unit")
    if not player or #player == 0 then
        return false
    end
    player = player[1]
    
    if auto_track.type == "kill_with_condition" then
        -- Check if player has killed enough enemies
        -- This is simplified - in a real implementation you'd track kills
        return false  -- Placeholder
        
    elseif auto_track.type == "perk_obtain" then
        -- Check if player has a specific perk
        local perks = EntityGetComponent(player, "PerkPickupComponent")
        if perks then
            for _, perk_comp in ipairs(perks) do
                local perk_id = ComponentGetValue2(perk_comp, "perk_id")
                if perk_id == auto_track.perk_id then
                    return true
                end
            end
        end
        return false
        
    elseif auto_track.type == "gold_collect" then
        -- Check player's current gold
        local x, y = EntityGetTransform(player)
        local money_carried = 0
        for _, entity in ipairs(EntityGetInRadiusWithTag(x, y, 300, "money_item")) do
            if EntityGetIsAlive(entity) then
                local moneycomponent = EntityGetFirstComponent(entity, "MoneyComponent")
                if moneycomponent then
                    money_carried = money_carried + ComponentGetValue2(moneycomponent, "money_type")
                end
            end
        end
        return money_carried >= (auto_track.min_gold or 0)
        
    elseif auto_track.type == "event_triggered" then
        -- This should be checked via event recording
        return false  -- Placeholder
        
    elseif auto_track.type == "biome_reach" then
        -- Check current biome
        local x, y = EntityGetTransform(player)
        local biome = GameGetBiomeName(x, y)
        return biome == auto_track.biome_name
        
    elseif auto_track.type == "time_survive" then
        -- Check elapsed game time
        local frame = GameGetFrameNum()
        local seconds = frame / 60
        return seconds >= (auto_track.min_time or 0)
        
    elseif auto_track.type == "inventory_count" then
        -- Count items in inventory
        local items = GameGetAllInventoryItems(player)
        local count = 0
        if items then
            for _, item_id in ipairs(items) do
                local filename = EntityGetFilename(item_id)
                if not auto_track.item_name or string.match(filename or "", auto_track.item_name) then
                    count = count + 1
                end
            end
        end
        return count >= (auto_track.min_count or 0)
    end
    
    return false
end

BingoCore.SimpleChecker = {
    checkObjectiveCompletion = checkObjectiveCompletion
}
