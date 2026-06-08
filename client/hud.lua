local playerState = LocalPlayer.state
local prev = {}
local shown = false

-- trend: 1 raste, -1 pada, 0 mirno
local function trend(key, value)
    local p = prev[key]
    prev[key] = value
    if p == nil then return 0 end
    if value > p + 0.3 then return 1 elseif value < p - 0.3 then return -1 end
    return 0
end

local function healthPct(ped)
    local max = GetEntityMaxHealth(ped)
    local hp = GetEntityHealth(ped)
    local base = max > 100 and 100 or 0
    if max <= base then return 0 end
    return math.max(0, math.min(100, math.floor((hp - base) / (max - base) * 100 + 0.5)))
end

CreateThread(function()
    while true do
        Wait(300)
        local show = QBX.IsLoggedIn and not playerState.isDead and not IsPauseMenuActive()
        if show then
            shown = true
            local ped = cache.ped
            -- GetPlayerSprintStaminaRemaining: 0 = puna, ~100 = iscrpljena -> obrni
            local stamina = 100.0 - math.min(100.0, GetPlayerSprintStaminaRemaining(cache.playerId))
            local hp = healthPct(ped)
            local armor = GetPedArmour(ped)
            local hunger = playerState.hunger or 100
            local thirst = playerState.thirst or 100
            local temp = playerState.temperature or 50
            local bladder = playerState.bladder or 0
            local bowel = playerState.bowel or 0
            local rad = playerState.radiation or 0

            SendNUIMessage({
                action = 'hud',
                show = true,
                stats = {
                    health = { v = hp, t = trend('health', hp) },
                    armor = { v = armor, t = trend('armor', armor) },
                    hunger = { v = hunger, t = trend('hunger', hunger) },
                    thirst = { v = thirst, t = trend('thirst', thirst) },
                    temperature = { v = temp, t = trend('temperature', temp) },
                    bladder = { v = bladder, t = trend('bladder', bladder) },
                    bowel = { v = bowel, t = trend('bowel', bowel) },
                    radiation = { v = rad, t = trend('radiation', rad) },
                    stamina = { v = stamina, t = 0 },
                },
            })
        elseif shown then
            shown = false
            SendNUIMessage({ action = 'hud', show = false })
        end
    end
end)
