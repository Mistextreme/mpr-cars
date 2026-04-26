-----------------------------------------------------------------------------------------------------------------------------------------
-- ESX
-----------------------------------------------------------------------------------------------------------------------------------------
ESX = exports["es_extended"]:getSharedObject()

-----------------------------------------------------------------------------------------------------------------------------------------
-- STATE
-----------------------------------------------------------------------------------------------------------------------------------------
local parts          = {"wheel_lf", "wheel_lr", "wheel_rf", "wheel_rr"}
local partsProntas   = {}
local instalando     = false
local vehicleInstall = nil
local menuactive     = false

-----------------------------------------------------------------------------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function Notify(type, msg, duration)
    ESX.ShowNotification(msg)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.003 + factor, 0.03, 41, 11, 41, 68)
end

local function checkNeonIsEnable(vehicle)
    local toggle = false
    local lados = {0, 1, 2, 3}
    for _, l in pairs(lados) do
        if IsVehicleNeonLightEnabled(vehicle, l) then
            toggle = true
        end
    end
    return toggle
end

local function closeNuis()
    SetNuiFocus(false, false)
    TransitionFromBlurred(1000)
    SendNUIMessage({ type = "closeNuis" })
end

local function ToggleActionMenu()
    menuactive = not menuactive
    if menuactive then
        SetNuiFocus(true, true)
        TransitionToBlurred(1000)
        SendNUIMessage({ showmenu = true })
    else
        SetNuiFocus(false, false)
        TransitionFromBlurred(1000)
        SendNUIMessage({ hidemenu = true })
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- DISABLE CONTROL WHILE INSTALLING
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if instalando then
            DisableControlAction(0, 167, true)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSION CHECKS (via server callbacks)
-----------------------------------------------------------------------------------------------------------------------------------------
local function checkPermission(cb)
    ESX.TriggerServerCallback("mpr-cars:checkPermission", function(result)
        cb(result)
    end)
end

local function checkPermissionShop(perm, cb)
    ESX.TriggerServerCallback("mpr-cars:checkPermissionShop", function(result)
        cb(result)
    end, perm)
end

local function checkXenon(cb)
    ESX.TriggerServerCallback("mpr-cars:checkXenon", function(result)
        cb(result)
    end)
end

local function checkNeon(cb)
    ESX.TriggerServerCallback("mpr-cars:checkNeon", function(result)
        cb(result)
    end)
end

local function checkSuspension(cb)
    ESX.TriggerServerCallback("mpr-cars:checkSuspension", function(result)
        cb(result)
    end)
end

local function returnPreset(cb)
    ESX.TriggerServerCallback("mpr-cars:returnPreset", function(result)
        cb(result)
    end)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- NEAREST VEHICLE HELPER
