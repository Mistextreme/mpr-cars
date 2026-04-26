-----------------------------------------------------------------------------------------------------------------------------------------
-- ESX
-----------------------------------------------------------------------------------------------------------------------------------------
ESX = exports["es_extended"]:getSharedObject()

-----------------------------------------------------------------------------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function getVehicleData(source)
    -- Returns: plate, vname via ESX player's vehicle state
    -- We store tuning under xPlayer identifier + plate key
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil, nil end
    return xPlayer
end

local function getTuningKey(identifier, plate, vname)
    return "customVehicle:" .. identifier .. "veh_" .. (vname or "unknown") .. "placa_" .. plate
end

local function getPlateFromNetVehicle(netId)
    -- Attempt to get plate from networked vehicle entity
    if NetworkDoesEntityExistWithNetworkId(netId) then
        local veh = NetToVeh(netId)
        if veh and veh ~= 0 then
            return string.gsub(GetVehicleNumberPlateText(veh), "%s+", ""),
                   GetEntityModel(veh)
        end
    end
    return nil, nil
end

local function getNearestVehicleForPlayer(source, radius)
    -- Get coords from player ped via native
    local ped    = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local nearby = GetClosestVehicle(coords.x, coords.y, coords.z, radius, 0, 70)
    if nearby and nearby ~= 0 then
        return nearby
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION CHECKS
-----------------------------------------------------------------------------------------------------------------------------------------
ESX.RegisterServerCallback("mpr-cars:checkPermission", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    if cfg.permissaoParaInstalar.existePermissao then
        for _, group in pairs(cfg.permissaoParaInstalar.permissoes) do
            if xPlayer.getGroup() == group or xPlayer.hasGroup(group) then
                cb(true)
                return
            end
        end
        cb(false)
    else
        cb(true)
    end
end)

ESX.RegisterServerCallback("mpr-cars:checkPermissionShop", function(source, cb, perm)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false) return end

    if xPlayer.getGroup() == perm or xPlayer.hasGroup(perm) then
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
        local key    = getTuningKey(identifier, plate, vname)
        local tuning = exports.oxmysql and nil -- fallback: use KVP
        -- Using FiveM built-in KVP (no external DB required for tuning flags)
        local raw    = GetResourceKvpString(key)
        local custom = raw and json.decode(raw) or {}

        if cfg.apenasDonoAcessaXenon then
            -- Only owner can access
            local ownerKey = "vehicle_owner:" .. plate
            local ownerId  = GetResourceKvpString(ownerKey)
            if ownerId and ownerId == identifier then
                cb(custom.xenonControl == 1)
            else
                cb(false)
            end
        else
            cb(custom.xenonControl == 1)
        end
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
        -- Play animation on client
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

                -- Store owner reference
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
        local key    = getTuningKey(identifier, plate, vname)
        local raw    = GetResourceKvpString(key)
        local custom = raw and json.decode(raw) or {}

        if cfg.apenasDonoAcessaNeon then
            local ownerKey = "vehicle_owner:" .. plate
            local ownerId  = GetResourceKvpString(ownerKey)
            if ownerId and ownerId == identifier then
                cb(custom.neonControl == 1)
            else
                cb(false)
            end
        else
            cb(custom.neonControl == 1)
        end
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
        local key    = getTuningKey(identifier, plate, vname)
        local raw    = GetResourceKvpString(key)
        local custom = raw and json.decode(raw) or {}

        if cfg.apenasDonoAcessaSuspensao then
            local ownerKey = "vehicle_owner:" .. plate
            local ownerId  = GetResourceKvpString(ownerKey)
            if ownerId and ownerId == identifier then
                cb(custom.suspensaoAr == 1)
            else
                cb(false)
            end
        else
            cb(custom.suspensaoAr == 1)
        end
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

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname = tostring(GetEntityModel(veh))
    local key   = getTuningKey(identifier, plate, vname)
    local raw   = GetResourceKvpString(key)
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

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "%s+", "")
    local vname = tostring(GetEntityModel(veh))
    local key   = getTuningKey(identifier, plate, vname)
    local raw   = GetResourceKvpString(key)
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
            local weight    = xPlayer.getInventoryItem(v.item)
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

-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMATION EVENTS (client-side handlers triggered from server)
-----------------------------------------------------------------------------------------------------------------------------------------
-- These are triggered on client via TriggerClientEvent("mpr-cars:playAnim") and ("mpr-cars:stopAnim")
-- The actual TaskPlayAnim natives run on client; registered below as net events on client side
-- (handled in client.lua via RegisterNetEvent)