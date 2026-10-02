-- velocidad_real | client.lua
-- Controles: B=cinturon  H=luces  G=motor  Y=crucero
--            ←→=intermitentes  ↑=emergencia
-- Comandos:  /vr_hud → mover el HUD (click+arrastrar, ESC para guardar)

local nuiVisible     = false
local cinturon       = false
local crucero        = false
local cruceroSpeed   = 0.0
local vehicleActual  = 0
local estaRecargando = false
local editModeOn     = false

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

local function speedReal(v)
    return math.floor(GetEntitySpeed(v) * 1.8)
end

local function esConductor(ped, v)
    return GetPedInVehicleSeat(v, -1) == ped
end

local function obtenerMarcha(v, gear)
    if GetEntitySpeedVector(v, true).y < -0.5 then return 'R' end
    if gear == 0 then return 'N' end
    return tostring(gear)
end

local function getPlate(v)
    return string.gsub(GetVehicleNumberPlateText(v), '%s+', '')
end

local function resetEstados(v)
    if v and v ~= 0 then
        SetVehicleEnginePowerMultiplier(v, 1.0)
        SetVehicleMaxSpeed(v, 0.0)
    end
    cinturon = false
    crucero  = false
    SendNUIMessage({ action = 'cinturon', estado = false })
    SendNUIMessage({ action = 'crucero',  estado = false })
end