-----------------------------------------------------------------------------------------------------------------------------------------
local function getNearestVehicle(radius)
    local ped    = PlayerPedId()
    local pos    = GetEntityCoords(ped)
    local handle = GetClosestVehicle(pos.x, pos.y, pos.z, radius, 0, 70)
    if handle ~= 0 then
        return handle
    end
    return nil
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- COMMANDS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    closeNuis()

    -- XENON COMMAND
    RegisterCommand(cfg.comandoXenon, function(source, args, rawCommand)
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)
        if vehicle ~= 0 then
            checkXenon(function(has)
                if has then
                    local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 3.605936)
                    local cor          = GetVehicleXenonLightsColour(vehicle)
                    if vehicleSpeed <= 25 then
                        ToggleVehicleMod(vehicle, 22, true)
                        SetNuiFocus(true, true)
                        SendNUIMessage({ type = "openXenon", color = cor })
                    else
                        Notify("aviso", "Você está muito rápido!")
                    end
                else
                    Notify("aviso", "O veículo não possui o módulo de xenon.")
                end
            end)
        else
            Notify("aviso", "Você não está em um veículo!")
        end
    end)

    -- NEON COMMAND
    RegisterCommand(cfg.comandoNeon, function(source, args, rawCommand)
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)
        if vehicle ~= 0 then
            checkNeon(function(has)
                if has then
                    local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 3.605936)
                    local cor          = { r = 255, g = 255, b = 255 }
                    if checkNeonIsEnable(vehicle) then
                        local r, g, b = GetVehicleNeonLightsColour(vehicle)
                        cor = { r = r, g = g, b = b }
                    end
                    if vehicleSpeed <= 25 then
                        SetNuiFocus(true, true)
                        SendNUIMessage({ type = "openNeon", color = cor })
                    else
                        Notify("aviso", "Você está muito rápido!")
                    end
                else
                    Notify("aviso", "O veículo não possui o módulo de neon.")
                end
            end)
        else
            Notify("aviso", "Você não está em um veículo!")
        end
    end)

    -- SUSPENSION COMMAND
    RegisterCommand(cfg.comandoSuspensao, function(source, args, rawCommand)
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsUsing(ped)
        if vehicle ~= 0 then
            checkSuspension(function(has)
                if has then
                    local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 3.605936)
                    if vehicleSpeed <= 25 then
                        SetNuiFocus(true, true)
                        SendNUIMessage({ type = "openControle" })
                    else
                        Notify("aviso", "Você está muito rápido!")
                    end
                else
                    Notify("aviso", "O veículo não possui suspensão a ar!")
                end
            end)
        else
            Notify("aviso", "Você não está em um veículo!")
        end
    end)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- NUI CALLBACKS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("ButtonClick", function(data, cb)
    cb({})

    -- Shop purchase buttons
    if data == "comprar-suspensao" then
        TriggerServerEvent("mpr-cars:comprar", "suspensaoar")
    elseif data == "comprar-neon" then
        TriggerServerEvent("mpr-cars:comprar", "moduloneon")
    elseif data == "comprar-xenon" then
        TriggerServerEvent("mpr-cars:comprar", "moduloxenon")
    elseif data == "fechar" then
        ToggleActionMenu()
    end

    if type(data) == "table" then
        -- Close NUIs
        if data.action == "closeNuis" then
            closeNuis()
        end

        -- Xenon color change
        if data.action == "trocar-cor-xenon" then
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleXenonLightsColour(vehicle, data.cor)
        end

        -- Neon on/off toggle
        if data.action == "on-off-neon" then
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local toggle  = checkNeonIsEnable(vehicle)
            local lados   = {0, 1, 2, 3}
            for _, l in pairs(lados) do
                SetVehicleNeonLightEnabled(vehicle, l, not toggle)
            end
            if not toggle then
                local r, g, b = GetVehicleNeonLightsColour(vehicle)
                SendNUIMessage({ type = "setColorNeon", color = { r = r, g = g, b = b } })
            end
        end

        -- Toggle individual neon side
        if data.action == "toggle-neon" then
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local r, g, b = GetVehicleNeonLightsColour(vehicle)
            SendNUIMessage({ type = "setColorNeon", color = { r = r, g = g, b = b } })
            SetVehicleNeonLightEnabled(vehicle, data.lado, not IsVehicleNeonLightEnabled(vehicle, data.lado))
        end

        -- Neon color change
        if data.action == "trocar-cor-neon" then
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleNeonLightsColour(vehicle, data.cor.r, data.cor.g, data.cor.b)
        end

        -- Save suspension preset
        if data.action == "savepreset" then
            local ped        = PlayerPedId()
            local vehicle    = GetVehiclePedIsIn(ped)
            local alturaAtual = GetVehicleSuspensionHeight(vehicle)
            TriggerServerEvent("mpr-cars:setPreset", tonumber(alturaAtual))
            Notify("sucesso", "Novo preset definido para suspensão!")
        end

        -- Suspension control
        if data.action == "useControl" then
            local ped           = PlayerPedId()
            local vehicle       = GetVehiclePedIsIn(ped)
            local alturaAnterior = GetVehicleSuspensionHeight(vehicle)
            local alturaAtual   = 0
            local typeAction    = data.typeAction
            local variacao      = 0.003

            if typeAction == "max" then
                alturaAtual = tonumber(-0.09)
                variacao    = 0.003
            elseif typeAction == "normal" then
                alturaAtual = tonumber(0.0)
                variacao    = 0.003
            elseif typeAction == "low" then
                alturaAtual = tonumber(0.09)
                variacao    = 0.003
            elseif typeAction == "up" then
                alturaAtual = alturaAnterior - tonumber(0.003)
                variacao    = 0.0003
            elseif typeAction == "down" then
                alturaAtual = alturaAnterior + tonumber(0.003)
                variacao    = 0.0003
            elseif typeAction == "preset" then
                variacao = 0.003
                returnPreset(function(preset)
                    alturaAtual = tonumber(preset)
                    if alturaAtual > tonumber(0.09) then
                        Notify("aviso", "Altura máxima atingida!")
                        return
                    end
                    if alturaAtual < tonumber(-0.09) then
                        Notify("aviso", "Altura miníma atingida!")
                        return
                    end
                    if alturaAnterior < alturaAtual then
                        SendNUIMessage({ transactionType = "playSound", transactionFile = "esvaziar", transactionVolume = 0.5 })
                        TriggerServerEvent("mpr-cars:tryzosuspe", VehToNet(vehicle), alturaAtual, alturaAnterior, variacao, "descer")
                    else
                        SendNUIMessage({ transactionType = "playSound", transactionFile = "encher", transactionVolume = 0.5 })
                        TriggerServerEvent("mpr-cars:tryzosuspe", VehToNet(vehicle), alturaAtual, alturaAnterior, variacao, "subir")
                    end
                end)
                return
            end

            if alturaAtual > tonumber(0.09) then
                Notify("aviso", "Altura máxima atingida!")
                return
            end
            if alturaAtual < tonumber(-0.09) then
                Notify("aviso", "Altura miníma atingida!")
                return
            end

            if alturaAnterior < alturaAtual then
                SendNUIMessage({ transactionType = "playSound", transactionFile = "esvaziar", transactionVolume = 0.5 })
                TriggerServerEvent("mpr-cars:tryzosuspe", VehToNet(vehicle), alturaAtual, alturaAnterior, variacao, "descer")
            else
                SendNUIMessage({ transactionType = "playSound", transactionFile = "encher", transactionVolume = 0.5 })
                TriggerServerEvent("mpr-cars:tryzosuspe", VehToNet(vehicle), alturaAtual, alturaAnterior, variacao, "subir")
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- INSTALL COMMAND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("instalar", function(source, args, rawCommand)
    if args[1] then
        if args[1] == "xenon" then
            TriggerEvent("mpr-cars:install_mod_xenon")
        elseif args[1] == "neon" then
            TriggerEvent("mpr-cars:install_mod_neon")
        elseif args[1] == "suspe" then
            TriggerEvent("mpr-cars:install_suspe_ar")
        end
    else
        Notify("negado", "Utilize /instalar [xenon, neon ou suspe]")
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- INSTALL XENON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:install_mod_xenon")
AddEventHandler("mpr-cars:install_mod_xenon", function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if vehicle ~= 0 then
        if ped == GetPedInVehicleSeat(vehicle, -1) then
            local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 3.605936)
            if vehicleSpeed == 0 then
                checkPermission(function(hasPerm)
                    if hasPerm then
                        checkXenon(function(hasXenon)
                            if not hasXenon then
                                SetVehicleEngineOn(vehicle, false, true, true)
                                TriggerServerEvent("mpr-cars:installXenon", VehToNet(vehicle))
                            else
                                Notify("aviso", "Veículo já possui módulo de Xenon")
                            end
                        end)
                    else
                        Notify("aviso", "Você não possui permissão para instalar o módulo de Xenon!")
                    end
                end)
            else
                Notify("aviso", "O veículo deve estar parado!")
            end
        else
            Notify("aviso", "Você não é o motorista do veículo")
        end
    else
        Notify("aviso", "Você não está em um veículo!")
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- INSTALL NEON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:install_mod_neon")
AddEventHandler("mpr-cars:install_mod_neon", function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    if vehicle ~= 0 then
        if ped == GetPedInVehicleSeat(vehicle, -1) then
            local vehicleSpeed = math.ceil(GetEntitySpeed(vehicle) * 3.605936)
            if vehicleSpeed == 0 then
                checkPermission(function(hasPerm)
                    if hasPerm then
                        checkNeon(function(hasNeon)
                            if not hasNeon then
                                SetVehicleEngineOn(vehicle, false, true, true)
                                TriggerServerEvent("mpr-cars:installNeon", VehToNet(vehicle))
                            else
                                Notify("aviso", "Veículo já possui módulo de neon")
                            end
                        end)
                    else
                        Notify("aviso", "Você não possui permissão para instalar o módulo de neon!")
                    end
                end)
            else
                Notify("aviso", "O veículo deve estar parado!")
            end
        else
            Notify("aviso", "Você não é o motorista do veículo")
        end
    else
        Notify("aviso", "Você não está em um veículo!")
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- INSTALL AIR SUSPENSION
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:install_suspe_ar")
AddEventHandler("mpr-cars:install_suspe_ar", function()
    checkPermission(function(hasPerm)
        if hasPerm then
            local ped = PlayerPedId()
            vehicleInstall = getNearestVehicle(5)
            if vehicleInstall then
                checkSuspension(function(hasSuspe)
                    if not hasSuspe then
                        local coords   = nil
                        local ppos     = GetEntityCoords(ped)
                        partsProntas   = {}

                        for _, v in ipairs(parts) do
                            local bone = GetEntityBoneIndexByName(vehicleInstall, v)
                            if bone ~= -1 then
                                coords = GetWorldPositionOfEntityBone(vehicleInstall, bone)
                                if coords then
                                    local len = GetDistanceBetweenCoords(
                                        vector3(ppos.x, ppos.y, ppos.z), coords)
                                    if len < 5 then
                                        local x, y, z = table.unpack(coords)
                                        while vehicleInstall and partsProntas[v] == nil do
                                            DrawMarker(1, x, y, z - 1.5, 0, 0, 0, 0, 0,
                                                0, 1.0, 1.0, 1.7, 0, 255, 0, 155,
                                                0, 0, 0, 1)
                                            ppos = GetEntityCoords(ped)
                                            len  = GetDistanceBetweenCoords(
                                                vector3(ppos.x, ppos.y, ppos.z), coords)
                                            if len < 1 then
                                                DrawText3D(x, y, z, "Pressione [~r~E~w~] para instalar a suspensão nesta roda.")
                                                if IsControlJustPressed(0, 38) then
                                                    instalando = true
                                                    Citizen.CreateThread(function()
                                                        while true do
                                                            Citizen.Wait(2000)
                                                            vehicleInstall = getNearestVehicle(5)
                                                            if vehicleInstall == nil or #partsProntas == 4 then
                                                                if vehicleInstall == nil then
                                                                    Notify("aviso", "Instalação cancelada, você não está próximo do veículo!")
                                                                end
                                                                return
                                                            end
                                                        end
                                                    end)

                                                    -- Play anim via server
                                                    TriggerServerEvent("mpr-cars:playInstallAnim")
                                                    partsProntas[v] = v
                                                    table.insert(partsProntas, v)
                                                end
                                            end
                                            if #partsProntas == 4 then
                                                TriggerServerEvent("mpr-cars:setSuspensao", VehToNet(vehicleInstall))
                                                Notify("sucesso", "Suspensão a ar instalada no veículo!")
                                            end
                                            Citizen.Wait(5)
                                        end
                                    end
                                end
                            end
                        end
                    else
                        Notify("aviso", "Veículo já possui suspensão a ar")
                    end
                end)
            else
                Notify("aviso", "Você não está próximo de um veículo!")
            end
        else
            Notify("aviso", "Você não possui permissão para instalar suspensão a ar!")
        end
    end)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- STOP INSTALLING STATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:setInstalando")
AddEventHandler("mpr-cars:setInstalando", function(bool)
    instalando = bool
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SYNC SUSPENSION HEIGHT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("mpr-cars:synczosuspe")
AddEventHandler("mpr-cars:synczosuspe", function(vehicle, altura)
    if NetworkDoesNetworkIdExist(vehicle) then
        local v = NetToVeh(vehicle)
        SetVehicleSuspensionHeight(v, altura)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SHOP BLIP + MARKER THREAD
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    -- Create map blips
    for _, l in pairs(cfg.blipsShopMec) do
        local v    = l.loc
        local blip = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blip, 446)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Loja de Peças")
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    SetNuiFocus(false, false)
    while true do
        local idle = 1000

        for _, l in pairs(cfg.blipsShopMec) do
            local v   = l.loc
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped))
            local distance = GetDistanceBetweenCoords(v.x, v.y, v.z, x, y, z, true)

            if distance < 2.1 and not menuactive then
                DrawText3D(v.x, v.y, v.z, "Pressione [~p~E~w~] para acessar a Loja de Peças.")
            end

            if distance < 5.1 then
                DrawMarker(23, v.x, v.y, v.z - 0.99, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.5, 136, 96, 240, 180, 0, 0, 0, 0)
                idle = 5
                if distance <= 1.2 then
                    if IsControlJustPressed(0, 38) then
                        for _, perm in pairs(l.perms) do
                            checkPermissionShop(perm, function(hasShopPerm)
                                if hasShopPerm then
                                    ToggleActionMenu()
                                end
                            end)
                        end
                    end
                end
            end
        end

        Citizen.Wait(idle)
    end
end)