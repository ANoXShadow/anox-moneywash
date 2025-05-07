local Bridge = {}
local isClient = IsDuplicityVersion() == false

local function Debug(msg)
    if Config.Debug then
        print('^3[anox-moneywash]^7 ' .. msg)
    end
end 

function Bridge.Load()
    local framework = Config.Framework:lower()    
    local supportedFrameworks = {
        esx = true,
        qb = true,
        qbx = true,
    }
    if not supportedFrameworks[framework] then
        Debug('^1Unsupported framework: ' .. framework)
        return nil
    end
    local bridgePath = isClient and 'bridge/client/' .. framework or 'bridge/server/' .. framework
    local bridgeModule = LoadResourceFile(GetCurrentResourceName(), bridgePath .. '.lua')
    if bridgeModule then
        local bridge = load(bridgeModule)()
        if bridge and bridge.Init and bridge.Init() then
            Debug('^2Successfully loaded ' .. framework .. ' bridge for ' .. (isClient and 'client' or 'server'))
            if bridge.RegisterEvents then
                bridge.RegisterEvents()
            end
            return bridge
        else
            Debug('^1Failed to initialize ' .. framework .. ' bridge for ' .. (isClient and 'client' or 'server'))
            return nil
        end
    else
        Debug('^1Failed to load ' .. framework .. ' bridge for ' .. (isClient and 'client' or 'server'))
        return nil
    end
end

local UIPresets = {
    notify = {
        success = {
            backgroundColor = '#0f0f0f',
            color = '#4ADE80',
            position = 'center-right',
            duration = 5000
        },
        error = {
            backgroundColor = '#3b0a0a',
            color = '#F87171',
            position = 'center-right',
            duration = 5000
        },
        info = {
            backgroundColor = '#0f0f0f',
            color = '#60A5FA',
            position = 'center-right',
            duration = 5000
        },
        warning = {
            backgroundColor = '#3b0a0a',
            color = '#FACC15',
            position = 'center-right',
            duration = 5000
        }               
    },
    progressBar = {
        cardInsert = {
            duration = 2000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'mp_common',
                clip = 'givetake1_a',
                flag = 49
            }
        },
        collectMoney = {
            duration = 3000,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'mp_common',
                clip = 'givetake1_a',
                flag = 49
            },
            prop = {
                model = `prop_anim_cash_pile_02`,
                bone = 28422,
                pos = vec3(0, 0, 0),
                rot = vec3(0, 0, 0)
            }
        }
    },
    alertDialog = {
        default = {
            size = 'md',
            centered = true,
            cancel = true,
            confirmLabel = "Confirm",
            cancelLabel = "Cancel"
        },
        moneyWash = {
            size = 'md',
            centered = true,
            cancel = true,
            confirmLabel = "Proceed",
            cancelLabel = "Cancel"
        }
    },
    inputDialog = {
        default = {
            allowCancel = true
        },
        moneyAmount = {
            allowCancel = true,
            rows = {
                type = 'number',
                label = 'Amount to Wash',
                icon = 'dollar-sign',
                required = true,
                min = 1000,
                default = 1000
            }
        }
    },
    textUI = {
        default = {
            backgroundColor = '#000000',
            color = '#FFD700',
            icon = 'info',
            position = 'top-center'
        },
        cooldown = {
            backgroundColor = '#000000',
            color = '#FACC15',
            icon = 'clock',
            position = 'top-center'
        },
        processing = {
            backgroundColor = '#000000',
            color = '#60A5FA',
            icon = 'spinner',
            position = 'top-center'
        },
        moneyReady = {
            backgroundColor = '#000000',
            color = '#4ADE80',
            icon = 'money-bill-wave',
            position = 'top-center'
        }
        
    }
}

Bridge.Notify = function(message, style, title)
    if IsDuplicityVersion() then
        local notifyStyle = style and UIPresets.notify[style] or UIPresets.notify.info
        TriggerClientEvent('ox_lib:notify', source, {
            title = title or 'Notification',
            description = message,
            type = style or 'info',
            style = {
                backgroundColor = '#000000',       -- notifyStyle.backgroundColor, (for diff background from presets)
                color = '#FFD700',
                borderRadius = 14,
                fontSize = '16px',
                fontWeight = 'bold',
                textAlign = 'left',
                padding = '14px 20px',
                border = '1px solid #FFD700',
                letterSpacing = '0.5px',
            },
            position = notifyStyle.position,
            duration = notifyStyle.duration
        })
    else
    if Config.UISystem.Notify == 'ox' then
        local notifyStyle = style and UIPresets.notify[style] or UIPresets.notify.info
        lib.notify({
            title = title,
            description = message, 
            style = {
                backgroundColor = '#000000',       -- notifyStyle.backgroundColor, (for diff background from presets)
                color = '#FFD700',
                borderRadius = 14,
                fontSize = '16px',
                fontWeight = 'bold',
                textAlign = 'left',
                padding = '14px 20px',
                border = '1px solid #FFD700',
                letterSpacing = '0.5px',
            },            
            position = notifyStyle.position,
            duration = notifyStyle.duration
        })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
        end
    end
end

