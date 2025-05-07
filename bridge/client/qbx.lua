local Bridge = {}
local QBCore = nil

function Bridge.Init()
    QBCore = exports['qb-core']:GetCoreObject()
    return true
end

function Bridge.GetPlayerData()
    return QBCore.Functions.GetPlayerData()
end

function Bridge.HasItem(itemName)
    local itemCount = exports.ox_inventory:Search('count', itemName)
    return itemCount > 0
end

function Bridge.HasBlackMoney(amount)
    local blackMoneyCount = exports.ox_inventory:Search('count', 'black_money')
    return blackMoneyCount >= amount
end

function Bridge.RegisterEvents()
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerEvent('anox-moneywash:playerLoaded', QBCore.Functions.GetPlayerData())
    end)
    AddEventHandler('playerDropped', function()
        TriggerEvent('anox-moneywash:playerDropped', source)
    end)
end

return Bridge