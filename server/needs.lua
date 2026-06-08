local config = require 'config.survival'

local function getStat(src, key, default)
    local v = Player(src).state[key]
    if v == nil then return default end
    return v
end

local function setStat(src, key, value, min, max)
    value = math.max(min, math.min(max, value))
    Player(src).state:set(key, value, true)
    return value
end

exports('GetTemperature', function(src) return getStat(src, 'temperature', config.temperature.default) end)
exports('SetTemperature', function(src, v) return setStat(src, 'temperature', v, config.temperature.min, config.temperature.max) end)
exports('AddTemperature', function(src, a)
    return setStat(src, 'temperature', getStat(src, 'temperature', config.temperature.default) + a, config.temperature.min, config.temperature.max)
end)
exports('AddBladder', function(src, a) return setStat(src, 'bladder', getStat(src, 'bladder', 0) + a, 0, config.bladder.max) end)
exports('AddBowel', function(src, a) return setStat(src, 'bowel', getStat(src, 'bowel', 0) + a, 0, config.bowel.max) end)
exports('GetRadiation', function(src) return getStat(src, 'radiation', config.radiation.default) end)
exports('SetRadiation', function(src, v) return setStat(src, 'radiation', v, config.radiation.min, config.radiation.max) end)
exports('AddRadiation', function(src, a)
    return setStat(src, 'radiation', getStat(src, 'radiation', config.radiation.default) + a, config.radiation.min, config.radiation.max)
end)
exports('RemoveRadiation', function(src, a)
    return setStat(src, 'radiation', getStat(src, 'radiation', config.radiation.default) - a, config.radiation.min, config.radiation.max)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    setStat(src, 'temperature', config.temperature.default, config.temperature.min, config.temperature.max)
    setStat(src, 'bladder', config.bladder.default, 0, config.bladder.max)
    setStat(src, 'bowel', config.bowel.default, 0, config.bowel.max)
    setStat(src, 'radiation', config.radiation.default, config.radiation.min, config.radiation.max)
end)

RegisterNetEvent('qbx_core:server:tempTick', function(env)
    if type(env) ~= 'table' then return end
    local src = source
    local t = config.temperature
    local temp = getStat(src, 'temperature', t.default)
    local delta = 0

    if env.hot then delta += t.heatRise + (tonumber(env.heatPenalty) or 0) end
    if env.night then delta -= t.nightDrop end
    if env.rain then delta -= t.rainDrop end
    if env.water then delta -= t.waterDrop end
    if env.cold then delta -= t.snowDrop end

    local warmth = tonumber(env.warmth) or 0
    if delta < 0 and warmth > 0 then delta = math.min(0, delta + warmth) end

    if delta == 0 then
        local mid = (t.comfortMin + t.comfortMax) / 2
        if temp < mid then delta = math.min(t.baseRegen, mid - temp)
        elseif temp > mid then delta = -math.min(t.baseRegen, temp - mid) end
    end

    delta = math.max(-t.maxDelta, math.min(t.maxDelta, delta))
    setStat(src, 'temperature', temp + delta, t.min, t.max)
end)

RegisterNetEvent('qbx_core:server:drinkTemp', function(kind)
    local src = source
    local a = kind == 'hot' and config.temperature.hotDrink or -config.temperature.coldDrink
    setStat(src, 'temperature', getStat(src, 'temperature', config.temperature.default) + a, config.temperature.min, config.temperature.max)
end)

RegisterNetEvent('qbx_core:server:radTick', function(data)
    if type(data) ~= 'table' then return end
    local src = source
    local r = config.radiation
    local rad = getStat(src, 'radiation', r.default)
    local delta
    if data.inZone then
        local protection = math.max(0, math.min(1, tonumber(data.protection) or 0))
        delta = (tonumber(data.intensity) or 0) * (1 - protection)
    else
        delta = -r.decayPerTick
    end
    delta = math.max(-r.maxDelta, math.min(r.maxDelta, delta))
    setStat(src, 'radiation', rad + delta, r.min, r.max)
end)

RegisterNetEvent('qbx_core:server:antiRad', function(amount)
    local src = source
    local a = tonumber(amount) or 25
    setStat(src, 'radiation', getStat(src, 'radiation', config.radiation.default) - a, config.radiation.min, config.radiation.max)
end)

local prevHunger, prevThirst = {}, {}

AddStateBagChangeHandler('thirst', nil, function(bagName, _, value)
    local src = GetPlayerFromStateBagName(bagName)
    if src == 0 then return end
    local prev = prevThirst[src]
    prevThirst[src] = value
    if prev and value > prev + 0.5 then
        setStat(src, 'bladder', getStat(src, 'bladder', 0) + config.bladder.drinkGain, 0, config.bladder.max)
    end
end)

AddStateBagChangeHandler('hunger', nil, function(bagName, _, value)
    local src = GetPlayerFromStateBagName(bagName)
    if src == 0 then return end
    local prev = prevHunger[src]
    prevHunger[src] = value
    if prev and value > prev + 0.5 then
        setStat(src, 'bowel', getStat(src, 'bowel', 0) + config.bowel.eatGain, 0, config.bowel.max)
    end
end)

local function maybeInfect(src)
    if config.relieve.autoInfectionChance > 0
        and GetResourceState('fivez_injuries') == 'started'
        and math.random(100) <= config.relieve.autoInfectionChance then
        local ok, fn = pcall(function() return exports.fivez_injuries.AddInfection end)
        if ok and fn then exports.fivez_injuries:AddInfection(src, 'lower_body', 5) end
    end
end

RegisterNetEvent('qbx_core:server:relieve', function(kind)
    local src = source
    if kind == 'pee' then
        setStat(src, 'bladder', 0, 0, config.bladder.max)
    elseif kind == 'poop' then
        setStat(src, 'bowel', 0, 0, config.bowel.max)
    end
end)

CreateThread(function()
    while true do
        Wait(config.tickInterval * 1000)
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            if Player(src).state.isLoggedIn and not Player(src).state.isDead then
                local b = setStat(src, 'bladder', getStat(src, 'bladder', 0) + config.bladder.timeGain, 0, config.bladder.max)
                if b >= config.bladder.auto then
                    setStat(src, 'bladder', 0, 0, config.bladder.max)
                    TriggerClientEvent('qbx_core:client:autoRelieve', src, 'pee')
                    maybeInfect(src)
                end

                local bo = setStat(src, 'bowel', getStat(src, 'bowel', 0) + config.bowel.timeGain, 0, config.bowel.max)
                if bo >= config.bowel.auto then
                    setStat(src, 'bowel', 0, 0, config.bowel.max)
                    TriggerClientEvent('qbx_core:client:autoRelieve', src, 'poop')
                    maybeInfect(src)
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    prevHunger[source] = nil
    prevThirst[source] = nil
end)
