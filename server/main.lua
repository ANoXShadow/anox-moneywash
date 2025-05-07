local Bridge = require('bridge/loader')
local Framework = Bridge.Load()
local machineStates = {}

local function Debug(msg)
    if Config.Debug then
        print('^3[anox-moneywash]^7 ' .. msg)
    end
end

local function InitializeMachineStates()
    for i, _ in ipairs(Config.MachineLocations) do
        machineStates[i] = {
            inUse = false,
            cooldown = false,
            cooldownEnd = 0,
            userId = nil
        }
    end
    Debug('Initialized machine states')
end

RegisterNetEvent('anox-moneywash:server:removeCard')
AddEventHandler('anox-moneywash:server:removeCard', function(cardItem)
    local source = source  
    if Framework.RemoveItem(source, cardItem, 1) then
        Debug('Removed 1x ' .. cardItem .. ' from player ' .. source)
    else
        Bridge.Notify(_L('failed_remove_card'), "error", _L('error'))
    end
end)

RegisterNetEvent('anox-moneywash:server:returnCard')
AddEventHandler('anox-moneywash:server:returnCard', function(cardItem)
    local source = source    
    if Framework.AddItem(source, cardItem, 1) then
        Debug('Returned 1x ' .. cardItem .. ' to player ' .. source)
    else
        Bridge.Notify(_L('failed_return_card'), "error", _L('error'))
    end
end)

RegisterNetEvent('anox-moneywash:server:removeBlackMoney')
AddEventHandler('anox-moneywash:server:removeBlackMoney', function(amount)
    local source = source    
    if Framework.RemoveItem(source, 'black_money', amount) then
        Debug('Removed $' .. amount .. ' black money from player ' .. source)
    else
        Bridge.Notify(_L('failed_remove_black_money'), "error", _L('error'))
    end
end)

RegisterNetEvent('anox-moneywash:server:collectCleanMoney')
AddEventHandler('anox-moneywash:server:collectCleanMoney', function(amount)
    local source = source
    if Framework.AddMoney(source, amount) then
        local shouldReturnCard = true
        if Config.CardLossChance > 0 then
            local random = math.random(1, 100)
            shouldReturnCard = random > Config.CardLossChance
        end
        if shouldReturnCard then
            Framework.AddItem(source, Config.RequiredItem, 1) 
            Bridge.Notify(_L('received_money_card_returned', amount), "success", _L('money_collected'))
        else
            Bridge.Notify(_L('received_money_card_damaged', amount), "info", _L('money_collected'))
        end
        Debug('Player ' .. source .. ' collected $' .. amount .. ' of clean money. Card returned: ' .. tostring(shouldReturnCard))
    end
end)

RegisterNetEvent('anox-moneywash:server:checkMachineStatus')
AddEventHandler('anox-moneywash:server:checkMachineStatus', function(machineId)
    local source = source
    TriggerClientEvent('anox-moneywash:client:checkMachineStatus', -1, machineId, source)
end)

RegisterNetEvent('anox-moneywash:server:returnMachineStatus')
AddEventHandler('anox-moneywash:server:returnMachineStatus', function(machineId, inUse, requesterSource)
    local source = source    
    if inUse then
        TriggerClientEvent('anox-moneywash:client:machineInUse', requesterSource, machineId)
    end
end)

local activeLaunderers = {}

RegisterNetEvent('anox-moneywash:server:registerActiveMachine')
AddEventHandler('anox-moneywash:server:registerActiveMachine', function(machineId)
    local source = source
    machineStates[machineId] = {
        inUse = true,
        cooldown = false,
        userId = source
    }
    activeLaunderers[machineId] = source
    TriggerClientEvent('anox-moneywash:client:updateMachineState', -1, machineId, 'inUse', source)
    Debug('Player ' .. source .. ' registered as using machine ' .. machineId)
end)

RegisterNetEvent('anox-moneywash:server:unregisterActiveMachine')
AddEventHandler('anox-moneywash:server:unregisterActiveMachine', function(machineId)
    local source = source
    if machineStates[machineId] and machineStates[machineId].userId == source then
        machineStates[machineId].inUse = false
        machineStates[machineId].userId = nil
        if activeLaunderers[machineId] == source then
            activeLaunderers[machineId] = nil
        end
        Debug('Player ' .. source .. ' unregistered from machine ' .. machineId)
    end
end)

RegisterNetEvent('anox-moneywash:server:setMachineCooldown')
AddEventHandler('anox-moneywash:server:setMachineCooldown', function(machineId, cooldownSeconds)
    local source = source
    if machineStates[machineId] and machineStates[machineId].userId == source then
        local cooldownEnd = os.time() + cooldownSeconds
        machineStates[machineId] = {
            inUse = false,
            cooldown = true,
            cooldownEnd = cooldownEnd,
            userId = nil
        }
        TriggerClientEvent('anox-moneywash:client:updateMachineState', -1, machineId, 'cooldown', nil, cooldownEnd)
        SetTimeout(cooldownSeconds * 1000, function()
            if machineStates[machineId] and machineStates[machineId].cooldown then
                machineStates[machineId] = {
                    inUse = false,
                    cooldown = false,
                    cooldownEnd = 0,
                    userId = nil
                }
                TriggerClientEvent('anox-moneywash:client:updateMachineState', -1, machineId, 'available')
                Debug('Machine ' .. machineId .. ' cooldown ended')
            end
        end)
        Debug('Player ' .. source .. ' set machine ' .. machineId .. ' on cooldown for ' .. cooldownSeconds .. ' seconds')
    end
end)

RegisterNetEvent('anox-moneywash:server:requestMachineStates')
AddEventHandler('anox-moneywash:server:requestMachineStates', function()
    local source = source
    TriggerClientEvent('anox-moneywash:client:receiveMachineStates', source, machineStates)
    Debug('Sent machine states to player ' .. source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end    
    InitializeMachineStates()
    Debug('Resource started: ' .. resourceName)
end)

AddEventHandler('playerDropped', function()
    local source = source
   for machineId, state in pairs(machineStates) do
        if state.userId == source then
            machineStates[machineId] = {
                inUse = false,
                cooldown = false,
                cooldownEnd = 0,
                userId = nil
            }
            if activeLaunderers[machineId] == source then
                activeLaunderers[machineId] = nil
            end
            TriggerClientEvent('anox-moneywash:client:updateMachineState', -1, machineId, 'available')            
            Debug('Player ' .. source .. ' disconnected, freeing machine ' .. machineId)
        end
    end
end)