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
AddStateBagChangeHandler('radiation', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateRadiation', value)
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

-- ========================== RADIJACIJA ==========================
local radProtection = 0 -- 0..1 (1 = hazmat, puni imunitet); postavlja je clothing/hazmat skripta
exports('SetRadiationProtection', function(level)
    radProtection = math.max(0, math.min(1, tonumber(level) or 0))
end)

-- vrati najjaču zonu/intenzitet na trenutnoj poziciji (lokalno, iz configa)
local function currentRadField()
    local coords = GetEntityCoords(cache.ped)
    local best = 0
    for i = 1, #config.radiation.zones do
        local z = config.radiation.zones[i]
        if #(coords - z.coords) <= z.radius then
            if z.intensity > best then best = z.intensity end
        end
    end
    return best
end

-- javljaj server-u izloženost
CreateThread(function()
    if not config.radiation.enabled then return end
    while true do
        Wait(config.radiation.tickInterval * 1000)
        if QBX.IsLoggedIn and not playerState.isDead then
            local intensity = currentRadField()
            TriggerServerEvent('qbx_core:server:radTick', {
                inZone = intensity > 0,
                intensity = intensity,
                protection = radProtection,
            })
        end
    end
end)

-- efekti radijacije (muka/distorzija + HP šteta -> DOWNED)
CreateThread(function()
    if not config.radiation.enabled then return end
    local r = config.radiation
    local fxActive = false
    while true do
        local sleep = 4000
        if QBX.IsLoggedIn and not playerState.isDead then
            local rad = playerState.radiation or 0
            if rad >= r.sicknessThreshold then
                if not fxActive then AnimpostfxPlay(r.screenFx, 0, true); fxActive = true end
                if math.random(100) <= r.vomitChance and not IsPedRagdoll(cache.ped) then
                    local a = r.vomitAnim
                    if lib.requestAnimDict(a.dict, 1000) then
                        TaskPlayAnim(cache.ped, a.dict, a.clip, 8.0, -8.0, 4000, 0, 0, false, false, false)
                    end
                end
            elseif fxActive then
                AnimpostfxStop(r.screenFx); fxActive = false
            end

            if rad >= r.damageThreshold then
                local hp = GetEntityHealth(cache.ped)
                if hp > 0 then SetEntityHealth(cache.ped, hp - r.damage) end
                sleep = 3000
            end
        elseif fxActive then
            AnimpostfxStop(r.screenFx); fxActive = false
        end
        Wait(sleep)
    end
end)

-- geiger brojač (toggle); brzina tikanja skalira sa jačinom polja
local geigerOn = false
local function toggleGeiger()
    if not geigerOn then
        if exports.ox_inventory:Search('count', 'geiger') < 1 then
            exports.qbx_core:Notify('Nemaš geiger brojač', 'error')
            return
        end
        geigerOn = true
        exports.qbx_core:Notify('Geiger brojač: UKLJUČEN', 'success')
        CreateThread(function()
            local g = config.radiation.geiger
            while geigerOn do
                local intensity = currentRadField()
                if intensity > 0 and not playerState.isDead then
                    PlaySoundFrontend(-1, g.soundName, g.soundSet, true)
                    -- jači intenzitet = kraći razmak između tikova
                    local ratio = math.min(intensity / 10, 1.0)
                    Wait(math.floor(g.maxInterval - (g.maxInterval - g.minInterval) * ratio))
                else
                    Wait(1500)
                end
            end
        end)
    else
        geigerOn = false
        exports.qbx_core:Notify('Geiger brojač: ISKLJUČEN', 'inform')
    end
end
RegisterCommand('geiger', toggleGeiger, false)
exports('toggleGeiger', toggleGeiger) -- ox_inventory geiger item

-- anti-rad lijek (ox_inventory item -> ovaj export)
exports('useAntiRad', function() TriggerServerEvent('qbx_core:server:antiRad') end)
