local config = require 'config.server'

-- How many players to process before yielding a frame. Spreads the per-interval
-- work (DB saves, paychecks, client syncs) across ticks so a full server doesn't
-- hitch when every loop fires on the same frame.
local PLAYERS_PER_BATCH = 20

---Iterates online players, yielding every PLAYERS_PER_BATCH to keep ticks smooth.
---Snapshots sources up front so yielding can't corrupt iteration when players
---join or drop mid-pass, and re-validates each player after the wait.
---@param handler fun(src: Source, player: Player)
local function forEachPlayerStaggered(handler)
    local sources = {}
    for src in pairs(QBX.Players) do
        sources[#sources + 1] = src
    end

    for i = 1, #sources do
        local src = sources[i]
        local player = QBX.Players[src]
        if player then
            handler(src, player)
        end
        if i % PLAYERS_PER_BATCH == 0 then
            Wait(0)
        end
    end
end

local function removeHungerAndThirst(src, player)
    local playerState = Player(src).state
    if not playerState.isLoggedIn then return end
    local newHunger = playerState.hunger - config.player.hungerRate
    local newThirst = playerState.thirst - config.player.thirstRate

    player.Functions.SetMetaData('thirst', math.max(0, newThirst))
    player.Functions.SetMetaData('hunger', math.max(0, newHunger))

    player.Functions.Save()
end

CreateThread(function()
    local interval = 60000 * config.updateInterval
    while true do
        Wait(interval)
        forEachPlayerStaggered(removeHungerAndThirst)
    end
end)

local function pay(player)
    local job = player.PlayerData.job
    local payment = GetJob(job.name).grades[job.grade.level].payment or job.payment
    if payment <= 0 then return end
    if not GetJob(job.name).offDutyPay and not job.onduty then return end
    if not config.money.paycheckSociety then
        config.sendPaycheck(player, payment)
        return
    end
    local account = config.getSocietyAccount(job.name)
    if not account then -- Checks if player is employed by a society
        config.sendPaycheck(player, payment)
        return
    end
    if account < payment then -- Checks if company has enough money to pay society
        Notify(player.PlayerData.source, locale('error.company_too_poor'), 'error')
        return
    end
    config.removeSocietyMoney(job.name, payment)
    config.sendPaycheck(player, payment)
end

CreateThread(function()
    local interval = 60000 * config.money.paycheckTimeout
    while true do
        Wait(interval)
        forEachPlayerStaggered(function(_, player)
            pay(player)
        end)
    end
end)
