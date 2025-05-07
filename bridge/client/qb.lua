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
    local playerData = QBCore.Functions.GetPlayerData()    
    if not playerData.items then
        playerData.items = playerData.inventory or {}
    end    
    for k, item in pairs(playerData.items) do
        if (type(item) == 'table' and (item.name == itemName or item.type == itemName)) and 
           (item.amount or item.count or item.qty or 0) > 0 then
            return true
        end
    end
    return false
end

function Bridge.HasBlackMoney(amount)
    local playerData = QBCore.Functions.GetPlayerData()
    for _, item in pairs(playerData.items) do
        if item.name == 'markedbills' and item.info and item.info.worth and item.info.worth >= amount then
            return true
        end
    end    
    return false
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