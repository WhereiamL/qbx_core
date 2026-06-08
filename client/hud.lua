local HUD = {
    mph = false,
    useTemp = true,
    useBlood = true,
    thickIcons = false,
    tick = 200,
}

local ps = LocalPlayer.state
local hudOn = true
local started = false

-- fivez_injuries: izvuci bleeding/fracture/infection iz per-bodypart statebaga
local function scanInjuries()
    local bleeding, fracture, infection = false, false, false
    local inj = ps.injuries
    if type(inj) == 'table' then
        for _, bp in pairs(inj) do
            if type(bp) == 'table' then
                if (bp.bleeding or 0) > 0 then bleeding = true end
                if bp.fracture then fracture = true end
                if (bp.infection or 0) > 0 then infection = true end
            end
        end
    end
    if ps.internalBleeding then bleeding = true end
    return bleeding, fracture, infection
end

local function sendLoaded()
    SendNUIMessage({
        action = 'loaded',
        speedUnit = HUD.mph,
        useTemp = HUD.useTemp,
        useBlood = HUD.useBlood,
        useThickIcons = HUD.thickIcons,
    })
end

local function healthPct(ped)
    local max = GetEntityMaxHealth(ped)
    local base = max > 100 and 100 or 0
    if max <= base then return 0 end
    return math.max(0, math.min(100, math.floor((GetEntityHealth(ped) - base) / (max - base) * 100 + 0.5)))
end

local function voiceLevel()
    local prox = MumbleGetTalkerProximity()
    if prox <= 3.0 then return 1.5 elseif prox <= 8.0 then return 3.0 else return 6.0 end
end

RegisterCommand('hud', function()
    hudOn = not hudOn
    SendNUIMessage({ action = 'hudVisibility', showHud = hudOn })
end, false)

local function startHud()
    if started then return end
    started = true
    sendLoaded()

    CreateThread(function()
        while true do
            Wait(HUD.tick)
            if not ps.isLoggedIn then goto continue end

            if ps.isDead or ps.unconscious then
                SendNUIMessage({ action = 'hudVisibility', showHud = false })
                goto continue
            elseif hudOn then
                SendNUIMessage({ action = 'hudVisibility', showHud = true })
            else
                goto continue
            end

            local ped = cache.ped

            local veh = cache.vehicle
            if veh then
                local mult = HUD.mph and 2.236702 or 3.6
                local fuel = Entity(veh).state.fuel or GetVehicleFuelLevel(veh)
                SendNUIMessage({ action = 'inVehicle', speed = GetEntitySpeed(veh) * mult, fuel = fuel or 0 })
            else
                SendNUIMessage({ action = 'noVehicle', stamina = 100.0 - math.min(100.0, GetPlayerSprintStaminaRemaining(cache.playerId)) })
            end

            local bleeding, fracture, infection = scanInjuries()
            SendNUIMessage({
                action = 'onFoot',
                health = healthPct(ped),
                armor = GetPedArmour(ped),
                hunger = ps.hunger or 100,
                water = ps.thirst or 100,
                temp = ps.temperature or 50,
                blood = ps.blood or 100,
                voice = voiceLevel(),
                talking = NetworkIsPlayerTalking(PlayerId()),
                wetness = ps.wet == true,
                bleeding = bleeding,
                disease = infection,
                illness = (ps.radiation or 0) >= 40,
                brokenbone = fracture,
                digestion = (ps.bowel or 0) >= 80 or (ps.bladder or 0) >= 80,
                overweight = false,
            })

            ::continue::
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', startHud)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if LocalPlayer.state.isLoggedIn then startHud() end
end)
