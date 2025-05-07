local Bridge = {}
local ESX = nil

function Bridge.Init()
    ESX = exports['es_extended']:getSharedObject()
    return true
end

function Bridge.GetPlayerData()
    return ESX.GetPlayerData()
end

function Bridge.HasItem(itemName)
    local playerData = ESX.GetPlayerData()
    for _, item in ipairs(playerData.inventory) do
        if item.name == itemName and item.count > 0 then
            return true
        end
    end
    return false
end

function Bridge.HasBlackMoney(amount)
    local playerData = ESX.GetPlayerData()    
    for _, account in ipairs(playerData.accounts) do
        if account.name == 'black_money' then
            return account.money >= amount
        end
    end
    return false
end

function Bridge.RegisterEvents()
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        TriggerEvent('anox-moneywash:playerLoaded', xPlayer)
    end)
    AddEventHandler('playerDropped', function()
        TriggerEvent('anox-moneywash:playerDropped', source)
    end)
end

return Bridge