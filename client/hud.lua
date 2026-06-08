local HUD = { mph = false, tick = 250 }

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
            local bleeding, fracture, infection = scanInjuries()

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
                    health = healthPct(ped),
                    armor = num(GetPedArmour(ped)),
                    blood = num(ps.blood or 100),
                    hunger = num(ps.hunger or 100),
                    thirst = num(ps.thirst or 100),
                    temp = num(ps.temperature or 50),
                    bladder = num(ps.bladder or 0),
                    bowel = num(ps.bowel or 0),
                    radiation = num(ps.radiation or 0),
                    stamina = num(100.0 - math.min(100.0, GetPlayerSprintStaminaRemaining(cache.playerId))),
                },
                debuffs = { bleeding = bleeding, fracture = fracture, disease = infection, wetness = ps.wet == true },
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
