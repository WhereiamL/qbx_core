local config = require 'config.survival'
local playerState = LocalPlayer.state
local warmth = 0 -- toplina odjeće (drugi resursi je postavljaju ovim exportom)

exports('SetClothingWarmth', function(level) warmth = tonumber(level) or 0 end)

-- HUD eventi (qbx_hud može slušati ove)
AddStateBagChangeHandler('temperature', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateTemperature', value)
end)
AddStateBagChangeHandler('bladder', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateBladder', value)
end)
AddStateBagChangeHandler('bowel', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateBowel', value)
end)

-- TEMPERATURA: javljaj okolinu serveru
CreateThread(function()
    if not config.temperature.enabled then return end
    local t = config.temperature
    while true do
        Wait(t.tickInterval * 1000)
        if QBX.IsLoggedIn and not playerState.isDead then
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            local hour = GetClockHours()
            TriggerServerEvent('qbx_core:server:tempTick', {
                night = hour >= 22 or hour < 6,
                rain = GetRainLevel() > 0.1,
                water = IsEntityInWater(ped) or IsPedSwimming(ped),
                cold = coords.z > t.coldAltitude,
                hot = t.hotZones[GetNameOfZone(coords.x, coords.y, coords.z)] == true,
                warmth = warmth,
            })
        end
    end
end)

-- efekti temperature (drhtanje + HP šteta na ekstremu -> vodi u DOWNED)
CreateThread(function()
    if not config.temperature.enabled then return end
    local t = config.temperature
    while true do
        local sleep = 5000
        if QBX.IsLoggedIn and not playerState.isDead then
            local temp = playerState.temperature or t.default
            if temp <= t.coldShiverThreshold then
                ShakeGameplayCam('SKY_DIVING_SHAKE', 0.12)
            end
            if temp <= t.coldDamageThreshold or temp >= t.hotDamageThreshold then
                local hp = GetEntityHealth(cache.ped)
                if hp > 0 then SetEntityHealth(cache.ped, hp - t.damage) end
                sleep = 3000
            end
        end
        Wait(sleep)
    end
end)

-- mjehur/crijeva: nelagoda (blokira sprint dok je puno)
CreateThread(function()
    while true do
        local sleep = 500
        local full = (playerState.bladder or 0) >= config.bladder.discomfort
            or (playerState.bowel or 0) >= config.bowel.discomfort
        if full and QBX.IsLoggedIn and not playerState.isDead then
            sleep = 0
            DisableControlAction(0, 21, true) -- sprint
        end
        Wait(sleep)
    end
end)

-- pokreni particle efekat na karlici, vrati handle (ili nil)
local function startRelievePtfx(cfg)
    if not cfg.ptfx or not lib.requestNamedPtfxAsset(cfg.ptfx.dict, 1000) then return end
    UseParticleFxAsset(cfg.ptfx.dict)
    local o = cfg.ptfx.offset or vec3(0.0, 0.0, 0.0)
    local bone = GetPedBoneIndex(cache.ped, 11816) -- lower body
    return StartParticleFxLoopedOnEntityBone(cfg.ptfx.name, cache.ped, o.x, o.y, o.z, 0.0, 0.0, 0.0, bone, 1.0, false, false, false)
end

-- olakšanje
local function relieve(kind)
    local cfg = kind == 'pee' and config.relieve.pee or config.relieve.poop
    local stat = kind == 'pee' and 'bladder' or 'bowel'
    if (playerState[stat] or 0) < config.relieve.minToRelieve then
        exports.qbx_core:Notify('Ne treba ti', 'error')
        return
    end
    local fx = startRelievePtfx(cfg)
    local ok = lib.progressBar({
        duration = cfg.duration,
        label = kind == 'pee' and 'Pišanje...' or 'Obavljanje nužde...',
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = cfg.anim.dict, clip = cfg.anim.clip },
    })
    if fx then StopParticleFxLooped(fx, false) end
    if cfg.ptfx then RemoveNamedPtfxAsset(cfg.ptfx.dict) end
    if ok then TriggerServerEvent('qbx_core:server:relieve', kind) end
end

RegisterCommand('piski', function() relieve('pee') end, false)
RegisterCommand('kaki', function() relieve('poop') end, false)

-- auto-pražnjenje (sramota)
RegisterNetEvent('qbx_core:client:autoRelieve', function(kind)
    local cfg = kind == 'pee' and config.relieve.pee or config.relieve.poop
    exports.qbx_core:Notify(kind == 'pee' and 'Upiškio si se...' or 'Ukakio si se...', 'error')
    if cfg.anim and lib.requestAnimDict(cfg.anim.dict, 1000) then
        TaskPlayAnim(cache.ped, cfg.anim.dict, cfg.anim.clip, 8.0, -8.0, 3000, 1, 0, false, false, false)
    end
    local fx = startRelievePtfx(cfg)
    if fx then SetTimeout(3000, function() StopParticleFxLooped(fx, false) end) end
end)

-- topli/hladni napici (ox_inventory item -> ovaj export)
exports('useHotDrink', function() TriggerServerEvent('qbx_core:server:drinkTemp', 'hot') end)
exports('useColdDrink', function() TriggerServerEvent('qbx_core:server:drinkTemp', 'cold') end)
