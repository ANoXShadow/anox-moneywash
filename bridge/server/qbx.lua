local Bridge = {}
local QBCore = nil

function Bridge.Init()
    QBCore = exports['qb-core']:GetCoreObject()
    return true
end

function Bridge.GetPlayer(playerId)
    return QBCore.Functions.GetPlayer(playerId)
end

function Bridge.HasItem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local itemCount = exports.ox_inventory:Search(source, 'count', item)
    return itemCount >= count
end

function Bridge.RemoveItem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        return false 
    end
    local removed = Player.Functions.RemoveItem(item, count)
    if removed then
    else
    end
    return removed
end

function Bridge.AddItem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.AddItem(item, count)
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