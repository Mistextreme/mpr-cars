-----------------------------------------------------------------------------------------------------------------------------------------
-- ESX
-----------------------------------------------------------------------------------------------------------------------------------------
ESX = exports["es_extended"]:getSharedObject()

-----------------------------------------------------------------------------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function getTuningKey(identifier, plate, vname)
    return "customVehicle:" .. identifier .. "veh_" .. (vname or "unknown") .. "placa_" .. plate
end

-- Server-safe nearest vehicle: enumerate all vehicles and find closest to player ped
local function getNearestVehicleForPlayer(source, radius)
    local ped    = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local nearest = nil
    local nearestDist = radius + 1

    local vehicles = GetAllVehicles()
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vcoords = GetEntityCoords(veh)
            local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(vcoords.x, vcoords.y, vcoords.z))
            if dist < nearestDist then
                nearestDist = dist
                nearest = veh
            end
        end
    end
    return nearest
end

-- Check if player has a job matching any entry in a list
local function playerHasJob(xPlayer, jobList)
    local playerJob = xPlayer.getJob().name
    for _, jobName in pairs(jobList) do
        if playerJob == jobName then
            return true
        end
    end
    return false
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION CHECKS
-----------------------------------------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback("mpr-cars:checkPermission", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    if cfg.permissaoParaInstalar.existePermissao then
        if playerHasJob(xPlayer, cfg.permissaoParaInstalar.permissoes) then
            cb(true)
        else
            cb(false)
        end
    else
        cb(true)
    end
end)

