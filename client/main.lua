local Bridge = require('bridge/loader')
local Framework = Bridge.Load()
local machineObjects = {}
local activeMachines = {}
local globalMachineStates = {}
local playerInside = false
local activeZones = {}
local displayingCooldown = {}
local activeTextUI = nil

local function Debug(msg)
    if Config.Debug then
        print('^3[anox-moneywash]^7 ' .. msg)
    end
end

local function SyncMachineStates()
    TriggerServerEvent('anox-moneywash:server:requestMachineStates')
end

local function CreateWashingMachines()
    for i, machine in ipairs(Config.MachineLocations) do
        local prop = CreateObject(GetHashKey(Config.MachineProps.idle), machine.coords.x, machine.coords.y, machine.coords.z - 1.0, false, false, false)
        SetEntityHeading(prop, machine.heading)
        FreezeEntityPosition(prop, true)
        machineObjects[i] = {
            object = prop,
            state = 'idle',
            id = i
        }
        Debug('Created washing machine at ' .. machine.coords.x .. ', ' .. machine.coords.y .. ', ' .. machine.coords.z)
    end
end

local function ChangeMachineState(machineId, state)
    if not machineObjects[machineId] then return end
    local machine = machineObjects[machineId]
    local coords = GetEntityCoords(machine.object)
    local heading = GetEntityHeading(machine.object)
    DeleteEntity(machine.object)
    local propName = Config.MachineProps.idle
    if state == 'inserted' then
        propName = Config.MachineProps.inserted
    elseif state == 'spinning' then
        propName = Config.MachineProps.spinning
    end
    local prop = CreateObject(GetHashKey(propName), coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(prop, heading)
    FreezeEntityPosition(prop, true)
    machineObjects[machineId].object = prop
    machineObjects[machineId].state = state
    Debug('Changed machine ' .. machineId .. ' state to ' .. state)
end

local function SetupTargetInteractions()
    for i, machine in ipairs(Config.MachineLocations) do
        local options = {
            {
                name = 'anox_moneywash:useMachine_' .. i,
                icon = Config.UISystem.icon,
                label = _L('use_washing_machine'),
                distance = 2.0,
                onSelect = function()
                    UseMachine(i)
                end,
                canInteract = function()
                    if activeMachines[i] and (activeMachines[i].cooldown or activeMachines[i].processing or activeMachines[i].moneyReady) then
                        return false
                    end
                    return true
                end
            }
        }
        options[#options+1] = {
            name = 'anox_moneywash:collectMoney_' .. i,
            icon = 'fa-solid fa-money-bill-wave',
            label = _L('collect_clean_money'),
            distance = 2.0,
            onSelect = function()
                CollectCleanMoney(i)
            end,
            canInteract = function()
                if activeMachines[i] and activeMachines[i].moneyReady then
                    return true
                end
                return false
            end
        }
        options[#options+1] = {
            name = 'anox_moneywash:retrieveCard_' .. i,
            icon = 'fa-solid fa-credit-card',
            label = _L('retrieve_laundry_card'),
            distance = 2.0,
            onSelect = function()
                RetrieveCard(i)
            end,
            canInteract = function()
                if activeMachines[i] and activeMachines[i].cardInserted and not activeMachines[i].processing then
                    return true
                end
                return false
            end
        }
        local zoneId = Bridge.Target.AddBoxZone({
            name = 'anox_moneywash:machine_' .. i,
            coords = machine.coords,
            size = vec3(1.5, 1.5, 2.0),
            rotation = machine.heading,
            debug = Config.Debug,
            options = options,
            distance = 2.0
        })
        activeZones[i] = zoneId
        Debug('Created target zone for machine ' .. i)
    end
end

local function RemoveTargetZones()
    for i, zoneId in pairs(activeZones) do
        Bridge.Target.RemoveZone(zoneId)
    end
    activeZones = {}
    Debug('Removed all target zones')
end

local function CheckRequiredItem()
    return Framework.HasItem(Config.RequiredItem)
end

local function CheckBlackMoney(amount)
    return Framework.HasBlackMoney(amount)
end

local function CreateMachineBlips()
    for i, machine in ipairs(Config.MachineLocations) do
        if machine.blip and machine.blip.enabled then
            local blip = AddBlipForCoord(machine.coords.x, machine.coords.y, machine.coords.z)
            SetBlipSprite(blip, machine.blip.sprite or 108)
            SetBlipColour(blip, machine.blip.color or 0)
            SetBlipScale(blip, machine.blip.scale or 0.7)
            SetBlipAsShortRange(blip, machine.blip.shortRange or true)
            SetBlipDisplay(blip, machine.blip.display or 4)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(machine.label or 'Money Washing Machine')
            EndTextCommandSetBlipName(blip)
            Debug('Created blip for washing machine at ' .. machine.coords.x .. ', ' .. machine.coords.y .. ', ' .. machine.coords.z)
        end
    end
end

function UseMachine(machineId)
    if activeMachines[machineId] then
        if activeMachines[machineId].cooldown then
            local remainingTime = math.floor((activeMachines[machineId].cooldownEnd - GetGameTimer()) / 1000)
            Bridge.Notify(_L('machine_cooldown', remainingTime), "error", _L('machine_unavailable'))
            return
        elseif activeMachines[machineId].processing or activeMachines[machineId].moneyReady then
            Bridge.Notify(_L('machine_already_in_use'), "error", _L('machine_in_use'))
            return
        elseif activeMachines[machineId].cardInserted then
            Bridge.Notify(_L('proceed_to_money_entry'), "info", _L('card_already_inserted'))
            ProceedToMoneyInput(machineId)
            return
        end
    end
    TriggerServerEvent('anox-moneywash:server:checkMachineStatus', machineId)
    local checkTimeout = 500
    while checkTimeout > 0 do
        if activeMachines[machineId] and activeMachines[machineId].externalUse then
            Bridge.Notify(_L('machine_already_in_use'), "error", _L('machine_in_use'))
            activeMachines[machineId].externalUse = nil
            return
        end
        checkTimeout = checkTimeout - 10
        Wait(10)
    end
    if not CheckRequiredItem() then
        Bridge.Notify(_L('no_laundry_card'), "error", _L('missing_item'))
        return
    end
    local alert = Bridge.AlertDialog(
        _L('money_washing'), 
        _L('money_wash_info', 
            Config.MinimumWashAmount, 
            Config.WashingFeePercentage, 
            Config.MachineLocations[machineId].washingTime,
            Config.MachineLocations[machineId].cooldown,
            Config.CollectionTimeWindow
        ), 
        "moneyWash"
    )
    if alert ~= 'confirm' then return end
    TriggerServerEvent('anox-moneywash:server:removeCard', Config.RequiredItem)
    if not Bridge.ProgressBar(_L('inserting_card'), 2000, "cardInsert") then
        TriggerServerEvent('anox-moneywash:server:returnCard', Config.RequiredItem)
        return
    end
    activeMachines[machineId] = {
        cardInserted = true
    }
    TriggerServerEvent('anox-moneywash:server:registerActiveMachine', machineId)
    ChangeMachineState(machineId, 'inserted')
    ProceedToMoneyInput(machineId)
end

function ProceedToMoneyInput(machineId)
    local input = Bridge.InputDialog(_L('enter_amount_header'), "moneyAmount")
    if not input or not input[1] then
        return
    end
    local amount = tonumber(input[1])
    if not CheckBlackMoney(amount) then
        Bridge.Notify(_L('not_enough_money_card_remains'), "error", _L('not_enough_black_money'))
        return
    end
    local fee = math.floor(amount * (Config.WashingFeePercentage / 100))
    local finalAmount = amount - fee
    StartWashingProcess(machineId, amount, finalAmount)
end

function RetrieveCard(machineId)
    if not activeMachines[machineId] or not activeMachines[machineId].cardInserted then
        Bridge.Notify(_L('no_card_in_machine'), "error", _L('no_card_found'))
        return
    end
    if not Bridge.ProgressBar(_L('retrieving_card'), 2000, "cardInsert") then
        return
    end
    TriggerServerEvent('anox-moneywash:server:returnCard', Config.RequiredItem)
    TriggerServerEvent('anox-moneywash:server:unregisterActiveMachine', machineId)
    activeMachines[machineId] = nil
    ChangeMachineState(machineId, 'idle')
    Bridge.Notify(_L('retrieved_laundry_card'), "success", _L('card_retrieved'))
end

function StartWashingProcess(machineId, dirtyAmount, cleanAmount)
    activeMachines[machineId].processing = true
    activeMachines[machineId].cardInserted = nil
    TriggerServerEvent('anox-moneywash:server:removeBlackMoney', dirtyAmount)
    Wait(1000)
    ChangeMachineState(machineId, 'spinning')
    local washingTime = Config.WashingTime
    if Config.MachineLocations[machineId].washingTime then
        washingTime = Config.MachineLocations[machineId].washingTime
    end
    activeMachines[machineId] = {
        dirtyAmount = dirtyAmount,
        cleanAmount = cleanAmount,
        startTime = GetGameTimer(),
        endTime = GetGameTimer() + (washingTime * 1000),
        processing = true,
        moneyReady = false
    }
    StartMachineCountdown(machineId)
    Bridge.Notify(_L('machine_washing', dirtyAmount), "success", _L('washing_started'))
    CreateThread(function()
        while activeMachines[machineId] do
            local currentTime = GetGameTimer()
            if activeMachines[machineId] and activeMachines[machineId].processing and not activeMachines[machineId].moneyReady and currentTime > activeMachines[machineId].endTime then
                Bridge.Notify(_L('money_ready_collection', Config.CollectionTimeWindow), "success", _L('washing_complete'))
                activeMachines[machineId].processing = false
                activeMachines[machineId].moneyReady = true
                activeMachines[machineId].collectionEndTime = currentTime + (Config.CollectionTimeWindow * 1000)
                StartCollectionCountdown(machineId)
            end
            if activeMachines[machineId] and activeMachines[machineId].moneyReady and currentTime > activeMachines[machineId].collectionEndTime then
                Bridge.Notify(_L('failed_collect_time'), "error", _L('money_lost'))
                local cooldownTime = Config.MachineCooldown
                if Config.MachineLocations[machineId].cooldown then
                    cooldownTime = Config.MachineLocations[machineId].cooldown
                end
                TriggerServerEvent('anox-moneywash:server:setMachineCooldown', machineId, cooldownTime)
                activeMachines[machineId] = {
                    cooldown = true,
                    cooldownEnd = currentTime + (cooldownTime * 1000)
                }
                ChangeMachineState(machineId, 'idle')
                CreateThread(function()
                    DisplayMachineCooldown(machineId, cooldownTime)
                end)
                return
            end
            Wait(1000)
        end
    end)
end

function CollectCleanMoney(machineId)
    if not activeMachines[machineId] or not activeMachines[machineId].moneyReady then
        Bridge.Notify(_L('no_clean_money'), "error", _L('no_money_to_collect'))
        return
    end
    local cleanAmount = activeMachines[machineId].cleanAmount
    if not Bridge.ProgressBar(_L('collecting_money'), 2000, "collectMoney") then
        return
    end
    TriggerServerEvent('anox-moneywash:server:collectCleanMoney', cleanAmount)
    local cooldownTime = Config.MachineCooldown
    if Config.MachineLocations[machineId].cooldown then
        cooldownTime = Config.MachineLocations[machineId].cooldown
    end
    TriggerServerEvent('anox-moneywash:server:setMachineCooldown', machineId, cooldownTime)
    activeMachines[machineId] = {
        cooldown = true,
        cooldownEnd = GetGameTimer() + (cooldownTime * 1000)
    }
    ChangeMachineState(machineId, 'idle')
    CreateThread(function()
        DisplayMachineCooldown(machineId, cooldownTime)
    end)
end

function DisplayMachineCooldown(machineId, cooldownTime)
    displayingCooldown[machineId] = true
    CreateThread(function()
        local remainingTime = cooldownTime
        while remainingTime > 0 and activeMachines[machineId] and activeMachines[machineId].cooldown do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local machineCoords = Config.MachineLocations[machineId].coords
            local distance = #(playerCoords - machineCoords)
            if distance <= 3.0 then
                if activeTextUI == nil or activeTextUI == machineId then
                    activeTextUI = machineId
                    Bridge.ShowTextUI(_L('machine_cooldown_ui', remainingTime), "cooldown")
                end
            else
                if activeTextUI == machineId then
                    Bridge.HideTextUI()
                    activeTextUI = nil
                end
            end
            Wait(1000)
            remainingTime = remainingTime - 1
        end
        if activeTextUI == machineId then
            Bridge.HideTextUI()
            activeTextUI = nil
        end
        displayingCooldown[machineId] = nil
        if activeMachines[machineId] and activeMachines[machineId].cooldown then
            activeMachines[machineId] = nil
            Debug('Machine ' .. machineId .. ' cooldown ended')
        end
    end)
end

function StartCollectionCountdown(machineId)
    if not activeMachines[machineId] or not activeMachines[machineId].moneyReady then return end
    local collectionTimeWindow = Config.CollectionTimeWindow
    local timeLeft = math.floor((activeMachines[machineId].collectionEndTime - GetGameTimer()) / 1000)
    CreateThread(function()
        while timeLeft > 0 and activeMachines[machineId] and activeMachines[machineId].moneyReady do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local machineCoords = Config.MachineLocations[machineId].coords
            local distance = #(playerCoords - machineCoords)
            if distance <= 3.0 then
                if activeTextUI == nil or activeTextUI == machineId then
                    activeTextUI = machineId
                    Bridge.ShowTextUI(_L('collection_countdown', timeLeft), "cooldown")
                end
            else
                if activeTextUI == machineId then
                    Bridge.HideTextUI()
                    activeTextUI = nil
                end
            end
            Wait(1000)
            timeLeft = timeLeft - 1
        end
        if activeTextUI == machineId then
            Bridge.HideTextUI()
            activeTextUI = nil
        end
    end)
end

function StartMachineCountdown(machineId)
    local washingTime = Config.WashingTime
    if Config.MachineLocations[machineId].washingTime then
        washingTime = Config.MachineLocations[machineId].washingTime
    end
    local timeLeft = washingTime
    CreateThread(function()
        while timeLeft > 0 and activeMachines[machineId] and activeMachines[machineId].processing do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local machineCoords = Config.MachineLocations[machineId].coords
            local distance = #(playerCoords - machineCoords)
            if distance <= 3.0 then
                if activeTextUI == nil or activeTextUI == machineId then
                    activeTextUI = machineId
                    Bridge.ShowTextUI(_L('washing_progress', timeLeft), "processing")
                end
            else
                if activeTextUI == machineId then
                    Bridge.HideTextUI()
                    activeTextUI = nil
                end
            end
            Wait(1000)
            timeLeft = timeLeft - 1
        end
        if activeMachines[machineId] and activeMachines[machineId].moneyReady then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local machineCoords = Config.MachineLocations[machineId].coords
            local distance = #(playerCoords - machineCoords)
            if distance <= 3.0 then
                if activeTextUI == nil or activeTextUI == machineId then
                    activeTextUI = machineId
                    Bridge.ShowTextUI(_L('money_ready_collection_ui'), "moneyReady")
                    Wait(3000)
                    if activeTextUI == machineId then
                        Bridge.HideTextUI()
                        activeTextUI = nil
                    end
                end
            end
        end
        if activeTextUI == machineId then
            Bridge.HideTextUI()
            activeTextUI = nil
        end
    end)
end

function HideAllTextUIs()
    Bridge.HideTextUI()
    activeTextUI = nil
end

RegisterNetEvent('anox-moneywash:client:receiveMachineStates')
AddEventHandler('anox-moneywash:client:receiveMachineStates', function(states)
    globalMachineStates = states
    for machineId, state in pairs(states) do
        if state.cooldown and not activeMachines[machineId] then
            local currentTime = os.time()
            local remainingTime = state.cooldownEnd - currentTime
            if remainingTime > 0 then
                activeMachines[machineId] = {
                    cooldown = true,
                    cooldownEnd = GetGameTimer() + (remainingTime * 1000)
                }
                ChangeMachineState(machineId, 'idle')
                if not displayingCooldown[machineId] then
                    CreateThread(function()
                        DisplayMachineCooldown(machineId, remainingTime)
                    end)
                end
            end
        elseif state.inUse and not activeMachines[machineId] then
            if state.userId ~= GetPlayerServerId(PlayerId()) then
                activeMachines[machineId] = {
                    externalUse = true
                }
            end
        end
    end
    Debug('Received and applied machine states from server')
end)

RegisterNetEvent('anox-moneywash:client:updateMachineState')
AddEventHandler('anox-moneywash:client:updateMachineState', function(machineId, state, userId, cooldownEnd)
    if not globalMachineStates[machineId] then
        globalMachineStates[machineId] = {}
    end
    if state == 'inUse' then
        globalMachineStates[machineId].inUse = true
        globalMachineStates[machineId].cooldown = false
        globalMachineStates[machineId].userId = userId
        if userId ~= GetPlayerServerId(PlayerId()) then
            if not activeMachines[machineId] then
                activeMachines[machineId] = {
                    externalUse = true
                }
            else
                activeMachines[machineId].externalUse = true
            end
        end
    elseif state == 'cooldown' then
        globalMachineStates[machineId].inUse = false
        globalMachineStates[machineId].cooldown = true
        globalMachineStates[machineId].cooldownEnd = cooldownEnd
        globalMachineStates[machineId].userId = nil
        if not activeMachines[machineId] or not activeMachines[machineId].processing then
            local currentTime = GetGameTimer() / 1000
            local remainingTime = cooldownEnd - currentTime
            if remainingTime > 0 then
                activeMachines[machineId] = {
                    cooldown = true,
                    cooldownEnd = GetGameTimer() + (remainingTime * 1000)
                }
                ChangeMachineState(machineId, 'idle')
                if not displayingCooldown[machineId] then
                    CreateThread(function()
                        DisplayMachineCooldown(machineId, remainingTime)
                    end)
                end
            end
        end
    elseif state == 'available' then
        globalMachineStates[machineId].inUse = false
        globalMachineStates[machineId].cooldown = false
        globalMachineStates[machineId].cooldownEnd = 0
        globalMachineStates[machineId].userId = nil
        if activeMachines[machineId] and not activeMachines[machineId].processing and not activeMachines[machineId].moneyReady then
            activeMachines[machineId] = nil
        end
    end
    Debug('Updated machine ' .. machineId .. ' state to ' .. state)
end)

RegisterNetEvent('anox-moneywash:client:checkMachineStatus')
AddEventHandler('anox-moneywash:client:checkMachineStatus', function(machineId, requesterSource)
    if GetPlayerServerId(PlayerId()) ~= requesterSource and activeMachines[machineId] then
        TriggerServerEvent('anox-moneywash:server:returnMachineStatus', machineId, true, requesterSource)
    end
end)

RegisterNetEvent('anox-moneywash:client:machineInUse')
AddEventHandler('anox-moneywash:client:machineInUse', function(machineId)
    if not activeMachines[machineId] then
        activeMachines[machineId] = {externalUse = true}
    else
        activeMachines[machineId].externalUse = true
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CreateWashingMachines()
    CreateMachineBlips()
    SetupTargetInteractions()
    Wait(1000)
    SyncMachineStates()
    Debug('Resource started: ' .. resourceName)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, machine in pairs(machineObjects) do
        DeleteEntity(machine.object)
    end
    RemoveTargetZones()
    HideAllTextUIs()
    Debug('Resource stopped: ' .. resourceName)
end)

if Framework and Framework.RegisterEvents then
    Framework.RegisterEvents()
    RegisterNetEvent('anox-moneywash:playerLoaded')
    AddEventHandler('anox-moneywash:playerLoaded', function(playerData)
        Wait(1000)
        CreateWashingMachines()
        CreateMachineBlips()
        SetupTargetInteractions()
        SyncMachineStates()
    end)
end