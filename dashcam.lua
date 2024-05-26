local QBCore = exports['qb-core']:GetCoreObject()
local isWatchingDashcam = false
local dashcamCam = nil
local dashcamPosition = Config.WatchCoords

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

RegisterNUICallback('viewCamera', function(data, cb)
    local vehicleNetId = data.netId
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)

    if DoesEntityExist(vehicle) then
        local playerPed = PlayerPedId()
        FreezePlayer(playerPed, true)
        SendNUIMessage({ action = 'preloading' })
        Wait(3000)
        SendNUIMessage({ action = 'hidePreloading' })

        dashcamCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        AttachCamToEntity(dashcamCam, vehicle, 0.0, .7, 0.5, true)
        SetCamRot(dashcamCam, 0.0, 0.0, GetEntityHeading(vehicle))
        SetCamActive(dashcamCam, true)
        RenderScriptCams(true, false, 0, true, true)
        isWatchingDashcam = true

        SendNUIMessage({
            action = 'showStatus'
        })

        SendNUIMessage({
            action = 'showVehicleInfo',
            plate = GetVehicleNumberPlateText(vehicle),
            code = generateRandomCode()
        })

        CreateThread(function()
            while isWatchingDashcam do
                Wait(11)
                if DoesEntityExist(vehicle) then
                    local sirensOn = IsVehicleSirenOn(vehicle)
                    local handbrakeOn = GetVehicleHandbrake(vehicle)

                    SendNUIMessage({
                        action = 'updateStatus',
                        sirens = sirensOn,
                        handbrake = handbrakeOn,
                    })

                    local vehicleCoords = GetEntityCoords(vehicle)
                    local vehicleRot = GetEntityRotation(vehicle, 2)
                    SetCamCoord(dashcamCam, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.0)
                    SetCamRot(dashcamCam, vehicleRot.x, vehicleRot.y, vehicleRot.z)
                else
                    RenderScriptCams(false, false, 0, true, true)
                    DestroyCam(dashcamCam, false)
                    dashcamCam = nil
                    isWatchingDashcam = false
                    SendNUIMessage({ action = 'hideStatus' })
                    SendNUIMessage({ action = 'hideVehicleInfo' })
                    UnfreezePlayer(playerPed)
                end
            end
        end)
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