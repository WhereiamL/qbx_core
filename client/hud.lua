local HUD = { mph = false, tick = 250 }

local ps = LocalPlayer.state
local hudOn = true
local started = false

local PART_LABEL = {
    head = 'Glava', neck = 'Vrat', chest = 'Grudi', stomach = 'Stomak',
    left_arm = 'Lijeva ruka', right_arm = 'Desna ruka',
    left_hand = 'Lijeva šaka', right_hand = 'Desna šaka',
    left_leg = 'Lijeva noga', right_leg = 'Desna noga',
    left_foot = 'Lijevo stopalo', right_foot = 'Desno stopalo',
}

-- fivez_injuries: izvuci status iz per-bodypart statebaga
local function scanInjuries()
    local bleeding, infection, fractures = false, 0, {}
    local inj = ps.injuries
    if type(inj) == 'table' then
        for key, bp in pairs(inj) do
            if type(bp) == 'table' then
                if (bp.bleeding or 0) > 0 then bleeding = true end
                if (bp.infection or 0) > infection then infection = bp.infection end
                if bp.fracture then fractures[#fractures + 1] = PART_LABEL[key] or key end
            end
        end
    end
    if ps.internalBleeding then bleeding = true end
    local fractureLabel
    if #fractures > 0 then
        fractureLabel = fractures[1]
        if #fractures > 1 then fractureLabel = fractureLabel .. ' +' .. (#fractures - 1) end
    end
    return bleeding, math.floor(infection + 0.5), fractureLabel
end

local function healthPct(ped)
    local max = GetEntityMaxHealth(ped)
    local base = max > 100 and 100 or 0
    if max <= base then return 0 end
    return math.max(0, math.min(100, math.floor((GetEntityHealth(ped) - base) / (max - base) * 100 + 0.5)))
end

local function num(v) return math.floor((v or 0) + 0.5) end

RegisterCommand('hud', function()
    hudOn = not hudOn
end, false)

local function startHud()
    if started then return end
    started = true
    SendNUIMessage({ action = 'loaded' })

    CreateThread(function()
        while true do
            Wait(HUD.tick)
            if not ps.isLoggedIn then goto continue end

            if not hudOn or ps.isDead or ps.unconscious then
                SendNUIMessage({ action = 'hud', show = false })
                goto continue
            end

            local ped = cache.ped
            local bleeding, infection, fractureLabel = scanInjuries()
            local temp = num(ps.temperature or 50)

            local veh = cache.vehicle
            local vinfo
            if veh then
                local mult = HUD.mph and 2.236702 or 3.6
                vinfo = { inv = true, speed = num(GetEntitySpeed(veh) * mult), fuel = num(Entity(veh).state.fuel or GetVehicleFuelLevel(veh) or 0) }
            else
                vinfo = { inv = false }
            end

            SendNUIMessage({
                action = 'hud',
                show = true,
                stats = {
                    radiation = num(ps.radiation or 0),
                    temp = temp,
                    tempC = math.floor(-10 + (temp / 100) * 50 + 0.5),
                    health = healthPct(ped),
                    armor = num(GetPedArmour(ped)),
                    blood = num(ps.blood or 100),
                    hunger = num(ps.hunger or 100),
                    thirst = num(ps.thirst or 100),
                    bladder = num(ps.bladder or 0),
                    bowel = num(ps.bowel or 0),
                    stamina = num(100.0 - math.min(100.0, GetPlayerSprintStaminaRemaining(cache.playerId))),
                },
                status = {
                    infection = infection,
                    fracture = fractureLabel,
                    bleeding = bleeding,
                    wetness = ps.wet == true,
                },
                veh = vinfo,
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