Bridge.ProgressBar = function(label, duration, style)
    if Config.UISystem.ProgressBar == 'ox' then
        local progressStyle = style and UIPresets.progressBar[style] or UIPresets.progressBar.default
        local progressOptions = {
            duration = duration or progressStyle.duration or 5000,
            label = label,
            position = progressStyle.position,
            useWhileDead = progressStyle.useWhileDead,
            canCancel = progressStyle.canCancel,
            disable = progressStyle.disable,
            anim = progressStyle.anim
        }
        if progressStyle.prop then
            progressOptions.prop = progressStyle.prop
        end
        return lib.progressBar(progressOptions)
    else
        Citizen.Wait(duration or 5000)
        return true
    end
end

Bridge.AlertDialog = function(title, message, style)
    if Config.UISystem.AlertDialog == 'ox' then
        local dialogStyle = style and UIPresets.alertDialog[style] or UIPresets.alertDialog.default
        return lib.alertDialog({
            header = title,
            content = message,
            size = dialogStyle.size,
            centered = dialogStyle.centered,
            cancel = dialogStyle.cancel,
            labels = {
                confirm = dialogStyle.confirmLabel,
                cancel = dialogStyle.cancelLabel
            }
        })
    else
        Bridge.Notify(message, 'info')
        return 'confirm'
    end
end

Bridge.InputDialog = function(title, style)
    if Config.UISystem.InputDialog == 'ox' then
        local inputStyle = style and UIPresets.inputDialog[style] or UIPresets.inputDialog.default
        local rows = inputStyle.rows or {}
        if style == 'moneyAmount' then
            rows = {
                {
                    type = 'number',
                    label = rows.label or 'Amount to Wash',
                    icon = rows.icon or 'dollar-sign',
                    required = rows.required ~= nil and rows.required or true,
                    min = rows.min or 1000,
                    default = rows.default or 1000
                }
            }
        end
        return lib.inputDialog(title, rows, { 
            allowCancel = inputStyle.allowCancel 
        })
    else
        Bridge.Notify('Input dialog not supported', 'error')
        return false
    end
end

Bridge.ShowTextUI = function(message, style)
    if Config.UISystem.TextUI == 'ox' then
        local textUIStyle = style and UIPresets.textUI[style] or UIPresets.textUI.default
        lib.showTextUI(message, {
            position = textUIStyle.position,
            icon = textUIStyle.icon,
            style = {
                borderRadius = 6,
                backgroundColor = '#000000',
                color = '#FFD700',
                border = '1px solid #FFD700',
                fontSize = '15px',
                fontWeight = '600',
                padding = '6px 12px',
                letterSpacing = '0.5px',
            }
        })
    else
        Bridge.Notify(message)
    end
end

Bridge.HideTextUI = function()
    if Config.UISystem.TextUI == 'ox' then
        lib.hideTextUI()
    end
end

Bridge.Target = {
    AddBoxZone = function(options)
        if Config.Target == 'ox' then
            return exports.ox_target:addBoxZone({
                coords = options.coords,
                size = options.size or vec3(1.5, 1.5, 2.0),
                rotation = options.rotation or 0,
                debug = options.debug or false,
                options = options.options
            })
        elseif Config.Target == 'qb' then
            local qbOptions = {}
            for _, opt in ipairs(options.options) do
                table.insert(qbOptions, {
                    type = opt.type or 'client',
                    event = opt.event,
                    icon = opt.icon,
                    label = opt.label,
                    canInteract = opt.canInteract,
                    job = opt.job,
                    action = opt.onSelect and function()
                        opt.onSelect()
                    end
                })
            end
            exports['qb-target']:AddBoxZone(options.name or 'custom_zone', options.coords, options.size.x, options.size.y, {
                name = options.name or 'custom_zone',
                heading = options.rotation or 0,
                debugPoly = options.debug or false,
                minZ = options.coords.z - 1.0,
                maxZ = options.coords.z + 1.0
            }, {
                options = qbOptions,
                distance = options.distance or 2.0
            })
        else
            error('Unsupported target system: ' .. tostring(Config.Target))
        end
    end,
    RemoveZone = function(zoneId)
        if Config.Target == 'ox' then
            exports.ox_target:removeZone(zoneId)
        elseif Config.Target == 'qb' then
            exports['qb-target']:RemoveZone(zoneId)
        else
            error('Unsupported target system: ' .. tostring(Config.Target))
        end
    end,
    AddLocalEntity = function(entity, options)
        if Config.Target == 'ox' then
            exports.ox_target:addLocalEntity(entity, options)
        elseif Config.Target == 'qb' then
            local qbOptions = {}
            for _, opt in ipairs(options) do
                table.insert(qbOptions, {
                    type = opt.type or 'client',
                    event = opt.event,
                    icon = opt.icon,
                    label = opt.label,
                    canInteract = opt.canInteract,
                    job = opt.job,
                    action = opt.onSelect and function()
                        opt.onSelect()
                    end
                })
            end
            exports['qb-target']:AddTargetEntity(entity, {
                options = qbOptions,
                distance = 2.0
            })
        else
            error('Unsupported target system: ' .. tostring(Config.Target))
        end
    end,
    RemoveLocalEntity = function(entity)
        if Config.Target == 'ox' then
            exports.ox_target:removeLocalEntity(entity)
        elseif Config.Target == 'qb' then
            exports['qb-target']:RemoveTargetEntity(entity)
        else
            error('Unsupported target system: ' .. tostring(Config.Target))
        end
    end
}

return Bridge