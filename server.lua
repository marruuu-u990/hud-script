-- velocidad_real | server.lua
local QBCore      = exports['qb-core']:GetCoreObject()
local vehicleFuel = {}  -- plate -> nivel de combustible (persiste en memoria del server)

-- ── COBRAR GASOLINA ────────────────────────────────────────────────────────
lib.callback.register('velocidad_real:cobrarGasolina', function(source, precio)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local cash = Player.Functions.GetMoney('cash')
    local bank = Player.Functions.GetMoney('bank')

    if cash >= precio then
        Player.Functions.RemoveMoney('cash', precio, 'Gasolina [velocidad_real]')
        return true
    elseif bank >= precio then
        Player.Functions.RemoveMoney('bank', precio, 'Gasolina [velocidad_real]')
        return true
    end

    return false
end)

-- ── OBTENER COMBUSTIBLE POR PLACA ──────────────────────────────────────────
lib.callback.register('velocidad_real:getCombustible', function(_, plate)
    return vehicleFuel[plate]  -- nil si no fue guardado antes
end)

-- ── GUARDAR COMBUSTIBLE POR PLACA ─────────────────────────────────────────
RegisterNetEvent('velocidad_real:guardarCombustible', function(plate, fuel)
    if plate and fuel then
        vehicleFuel[plate] = fuel
    end
end)
