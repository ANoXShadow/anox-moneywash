local Bridge = {}
local ESX = nil

function Bridge.Init()
    ESX = exports['es_extended']:getSharedObject()
    return true
end

function Bridge.GetPlayer(playerId)
    return ESX.GetPlayerFromId(playerId)
end

function Bridge.HasItem(playerId, item, count)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        if item == 'black_money' then
            local blackMoneyCount = xPlayer.getAccount('black_money').money
            return blackMoneyCount >= count
        else
            return xPlayer.getInventoryItem(item).count >= count
        end
    end
    return false
end

function Bridge.AddItem(playerId, item, count)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        if item == 'black_money' then
            xPlayer.addAccountMoney('black_money', count)
            return true
        else
            if xPlayer.canCarryItem(item, count) then
                xPlayer.addInventoryItem(item, count)
                return true
            else
                return false
            end
        end
    end
    return false
end

function Bridge.RemoveItem(playerId, item, count)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        if item == 'black_money' then
            local blackMoneyCount = xPlayer.getAccount('black_money').money
            if blackMoneyCount >= count then
                xPlayer.removeAccountMoney('black_money', count)
                return true
            else
                return false
            end
        else
            if xPlayer.getInventoryItem(item).count >= count then
                xPlayer.removeInventoryItem(item, count)
                return true
            else
                return false
            end
        end
    end
    return false
end

function Bridge.AddMoney(playerId, amount)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        xPlayer.addMoney(amount)
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