ESX.RegisterServerCallback("mpr-cars:checkPermissionShop", function(source, cb, perm)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    if xPlayer.getJob().name == perm then
        cb(true)
    else
        cb(false)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- XENON CALLBACKS & EVENTS
-----------------------------------------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback("mpr-cars:checkXenon", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    local identifier = xPlayer.getIdentifier()
    local veh        = getNearestVehicleForPlayer(source, 5)
    if not veh then cb(false) return end

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname = tostring(GetEntityModel(veh))

    if plate and plate ~= "" then
        if cfg.apenasDonoAcessaXenon then
            local ownerKey = "vehicle_owner:" .. plate
            local ownerId  = GetResourceKvpString(ownerKey)
            if not ownerId or ownerId ~= identifier then
                cb(false)
                return
            end
        end

        local key    = getTuningKey(identifier, plate, vname)
        local raw    = GetResourceKvpString(key)
        local custom = raw and json.decode(raw) or {}
        cb(custom.xenonControl == 1)
    else
        cb(false)
    end
end)

RegisterNetEvent("mpr-cars:installXenon")
AddEventHandler("mpr-cars:installXenon", function(netVehicle)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local item = xPlayer.getInventoryItem("moduloxenon")
    if item and item.count >= 1 then
        TriggerClientEvent("mpr-cars:playAnim", source, true, {{"mini@repair", "fixing_a_ped", 1}})
        TriggerClientEvent("progress", source, 30000, "Instalando módulo de Xenon")

        SetTimeout(31000, function()
            TriggerClientEvent("mpr-cars:stopAnim", source)

            local identifier = xPlayer.getIdentifier()
            local veh        = NetworkGetEntityFromNetworkId(netVehicle)
            if veh and veh ~= 0 then
                local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
                local vname = tostring(GetEntityModel(veh))
                local key   = getTuningKey(identifier, plate, vname)

                SetResourceKvp("vehicle_owner:" .. plate, identifier)

                local raw    = GetResourceKvpString(key)
                local custom = raw and json.decode(raw) or {}
                custom.xenonControl = 1
                SetResourceKvp(key, json.encode(custom))

                xPlayer.removeInventoryItem("moduloxenon", 1)
                TriggerClientEvent("esx:showNotification", source, "Módulo de Xenon instalado com sucesso!")
            end
        end)
    else
        TriggerClientEvent("esx:showNotification", source, "Você não possui um módulo xenon.")
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- NEON CALLBACKS & EVENTS
-----------------------------------------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback("mpr-cars:checkNeon", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    local identifier = xPlayer.getIdentifier()
    local veh        = getNearestVehicleForPlayer(source, 5)
    if not veh then cb(false) return end

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname = tostring(GetEntityModel(veh))

    if plate and plate ~= "" then
        if cfg.apenasDonoAcessaNeon then
            local ownerKey = "vehicle_owner:" .. plate
            local ownerId  = GetResourceKvpString(ownerKey)
            if not ownerId or ownerId ~= identifier then
                cb(false)
                return
            end
        end

        local key    = getTuningKey(identifier, plate, vname)
        local raw    = GetResourceKvpString(key)
        local custom = raw and json.decode(raw) or {}
        cb(custom.neonControl == 1)
    else
        cb(false)
    end
end)

RegisterNetEvent("mpr-cars:installNeon")
AddEventHandler("mpr-cars:installNeon", function(netVehicle)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local item = xPlayer.getInventoryItem("moduloneon")
    if item and item.count >= 1 then
        TriggerClientEvent("mpr-cars:playAnim", source, true, {{"mini@repair", "fixing_a_ped", 1}})
        TriggerClientEvent("progress", source, 30000, "Instalando módulo de neon")

        SetTimeout(31000, function()
            TriggerClientEvent("mpr-cars:stopAnim", source)

            local identifier = xPlayer.getIdentifier()
            local veh        = NetworkGetEntityFromNetworkId(netVehicle)
            if veh and veh ~= 0 then
                local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
                local vname = tostring(GetEntityModel(veh))
                local key   = getTuningKey(identifier, plate, vname)

                SetResourceKvp("vehicle_owner:" .. plate, identifier)

                local raw    = GetResourceKvpString(key)
                local custom = raw and json.decode(raw) or {}
                custom.neonControl = 1
                SetResourceKvp(key, json.encode(custom))

                xPlayer.removeInventoryItem("moduloneon", 1)
                TriggerClientEvent("esx:showNotification", source, "Módulo de Neon instalado com sucesso!")
            end
        end)
    else
        TriggerClientEvent("esx:showNotification", source, "Você não possui um módulo de Neon.")
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SUSPENSION CALLBACKS & EVENTS
-----------------------------------------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback("mpr-cars:checkSuspension", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    local identifier = xPlayer.getIdentifier()
    local veh        = getNearestVehicleForPlayer(source, 5)
    if not veh then cb(false) return end

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname = tostring(GetEntityModel(veh))

    if plate and plate ~= "" then
        if cfg.apenasDonoAcessaSuspensao then
            local ownerKey = "vehicle_owner:" .. plate
            local ownerId  = GetResourceKvpString(ownerKey)
            if not ownerId or ownerId ~= identifier then
                cb(false)
                return
            end
        end

        local key    = getTuningKey(identifier, plate, vname)
        local raw    = GetResourceKvpString(key)
        local custom = raw and json.decode(raw) or {}
        cb(custom.suspensaoAr == 1)
    else
        cb(false)
    end
end)

RegisterNetEvent("mpr-cars:playInstallAnim")
AddEventHandler("mpr-cars:playInstallAnim", function()
    local source = source
    TriggerClientEvent("mpr-cars:playAnim", source, false, {{"anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer"}})
    SetTimeout(7000, function()
        TriggerClientEvent("mpr-cars:stopAnim", source)
        TriggerClientEvent("mpr-cars:setInstalando", source, false)
    end)
end)

RegisterNetEvent("mpr-cars:setSuspensao")
AddEventHandler("mpr-cars:setSuspensao", function(netVehicle)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local item = xPlayer.getInventoryItem("suspensaoar")
    if item and item.count >= 1 then
        local identifier = xPlayer.getIdentifier()
        local veh        = NetworkGetEntityFromNetworkId(netVehicle)
        if veh and veh ~= 0 then
            local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
            local vname = tostring(GetEntityModel(veh))
            local key   = getTuningKey(identifier, plate, vname)

            SetResourceKvp("vehicle_owner:" .. plate, identifier)

            local raw    = GetResourceKvpString(key)
            local custom = raw and json.decode(raw) or {}
            custom.suspensaoAr = 1
            SetResourceKvp(key, json.encode(custom))

            xPlayer.removeInventoryItem("suspensaoar", 1)
        end
    else
        TriggerClientEvent("esx:showNotification", source, "Você não possui um Kit de suspensão a ar.")
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- PRESET CALLBACKS & EVENTS
-----------------------------------------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback("mpr-cars:returnPreset", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(0) return end

    local identifier = xPlayer.getIdentifier()
    local veh        = getNearestVehicleForPlayer(source, 5)
    if not veh then cb(0) return end

    local plate  = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname  = tostring(GetEntityModel(veh))
    local key    = getTuningKey(identifier, plate, vname)
    local raw    = GetResourceKvpString(key)
    local custom = raw and json.decode(raw) or {}

    if custom.presetSuspe ~= nil then
        cb(custom.presetSuspe)
    else
        cb(0)
    end
end)

RegisterNetEvent("mpr-cars:setPreset")
AddEventHandler("mpr-cars:setPreset", function(value)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local veh        = getNearestVehicleForPlayer(source, 5)
    if not veh then return end

    local plate  = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname  = tostring(GetEntityModel(veh))
    local key    = getTuningKey(identifier, plate, vname)
    local raw    = GetResourceKvpString(key)
    local custom = raw and json.decode(raw) or {}

    custom.presetSuspe = value
    SetResourceKvp(key, json.encode(custom))
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SUSPENSION SYNC
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:tryzosuspe")
AddEventHandler("mpr-cars:tryzosuspe", function(vehicle, pAlturaAtual, pAlturaAnterior, variacao, typeDir)
    local altura = pAlturaAnterior
    if typeDir == "subir" then
        while altura > pAlturaAtual do
            altura = altura - variacao
            TriggerClientEvent("mpr-cars:synczosuspe", -1, vehicle, altura)
            Citizen.Wait(1)
        end
    elseif typeDir == "descer" then
        while altura < pAlturaAtual do
            altura = altura + variacao
            TriggerClientEvent("mpr-cars:synczosuspe", -1, vehicle, altura)
            Citizen.Wait(1)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SHOP PURCHASE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:comprar")
AddEventHandler("mpr-cars:comprar", function(item)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    for _, v in pairs(cfg.valores) do
        if item == v.item then
            local preco     = tonumber(v.compra)
            local quantidade = tonumber(v.quantidade)

            if xPlayer.getMoney() >= preco then
                xPlayer.removeMoney(preco)
                xPlayer.addInventoryItem(v.item, quantidade)
                TriggerClientEvent("esx:showNotification", source,
                    "Comprou ~g~" .. quantidade .. "x " .. v.item .. "~s~ por ~r~$" .. preco .. "~s~.")
            else
                TriggerClientEvent("esx:showNotification", source, "Dinheiro insuficiente.")
            end
            return
        end
    end
end)