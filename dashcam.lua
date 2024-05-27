local QBCore = exports['qb-core']:GetCoreObject()
local isWatchingDashcam = false
local dashcamCam = nil
local dashcamPosition = Config.WatchCoords
local maxDistance = 5000.0
local attachedVehicle = nil

CreateThread(function()
    exports['qb-target']:AddBoxZone("dashcam", dashcamPosition, 1.0, 1.0, {
        name = "dashcam",
        heading = 0,
        debugPoly = false,
        minZ = 29.7,
        maxZ = 31.7,
    }, {
        options = {
            {
                type = "client",
                event = "akre_dashcam:Permission",
                icon = "fas fa-camera",
                label = "Show Dashcams",
            },
        },
        distance = 2.0
    })
end)

function hasPermission()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.job and PlayerData.job.name == Config.WatchJobs and PlayerData.job.grade.level >= Config.JobGrade then
        return true
    end
    return false
end

function openDashcamMenu()
    QBCore.Functions.TriggerCallback('akre_dashcam:getConfigVehicles', function(policeVehicles)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openMenu',
            vehicles = policeVehicles
        })
    end)
end

RegisterNetEvent('akre_dashcam:Permission')
AddEventHandler('akre_dashcam:Permission', function()
    if hasPermission() then
        TriggerEvent('akre_dashcam:openMenu')
    else
        QBCore.Functions.Notify('You do not have permission to access the dashcam menu.', 'error')
    end
end)

RegisterNetEvent('akre_dashcam:openMenu')
AddEventHandler('akre_dashcam:openMenu', function()
    openDashcamMenu()
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    if not isWatchingDashcam then
        SendNUIMessage({
            action = 'hideStatus'
        })
    end
    cb('ok')
end)

function RequestVehicleControl(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        NetworkRequestControlOfNetworkId(vehicleNetId)
        local timeout = 2000
        while not NetworkHasControlOfNetworkId(vehicleNetId) and timeout > 0 do
            Wait(100)
            timeout = timeout - 100
        end
        vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    end
    return vehicle
end

function EnsureVehicleStreaming(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        RequestVehicleControl(vehicleNetId)
        vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    end

    if DoesEntityExist(vehicle) then
        local model = GetEntityModel(vehicle)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(100)
        end
        SetEntityCoords(vehicle, GetEntityCoords(vehicle))
    end

    return vehicle
end

RegisterNUICallback('viewCamera', function(data, cb)
    local vehicleNetId = data.netId
    attachedVehicle = EnsureVehicleStreaming(vehicleNetId)

    if DoesEntityExist(attachedVehicle) then
        local playerPed = PlayerPedId()
        FreezePlayer(playerPed, true)
        SendNUIMessage({ action = 'preloading' })
        Wait(3000)
        SendNUIMessage({ action = 'hidePreloading' })

        dashcamCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        AttachCamToEntity(dashcamCam, attachedVehicle, 0.0, 0.5, 1.0, true)
        SetCamRot(dashcamCam, 0.0, 0.0, GetEntityHeading(attachedVehicle))
        SetCamActive(dashcamCam, true)
        RenderScriptCams(true, false, 0, true, true)
        SetFocusEntity(attachedVehicle)
        isWatchingDashcam = true

        SendNUIMessage({
            action = 'showStatus'
        })

        SendNUIMessage({
            action = 'showVehicleInfo',
            plate = GetVehicleNumberPlateText(attachedVehicle),
            code = generateRandomCode()
        })

        CreateThread(function()
            while isWatchingDashcam do
                Wait(11)
                if DoesEntityExist(attachedVehicle) then
                    local sirensOn = IsVehicleSirenOn(attachedVehicle)
                    local handbrakeOn = GetVehicleHandbrake(attachedVehicle)

                    SendNUIMessage({
                        action = 'updateStatus',
                        sirens = sirensOn,
                        handbrake = handbrakeOn,
                    })

                    local vehicleCoords = GetEntityCoords(attachedVehicle)
                    local vehicleRot = GetEntityRotation(attachedVehicle, 2)
                    SetCamCoord(dashcamCam, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.0)
                    SetCamRot(dashcamCam, vehicleRot.x, vehicleRot.y, vehicleRot.z)
                    RequestCollisionAtCoord(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
                else
                    RenderScriptCams(false, false, 0, true, true)
                    DestroyCam(dashcamCam, false)
                    dashcamCam = nil
                    isWatchingDashcam = false
                    SetFocusEntity(playerPed)
                    SendNUIMessage({ action = 'hideStatus' })
                    SendNUIMessage({ action = 'hideVehicleInfo' })
                    UnfreezePlayer(playerPed)
                end
            end
        end)
    else
        QBCore.Functions.Notify('Unable to load vehicle for dashcam.', 'error')
    end

    cb('ok')
end)

RegisterNetEvent('akre_dashcam:updateVehicleStatus')
AddEventHandler('akre_dashcam:updateVehicleStatus', function(data)
    if isWatchingDashcam then
        local vehicle = NetworkGetEntityFromNetworkId(data.netId)
        if DoesEntityExist(vehicle) then
            SendNUIMessage({
                action = 'updateStatus',
                sirens = data.sirensOn,
                handbrake = data.handbrakeOn,
            })
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isWatchingDashcam then
            if IsControlJustPressed(0, 25) then
                local playerPed = PlayerPedId()
                SendNUIMessage({ action = 'disconnecting' })
                Wait(1000)
                SendNUIMessage({ action = 'hideDisconnecting' })

                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(dashcamCam, false)
                dashcamCam = nil
                isWatchingDashcam = false
                SetFocusEntity(playerPed)
                SendNUIMessage({ action = 'hideStatus' })
                SendNUIMessage({ action = 'hideVehicleInfo' })
                UnfreezePlayer(playerPed)
            end
        end
    end
end)

function generateRandomCode()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local code = ''
    local usedChars = {}
    while string.len(code) < 6 do
        local rand = math.random(1, #chars)
        local char = string.sub(chars, rand, rand)
        if not usedChars[char] then
            code = code .. char
            usedChars[char] = true
        end
    end
    return code
end

function FreezePlayer(player, toggle)
    FreezeEntityPosition(player, toggle)
    SetPlayerInvincible(player, toggle)
    SetEntityCollision(player, not toggle, not toggle)
    if toggle then
        ClearPedTasksImmediately(player)
    end
end

function UnfreezePlayer(player)
    FreezeEntityPosition(player, false)
    SetPlayerInvincible(player, false)
    SetEntityCollision(player, true, true)
end