local function bombaCercana(coords)
    for _, b in ipairs(Config.Bombas) do
        if #(coords - b.coords) < 10.0 then return b end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NUI CALLBACKS
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('cerrarEditMode', function(_, cb)
    editModeOn = false
    SetNuiFocus(false, false)
    cb({})
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- EDIT MODE: /vr_hud
-- ─────────────────────────────────────────────────────────────────────────────

RegisterCommand('vr_hud', function()
    editModeOn = not editModeOn
    SetNuiFocus(editModeOn, editModeOn)
    SendNUIMessage({ action = 'editMode', activo = editModeOn })
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- CINTURÓN: B
-- ─────────────────────────────────────────────────────────────────────────────

RegisterKeyMapping('vr_cinturon', 'Cinturon de seguridad', 'keyboard', 'b')
RegisterCommand('vr_cinturon', function()
    if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then return end
    cinturon = not cinturon
    PlaySoundFrontend(-1, cinturon and 'Tick' or 'CANCEL', 'RESPAWN_ONLINE_SOUNDSET', true)
    SendNUIMessage({ action = 'cinturon', estado = cinturon })
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- LUCES: H
-- ─────────────────────────────────────────────────────────────────────────────

RegisterKeyMapping('vr_luces', 'Encender / apagar luces', 'keyboard', 'h')
RegisterCommand('vr_luces', function()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 then return end
    local on, _ = GetVehicleLightsState(v)
    SetVehicleLights(v, on and 0 or 2)
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- MOTOR: G
-- ─────────────────────────────────────────────────────────────────────────────

RegisterKeyMapping('vr_motor', 'Encender / apagar motor', 'keyboard', 'g')
RegisterCommand('vr_motor', function()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 then return end
    if not GetIsVehicleEngineRunning(v) and GetVehicleFuelLevel(v) <= Config.NivelCritico then
        lib.notify({ title = '⛽ Sin combustible', description = 'Necesitas cargar gasolina', type = 'error' })
        return
    end
    SetVehicleEngineOn(v, not GetIsVehicleEngineRunning(v), true, true)
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- CRUCERO: Y
-- ─────────────────────────────────────────────────────────────────────────────

RegisterKeyMapping('vr_crucero', 'Control de crucero', 'keyboard', 'y')
RegisterCommand('vr_crucero', function()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 then return end
    crucero = not crucero
    if crucero then
        cruceroSpeed = GetEntitySpeed(v)
        PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        SendNUIMessage({ action = 'crucero', estado = true, speed = math.floor(cruceroSpeed * 1.8) })
    else
        SetVehicleMaxSpeed(v, 0.0)
        PlaySoundFrontend(-1, 'CANCEL', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        SendNUIMessage({ action = 'crucero', estado = false })
    end
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- INTERMITENTES: ← → ↑
-- ─────────────────────────────────────────────────────────────────────────────

RegisterKeyMapping('vr_izquierda', 'Intermitente izquierdo', 'keyboard', 'LEFT')
RegisterCommand('vr_izquierda', function()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 then return end
    local l   = GetVehicleIndicatorLights(v)
    local on  = l == 1 or l == 3
    SetVehicleIndicatorLights(v, 0, false)
    SetVehicleIndicatorLights(v, 1, not on)
    PlaySoundFrontend(-1, 'Tick', 'RESPAWN_ONLINE_SOUNDSET', true)
end, false)

RegisterKeyMapping('vr_derecha', 'Intermitente derecho', 'keyboard', 'RIGHT')
RegisterCommand('vr_derecha', function()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 then return end
    local l   = GetVehicleIndicatorLights(v)
    local on  = l == 2 or l == 3
    SetVehicleIndicatorLights(v, 1, false)
    SetVehicleIndicatorLights(v, 0, not on)
    PlaySoundFrontend(-1, 'Tick', 'RESPAWN_ONLINE_SOUNDSET', true)
end, false)

RegisterKeyMapping('vr_emergencia', 'Luces de emergencia', 'keyboard', 'UP')
RegisterCommand('vr_emergencia', function()
    local v   = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 then return end
    local haz = GetVehicleIndicatorLights(v) == 3
    SetVehicleIndicatorLights(v, 0, not haz)
    SetVehicleIndicatorLights(v, 1, not haz)
    PlaySoundFrontend(-1, 'Tick', 'RESPAWN_ONLINE_SOUNDSET', true)
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
-- SISTEMA DE GASOLINA: recarga
-- ─────────────────────────────────────────────────────────────────────────────

local function iniciarRecarga(vehicle, bomba)
    if estaRecargando then return end
    estaRecargando = true

    local ped        = PlayerPedId()
    local fuelActual = GetVehicleFuelLevel(vehicle)
    local falta      = Config.MaxCombustible - fuelActual

    if falta < 1.0 then
        lib.notify({ title = '⛽ Tanque lleno', description = 'No necesitas cargar', type = 'inform' })
        estaRecargando = false
        return
    end

    local litros   = math.min(falta, 65.0)
    local precio   = math.floor(litros * Config.PrecioPorLitro)
    local duracion = math.floor(litros * Config.MsPorLitro)

    -- Cobrar al jugador
    local pagado = lib.callback.await('velocidad_real:cobrarGasolina', false, precio)
    if not pagado then
        lib.notify({ title = '⛽ Sin fondos', description = 'Necesitas $'..precio, type = 'error' })
        estaRecargando = false
        return
    end

    -- Salir del vehículo si estaba dentro
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        TaskLeaveVehicle(ped, vehicle, 16)
        Citizen.Wait(2500)
    end

    -- Guardar cámara y cambiar a primera persona
    local camAnterior = GetFollowPedCamViewMode()
    SetFollowPedCamViewMode(4)

    -- Mostrar overlay NUI de la bomba
    SendNUIMessage({
        action   = 'iniciarRecarga',
        litros   = math.floor(litros * 10) / 10,
        precio   = precio,
        duracion = duracion,
        nombre   = bomba.nombre,
    })

    -- Thread paralelo: actualiza combustible progresivamente
    local activo    = true
    local fuelBase  = GetVehicleFuelLevel(vehicle)
    Citizen.CreateThread(function()
        local t0 = GetGameTimer()
        while activo do
            local pct       = math.min((GetGameTimer() - t0) / duracion, 1.0)
            local nuevoFuel = math.min(fuelBase + litros * pct, Config.MaxCombustible)
            SetVehicleFuelLevel(vehicle, nuevoFuel)
            SendNUIMessage({ action = 'progresoRecarga', pct = pct, litrosAct = math.floor(nuevoFuel * 10) / 10 })
            Citizen.Wait(80)
        end
    end)

    -- Animacion principal (ox_lib bloquea este hilo hasta terminar)
    lib.progressBar({
        duration     = duracion,
        label        = 'Cargando combustible...',
        useWhileDead = false,
        canCancel    = false,
        disable      = { move = true, combat = true, car = true },
        anim         = { dict = 'weapon@w_sp_jerrycan', clip = 'fire' },
    })

    activo = false
    SetVehicleFuelLevel(vehicle, math.min(fuelBase + litros, Config.MaxCombustible))
    SetFollowPedCamViewMode(camAnterior)
    SendNUIMessage({ action = 'finRecarga' })
    lib.notify({ title = '⛽ Listo', description = math.floor(litros)..'L cargados — $'..precio, type = 'success' })

    -- Guardar en servidor
    TriggerServerEvent('velocidad_real:guardarCombustible', getPlate(vehicle), GetVehicleFuelLevel(vehicle))
    estaRecargando = false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- THREAD: PROXIMIDAD GASOLINERAS
-- ─────────────────────────────────────────────────────────────────────────────

Citizen.CreateThread(function()
    local textuiOn = false
    while true do
        local sleep  = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local bomba  = bombaCercana(coords)

        if bomba and not estaRecargando then
            sleep = 0
            local v = GetVehiclePedIsIn(ped, false)
            if v == 0 then
                v = GetClosestVehicle(coords.x, coords.y, coords.z, 10.0, 0, 70)
            end

            if v and v ~= 0 then
                if not textuiOn then
                    local falta  = Config.MaxCombustible - GetVehicleFuelLevel(v)
                    local litros = math.min(falta, 65.0)
                    lib.showTextUI('[E] Cargar gasolina  $'..math.floor(litros * Config.PrecioPorLitro), {
                        position = 'bottom-center',
                    })
                    textuiOn = true
                end
                if IsControlJustReleased(0, 38) then  -- E
                    lib.hideTextUI()
                    textuiOn = false
                    local vRef  = v
                    local bRef  = bomba
                    Citizen.CreateThread(function()
                        iniciarRecarga(vRef, bRef)
                    end)
                end
            else
                if textuiOn then lib.hideTextUI() textuiOn = false end
            end
        else
            if textuiOn then lib.hideTextUI() textuiOn = false end
        end

        Citizen.Wait(sleep)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- THREAD PRINCIPAL: vehículo, consumo, HUD
-- ─────────────────────────────────────────────────────────────────────────────

Citizen.CreateThread(function()
    Citizen.Wait(2000)  -- espera que cargue la NUI
    while true do
        local ped = PlayerPedId()
        local v   = GetVehiclePedIsIn(ped, false)

        local esDriver = v ~= 0 and esConductor(ped, v)
        if IsPedInAnyVehicle(ped, false) then

            -- Cambio de vehículo
            if v ~= vehicleActual then
                resetEstados(vehicleActual)
                vehicleActual = v
                -- Carga el combustible en un hilo aparte para no bloquear el mostrar del HUD
                local vRef = v
                Citizen.CreateThread(function()
                    local plate        = getPlate(vRef)
                    local fuelServidor = lib.callback.await('velocidad_real:getCombustible', false, plate)
                    if fuelServidor and GetVehiclePedIsIn(PlayerPedId(), false) == vRef then
                        SetVehicleFuelLevel(vRef, fuelServidor)
                    end
                end)
            end

            if not nuiVisible then
                SendNUIMessage({ action = 'mostrar' })
                nuiVisible = true
            end

            local fuel = GetVehicleFuelLevel(v)

            -- Consumo de combustible
            if not estaRecargando and GetIsVehicleEngineRunning(v) then
                local spd    = GetEntitySpeed(v) * 3.6
                local cons   = (Config.ConsumoPorSegundo + spd * Config.ConsumoPorVelocidad) / 60.0
                fuel         = math.max(fuel - cons, 0.0)
                SetVehicleFuelLevel(v, fuel)
            end

            -- Motor se apaga sin gasolina
            if fuel <= Config.NivelCritico and GetIsVehicleEngineRunning(v) then
                SetVehicleEngineOn(v, false, false, true)
            end

            -- Crucero o boost (solo para el conductor)
            if esDriver then
                if crucero then
                    SetVehicleEnginePowerMultiplier(v, 1.0)
                    local freno = GetControlNormal(0, 72)
                    if freno > 0.1 then
                        crucero = false
                        SetVehicleMaxSpeed(v, 0.0)
                        SendNUIMessage({ action = 'crucero', estado = false })
                    else
                        SetVehicleMaxSpeed(v, cruceroSpeed + 0.5)
                        if GetEntitySpeed(v) < cruceroSpeed - 0.5 then
                            SetVehicleForwardSpeed(v, cruceroSpeed)
                        end
                    end
                else
                    SetVehicleEnginePowerMultiplier(v, 2.0)
                    SetVehicleMaxSpeed(v, 250.0)
                end
            end

            local lucesOn, altasOn = GetVehicleLightsState(v)
            local ind              = GetVehicleIndicatorLights(v)

            SendNUIMessage({
                action     = 'actualizar',
                speed      = speedReal(v),
                gear       = obtenerMarcha(v, GetVehicleCurrentGear(v)),
                rpm        = GetVehicleCurrentRpm(v),
                fuel       = math.floor(fuel),
                luces      = lucesOn,
                altas      = altasOn,
                blinkerIzq = ind == 1 or ind == 3,
                blinkerDer = ind == 2 or ind == 3,
                motor      = GetIsVehicleEngineRunning(v),
                crucero    = crucero,
                lowFuel    = fuel <= Config.NivelAdvertencia,
            })

            Citizen.Wait(0)
        else
            if nuiVisible then
                if vehicleActual ~= 0 then
                    TriggerServerEvent('velocidad_real:guardarCombustible',
                        getPlate(vehicleActual), GetVehicleFuelLevel(vehicleActual))
                end
                resetEstados(vehicleActual)
                vehicleActual = 0
                SendNUIMessage({ action = 'ocultar' })
                nuiVisible = false
            end
            Citizen.Wait(500)
        end
    end
end)
