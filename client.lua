local ESX, QBCore = nil, nil
Config.Framework = "ESX" -- ili "QB"

if Config.Framework == "ESX" then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.Framework == "QB" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

-- Marker za rent lokaciju
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        for _, v in pairs(Config.RentLocations) do
            local dist = #(pos - v.coords)
            if dist < 15.0 then
                DrawMarker(1, v.coords.x, v.coords.y, v.coords.z-1.0, 0,0,0,0,0,0,1.5,1.5,0.5, 0,150,255,150, false,true,2)
                if dist < 2.0 then
                    ESX.ShowHelpNotification("Pritisni ~INPUT_CONTEXT~ za rent vozila")
                    if IsControlJustPressed(0,38) then
                        SetNuiFocus(true,true)
                        SendNUIMessage({akcija="otvori", vozila=Config.Vehicles})
                    end
                end
            end
        end
    end
end)

-- Kad se odabere vozilo u UI-u
RegisterNUICallback("rentaj", function(podaci, cb)
    TriggerServerEvent("rent:vozilo", podaci.model, podaci.cijena)
    SetNuiFocus(false,false)
    cb("ok")
end)

-- Zatvaranje UI-a
RegisterNUICallback("zatvori", function(_, cb)
    SetNuiFocus(false,false)
    cb("ok")
end)

-- Spawn vozila
RegisterNetEvent("rent:spawnVozilo", function(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    SetVehicleNumberPlateText(veh, "RENT"..math.random(100,999))
end)

-- Ako igrač uđe u rentano vozilo bez ugovora -> izbaci ga
CreateThread(function()
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local plate = GetVehicleNumberPlateText(veh)
            if string.find(plate, "RENT") then
                local hasItem = exports.ox_inventory:Search('count', 'rental_contract') > 0
                if not hasItem then
                    TaskLeaveVehicle(ped, veh, 0)
                    ESX.ShowNotification("Nemaš ugovor o najmu za ovo vozilo!")
                end
            end
        end
    end
end)

RegisterNetEvent("rent:despawnVozilo", function(model)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh ~= 0 then
        local plate = GetVehicleNumberPlateText(veh)
        if string.find(plate, "RENT") then
            ESX.ShowNotification("Istekao je ugovor za vozilo! Vozilo se uklanja.")
            DeleteVehicle(veh)
        end
    end

    -- Opcionalno: ukloni sva vozila sa mape sa istom oznakom
    for veh in EnumerateVehicles() do
        local plate = GetVehicleNumberPlateText(veh)
        if string.find(plate, "RENT") then
            DeleteVehicle(veh)
        end
    end
end)

-- EnumerateVehicles helper funkcija
function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        local finished = false
        repeat
            coroutine.yield(veh)
            finished, veh = FindNextVehicle(handle)
        until not finished
        EndFindVehicle(handle)
    end)
end
