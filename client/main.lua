local bodycamEnabled = false
local editMode = false
local currentPayload = nil
local kvpKey = 'bg_bodycam:ui_position'

local function cloneTable(source)
    if type(source) ~= 'table' then return source end
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = cloneTable(value)
    end
    return copy
end

local function safeEncode(data)
    local ok, encoded = pcall(json.encode, data)
    if ok then return encoded end
    return '{}'
end

local function safeDecode(data)
    if not data or data == '' then return nil end
    local ok, decoded = pcall(json.decode, data)
    if ok then return decoded end
    return nil
end

local function getSavedPosition()
    return safeDecode(GetResourceKvpString(kvpKey)) or cloneTable(Config.UI.defaultPosition)
end

local function savePosition(position)
    if type(position) ~= 'table' then return end
    SetResourceKvp(kvpKey, safeEncode(position))
end

local function resetPosition()
    DeleteResourceKvp(kvpKey)
    SendNUIMessage({ action = 'resetPosition', position = Config.UI.defaultPosition })
    BGFramework.Notify(Config.Text.resetPosition, 'success')
end

local function playToggleAnimation()
    if not Config.Animation.enabled then return end

    local ped = PlayerPedId()
    local dict = Config.Animation.dict
    local clip = Config.Animation.clip

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end

    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, clip, 8.0, -8.0, Config.Animation.duration, Config.Animation.flag, 0.0, false, false, false)
        Wait(Config.Animation.duration)
        StopAnimTask(ped, dict, clip, 1.0)
    end
end

local function playSound(state)
    if not Config.Sounds.enabled then return end

    local sound = Config.Sounds[state]
    if not sound then return end

    PlaySoundFrontend(-1, sound.name, sound.set, true)
end

local function getJobConfig(playerInfo)
    local jobName = playerInfo.jobName or 'unemployed'
    local jobConfig = Config.Jobs[jobName]

    if not jobConfig then
        if not Config.AllowUnconfiguredJobs then
            return nil, 'not_allowed'
        end
        jobConfig = Config.DefaultJob
    end

    if jobConfig.minGrade and playerInfo.gradeLevel < jobConfig.minGrade then
        return nil, 'not_allowed'
    end

    if Config.RequireDutyWhenConfigured and jobConfig.requireDuty and playerInfo.onDuty == false then
        return nil, 'not_duty'
    end

    return jobConfig, nil
end

local function buildPayload()
    local playerInfo = BGFramework.GetPlayerInfo()
    local jobConfig = getJobConfig(playerInfo) or Config.DefaultJob

    return {
        visible = bodycamEnabled,
        title = Config.UI.title,
        model = Config.UI.model,
        showLogo = Config.UI.showLogo,
        showRecordingDot = Config.UI.showRecordingDot,
        scale = Config.UI.scale,
        position = getSavedPosition(),
        time = Config.Time,
        player = {
            name = playerInfo.fullName,
            jobName = playerInfo.jobName,
            jobLabel = jobConfig.uiJobLabel or playerInfo.jobLabel,
            gradeLabel = playerInfo.gradeLabel,
            department = jobConfig.department or Config.DefaultJob.department,
            logo = jobConfig.logo or Config.DefaultJob.logo
        }
    }
end

local function sendUiUpdate(action)
    currentPayload = buildPayload()
    currentPayload.action = action or 'update'
    SendNUIMessage(currentPayload)
end

local function setBodycamState(state, skipAnimation)
    if bodycamEnabled == state then return end

    if not skipAnimation then
        playToggleAnimation()
    end

    bodycamEnabled = state

    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('bodycamActive', bodycamEnabled, true)
    end

    if bodycamEnabled then
        sendUiUpdate('show')
        playSound('on')
        BGFramework.Notify(Config.Text.bodycamOn, 'success')
    else
        SendNUIMessage({ action = 'hide' })
        playSound('off')
        BGFramework.Notify(Config.Text.bodycamOff, 'inform')
        if editMode then
            editMode = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'editMode', enabled = false })
        end
    end
end

local function toggleBodycam()
    local playerInfo = BGFramework.GetPlayerInfo()
    local _, reason = getJobConfig(playerInfo)

    if not bodycamEnabled and reason then
        if reason == 'not_duty' then
            BGFramework.Notify(Config.Text.notOnDuty, 'error')
        else
            BGFramework.Notify(Config.Text.noPermission, 'error')
        end
        return
    end

    setBodycamState(not bodycamEnabled)
end

local function setEditMode(state)
    if state and not bodycamEnabled then
        BGFramework.Notify('Accendi prima la bodycam per modificare la UI.', 'error')
        return
    end

    editMode = state
    SetNuiFocus(editMode, editMode)
    SendNUIMessage({ action = 'editMode', enabled = editMode })

    if editMode then
        BGFramework.Notify(Config.Text.editEnabled, 'inform')
    else
        BGFramework.Notify(Config.Text.editDisabled, 'inform')
    end
end

exports('useBodycam', function(data, slot)
    toggleBodycam()
end)

exports('toggleBodycam', toggleBodycam)
exports('isBodycamEnabled', function()
    return bodycamEnabled
end)

RegisterNetEvent('bg_bodycam:client:toggle', toggleBodycam)
RegisterNetEvent('bg_bodycam:client:forceOff', function()
    if bodycamEnabled then
        setBodycamState(false, true)
    end
end)

RegisterNetEvent('bg_bodycam:client:playerDataChanged', function()
    if not bodycamEnabled then return end

    local playerInfo = BGFramework.GetPlayerInfo()
    local _, reason = getJobConfig(playerInfo)
    if reason then
        setBodycamState(false, true)
        return
    end

    sendUiUpdate('update')
end)

RegisterCommand(Config.Commands.edit, function()
    setEditMode(not editMode)
end, false)

RegisterCommand(Config.Commands.reset, function()
    resetPosition()
end, false)

RegisterCommand(Config.Commands.debug, function()
    local info = BGFramework.GetPlayerInfo()
    print('[bg_bodycam] Player info: ' .. safeEncode(info))
    BGFramework.Notify('Dati bodycam stampati in console F8.', 'inform')
end, false)

if Config.Keybinds.enableEditKeybind then
    RegisterKeyMapping(Config.Commands.edit, Config.Keybinds.editDescription, 'keyboard', Config.Keybinds.editDefaultKey)
end

RegisterNUICallback('savePosition', function(data, cb)
    if data and data.position then
        savePosition(data.position)
    end
    cb({ ok = true })
end)

RegisterNUICallback('closeEdit', function(_, cb)
    if editMode then
        setEditMode(false)
    end
    cb({ ok = true })
end)

RegisterNUICallback('ready', function(_, cb)
    SendNUIMessage({ action = 'hydrate', position = getSavedPosition(), time = Config.Time })
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if bodycamEnabled then
            Wait(5000)
            sendUiUpdate('update')
        else
            Wait(1500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('bodycamActive', false, true)
    end
    SetNuiFocus(false, false)
end)
