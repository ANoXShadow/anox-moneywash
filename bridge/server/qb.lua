local Bridge = {}
local QBCore = nil

function Bridge.Init()
    QBCore = exports['qb-core']:GetCoreObject()
    return true
end

function Bridge.GetPlayer(playerId)
    return QBCore.Functions.GetPlayer(playerId)
end

function Bridge.RemoveItem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        return false 
    end
    for slot, inventoryItem in pairs(Player.PlayerData.items) do
        if inventoryItem then
        end
    end
    if item == 'black_money' or item == 'markedbills' then
        local markedBillsStacks = {}
        local totalWorth = 0
        for slot, inventoryItem in pairs(Player.PlayerData.items) do
            if inventoryItem and inventoryItem.name == 'markedbills' and 
               inventoryItem.info and inventoryItem.info.worth then
                table.insert(markedBillsStacks, {
                    slot = slot,
                    worth = inventoryItem.info.worth,
                    amount = inventoryItem.amount
                })
                totalWorth = totalWorth + inventoryItem.info.worth
            end
        end
        if totalWorth < count then
            return false
        end
        table.sort(markedBillsStacks, function(a, b) 
            return a.worth > b.worth 
        end)
        local remainingToRemove = count
        for _, stack in ipairs(markedBillsStacks) do
            if remainingToRemove > 0 then
                if stack.worth <= remainingToRemove then
                    Player.Functions.RemoveItem('markedbills', stack.amount, stack.slot)
                    remainingToRemove = remainingToRemove - stack.worth
                else
                    Player.Functions.RemoveItem('markedbills', stack.amount, stack.slot)
                    Player.Functions.AddItem('markedbills', 1, false, {
                        worth = stack.worth - remainingToRemove
                    }, stack.slot)                    
                    remainingToRemove = 0
                end
            end
        end

        if remainingToRemove > 0 then
            return false
        end
        return true
    else
        local removed = Player.Functions.RemoveItem(item, count)
        return removed
    end
end

function Bridge.AddItem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    if item == 'black_money' or item == 'markedbills' then
        Player.Functions.AddItem('markedbills', 1, false, {
            worth = count
        })
        return true
    else
        return Player.Functions.AddItem(item, count)
    end
end

function Bridge.HasItem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    if item == 'black_money' or item == 'markedbills' then
        local markedBills = Player.Functions.GetItemByName('markedbills')
        if markedBills and markedBills.info and markedBills.info.worth then
            return markedBills.info.worth >= count
        end
        return false
    else
        local playerItem = Player.Functions.GetItemByName(item)
        return playerItem and playerItem.amount >= count
    end
end

function Bridge.AddMoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.AddMoney('cash', amount)
        return true
    end
    return false
end

function Bridge.RegisterEvents()
    AddEventHandler('playerDropped', function()
        TriggerEvent('anox-moneywash:playerDropped', source)
    end)
end

return Bridge