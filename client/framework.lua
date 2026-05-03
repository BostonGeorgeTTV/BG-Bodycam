BGFramework = {
    name = 'standalone',
    ready = false,
    playerData = {}
}

local ESX = nil
local QBCore = nil

local function isStarted(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

local function safeCall(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function trim(value)
    value = tostring(value or '')
    return value:gsub('^%s+', ''):gsub('%s+$', '')
end

local function firstNonEmpty(...)
    local values = { ... }
    for i = 1, #values do
        local value = values[i]
        if value ~= nil and value ~= '' then
            return value
        end
    end
    return nil
end

local function detectFramework()
    local configured = string.lower(Config.Framework or 'auto')
    if configured ~= 'auto' then
        return configured
    end

    if isStarted('qbx_core') then return 'qbox' end
    if isStarted('qb-core') then return 'qbcore' end
    if isStarted('es_extended') then return 'esx' end

    return 'standalone'
end

local function getQboxPlayerData()
    local data = nil

    if isStarted('qbx_core') then
        data = safeCall(function()
            return exports.qbx_core:GetPlayerData()
        end)
    end

    if not data and type(QBX) == 'table' and type(QBX.PlayerData) == 'table' then
        data = QBX.PlayerData
    end

    return data
end

local function getQBCoreObject()
    if QBCore then return QBCore end

    if isStarted('qb-core') then
        QBCore = safeCall(function()
            return exports['qb-core']:GetCoreObject()
        end)
    end

    return QBCore
end

local function getQBCorePlayerData()
    local core = getQBCoreObject()
    if core and core.Functions and core.Functions.GetPlayerData then
        return core.Functions.GetPlayerData()
    end

    if isStarted('qb-core') then
        return safeCall(function()
            return exports['qb-core']:GetPlayerData()
        end)
    end

    return nil
end

local function getESXObject()
    if ESX then return ESX end

    if isStarted('es_extended') then
        ESX = safeCall(function()
            return exports['es_extended']:getSharedObject()
        end)
    end

    return ESX
end

local function getESXPlayerData()
    local core = getESXObject()
    if core and core.GetPlayerData then
        return core.GetPlayerData()
    end

    if core and type(core.PlayerData) == 'table' then
        return core.PlayerData
    end

    return nil
end

local function normalizeJob(job)
    job = job or {}
    local grade = job.grade
    local gradeLabel = nil
    local gradeLevel = 0

    if type(grade) == 'table' then
        gradeLabel = firstNonEmpty(grade.label, grade.name, grade.grade_label)
        gradeLevel = tonumber(firstNonEmpty(grade.level, grade.grade, grade.id, 0)) or 0
    else
        gradeLevel = tonumber(grade or job.gradeLevel or job.grade_level or 0) or 0
    end

    gradeLabel = firstNonEmpty(
        job.grade_label,
        job.gradeLabel,
        job.grade_name,
        gradeLabel,
        gradeLevel
    )

    return {
        name = firstNonEmpty(job.name, 'unemployed'),
        label = firstNonEmpty(job.label, job.name, 'Unemployed'),
        gradeLabel = tostring(gradeLabel or 'N/D'),
        gradeLevel = gradeLevel,
        onDuty = job.onduty,
        raw = job
    }
end

local function normalizePlayerData(frameworkName, data)
    data = data or {}

    local charinfo = data.charinfo or data.charInfo or {}
    local firstName = firstNonEmpty(data.firstName, data.firstname, charinfo.firstname, charinfo.firstName)
    local lastName = firstNonEmpty(data.lastName, data.lastname, charinfo.lastname, charinfo.lastName)
    local fullName = trim((firstName or '') .. ' ' .. (lastName or ''))

    if fullName == '' then
        fullName = firstNonEmpty(data.name, GetPlayerName(PlayerId()), 'Sconosciuto')
    end

    local job = normalizeJob(data.job)

    return {
        framework = frameworkName,
        firstName = firstName or '',
        lastName = lastName or '',
        fullName = fullName,
        jobName = string.lower(tostring(job.name or 'unemployed')),
        jobLabel = tostring(job.label or job.name or 'Unemployed'),
        gradeLabel = tostring(job.gradeLabel or 'N/D'),
        gradeLevel = tonumber(job.gradeLevel or 0) or 0,
        onDuty = job.onDuty,
        rawJob = job.raw,
        raw = data
    }
end

function BGFramework.Init()
    BGFramework.name = detectFramework()

    if BGFramework.name == 'esx' then
        getESXObject()
    elseif BGFramework.name == 'qbcore' then
        getQBCoreObject()
    end

    BGFramework.ready = true
    BGFramework.Refresh()
    print(('[bg_bodycam] Framework rilevato: %s'):format(BGFramework.name))
end

function BGFramework.Refresh()
    local data = nil

    if BGFramework.name == 'esx' then
        data = getESXPlayerData()
    elseif BGFramework.name == 'qbcore' then
        data = getQBCorePlayerData()
    elseif BGFramework.name == 'qbox' then
        data = getQboxPlayerData() or getQBCorePlayerData()
    end

    BGFramework.playerData = normalizePlayerData(BGFramework.name, data)
    return BGFramework.playerData
end

function BGFramework.GetPlayerInfo()
    return BGFramework.Refresh()
end

function BGFramework.Notify(message, notifyType)
    notifyType = notifyType or 'inform'
    local provider = string.lower(Config.Notifications.provider or 'auto')
    local duration = Config.Notifications.duration or 3500

    if (provider == 'auto' or provider == 'ox') and type(lib) == 'table' and lib.notify then
        lib.notify({ description = message, type = notifyType, duration = duration })
        return
    end

    if (provider == 'auto' or provider == 'qbox') and isStarted('qbx_core') then
        local notified = safeCall(function()
            exports.qbx_core:Notify(message, notifyType, duration)
            return true
        end)
        if notified then return end
    end

    if (provider == 'auto' or provider == 'qbcore') then
        local core = getQBCoreObject()
        if core and core.Functions and core.Functions.Notify then
            core.Functions.Notify(message, notifyType, duration)
            return
        end
        TriggerEvent('QBCore:Notify', message, notifyType, duration)
        if provider == 'qbcore' then return end
    end

    if (provider == 'auto' or provider == 'esx') then
        local core = getESXObject()
        if core and core.ShowNotification then
            core.ShowNotification(message)
            return
        end
        TriggerEvent('esx:showNotification', message)
        if provider == 'esx' then return end
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

CreateThread(function()
    Wait(500)
    BGFramework.Init()
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if BGFramework.name == 'esx' then
        BGFramework.playerData = normalizePlayerData('esx', xPlayer)
        TriggerEvent('bg_bodycam:client:playerDataChanged')
    end
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    if BGFramework.name == 'esx' then
        BGFramework.playerData = normalizePlayerData('esx', {})
        TriggerEvent('bg_bodycam:client:forceOff')
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if BGFramework.name == 'esx' then
        BGFramework.playerData.raw.job = job
        TriggerEvent('bg_bodycam:client:playerDataChanged')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if BGFramework.name == 'qbcore' or BGFramework.name == 'qbox' then
        BGFramework.Refresh()
        TriggerEvent('bg_bodycam:client:playerDataChanged')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if BGFramework.name == 'qbcore' or BGFramework.name == 'qbox' then
        BGFramework.playerData = normalizePlayerData(BGFramework.name, {})
        TriggerEvent('bg_bodycam:client:forceOff')
    end
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if BGFramework.name == 'qbox' then
        BGFramework.playerData = normalizePlayerData('qbox', {})
        TriggerEvent('bg_bodycam:client:forceOff')
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if BGFramework.name == 'qbcore' or BGFramework.name == 'qbox' then
        BGFramework.playerData.raw.job = job
        TriggerEvent('bg_bodycam:client:playerDataChanged')
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if BGFramework.name == 'qbcore' or BGFramework.name == 'qbox' then
        BGFramework.playerData = normalizePlayerData(BGFramework.name, data)
        TriggerEvent('bg_bodycam:client:playerDataChanged')
    end
end)
