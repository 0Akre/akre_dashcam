local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('akre_dashcam:getConfigVehicles', function(source, cb)
    local policeVehicles = {}

    for _, vehicle in ipairs(GetAllVehicles()) do
        local model = GetEntityModel(vehicle)
        if IsThisModelAPoliceVehicle(model) then
            table.insert(policeVehicles, {
                plate = GetVehicleNumberPlateText(vehicle),
                netId = NetworkGetNetworkIdFromEntity(vehicle)
            })
        end
    end

    cb(policeVehicles)
end)

function IsThisModelAPoliceVehicle(model)
    local policeModels = {}
    for _, vehicle in ipairs(Config.DashVehicles) do
        table.insert(policeModels, GetHashKey(vehicle))
    end

    for _, policeModel in ipairs(policeModels) do
        if model == policeModel then
            return true
        end
    end

    return false
end

CreateThread(function()
    while true do
        Wait(1000)
        for _, vehicle in ipairs(GetAllVehicles()) do
            local model = GetEntityModel(vehicle)
            if IsThisModelAPoliceVehicle(model) then
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                local sirensOn = IsVehicleSirenOn(vehicle)
                local handbrakeOn = GetVehicleHandbrake(vehicle)

                TriggerClientEvent('akre_dashcam:updateVehicleStatus', -1, {
                    netId = netId,
                    sirensOn = sirensOn,
                    handbrakeOn = handbrakeOn,
                })
            end
        end
    end
end)