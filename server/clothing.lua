local config = require 'config.clothing'
local CLOTHING_FILE = 'data/clothing.json'

-- definicije snimljene preko /outfitcapture (samo one idu u json; config je odvojen)
local savedDefs = {}

local function loadSaved()
    savedDefs = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), CLOTHING_FILE)
    if raw and raw ~= '' then
        local ok, parsed = pcall(json.decode, raw)
        if ok and type(parsed) == 'table' then savedDefs = parsed end
    end
end
loadSaved()

-- config.items + savedDefs (json override-uje config kod istog imena)
local function allDefs()
    local defs = {}
    for name, def in pairs(config.items) do defs[name] = def end
    for name, def in pairs(savedDefs) do defs[name] = def end
    return defs
end

local function persist()
    SaveResourceFile(GetCurrentResourceName(), CLOTHING_FILE, json.encode(savedDefs, { indent = true }), -1)
end

-- klijent traži sve definicije (za equip)
lib.callback.register('qbx_core:getClothingDefs', function()
    return allDefs()
end)

-- izgradi metadata + opis za generički 'clothing' item
local function statDesc(stats)
    stats = stats or {}
    local lines = {}
    if (stats.warmth or 0) ~= 0 then lines[#lines + 1] = ('Toplina: +%s'):format(stats.warmth) end
    if (stats.heatPenalty or 0) ~= 0 then lines[#lines + 1] = ('Pregrijavanje (vruće zone): +%s'):format(stats.heatPenalty) end
    if (stats.radProtection or 0) > 0 then lines[#lines + 1] = ('Zaštita od radijacije: %d%%'):format(math.floor(stats.radProtection * 100 + 0.5)) end
    return table.concat(lines, '\n')
end

local function buildMeta(defName, def)
    local meta = {
        clothing = defName,
        label = def.label or defName,
        description = statDesc(def.stats),
        stats = def.stats,
    }
    if def.image then meta.imageurl = def.image end -- custom slika po komadu (URL ili putanja)
    return meta
end

-- daj igraču generički clothing item s metadatom date definicije
local function giveClothing(src, defName, count)
    local def = allDefs()[defName]
    if not def then return false end
    return exports.ox_inventory:AddItem(src, config.genericItem, count or 1, buildMeta(defName, def))
end
exports('GiveClothingItem', giveClothing)

-- admin: /giveclothing [serverId] <defName> [count]  (konzola: serverId obavezan)
RegisterCommand('giveclothing', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'group.admin') then return end
    local target = tonumber(args[1])
    local defName = args[2]
    if not defName then
        -- /giveclothing <defName> -> sebi (samo igrač)
        defName = args[1]
        target = src ~= 0 and src or nil
    end
    if not target or not defName then return end
    giveClothing(target, defName, tonumber(args[3]) or 1)
end, true)

-- spoji novu (per-gender) varijantu u postojeću definiciju
local function mergeDef(name, def)
    local existing = savedDefs[name]
    if not (existing and existing.pieces) then
        savedDefs[name] = def
        return savedDefs[name]
    end
    for _, np in ipairs(def.pieces) do
        local found
        for _, op in ipairs(existing.pieces) do
            if op.type == np.type and op.id == np.id then found = op break end
        end
        if found then
            for k, v in pairs(np) do
                if k ~= 'type' and k ~= 'id' then found[k] = v end
            end
        else
            existing.pieces[#existing.pieces + 1] = np
        end
    end
    if def.radProtection then existing.radProtection = def.radProtection end
    return existing
end

-- DEV: capture (auto-save u json). Samo admin + devCapture.
RegisterNetEvent('qbx_core:server:captureClothing', function(name, def)
    local src = source
    if not config.devCapture then return end
    if not IsPlayerAceAllowed(src, 'group.admin') then return end
    if type(name) ~= 'string' or type(def) ~= 'table' or type(def.pieces) ~= 'table' then return end

    local merged = mergeDef(name, def)
    persist()
    TriggerClientEvent('qbx_core:client:clothingDefUpdated', -1, name, merged) -- live svima
    giveClothing(src, name, 1) -- odmah daj nosivi item za test
    TriggerClientEvent('qbx_core:client:captureDone', src, name)
end)

-- ===== trajno čuvanje OBUČENE odjeće po igraču (metadata wornClothing) =====
RegisterNetEvent('qbx_core:server:syncClothing', function(list)
    local src = source
    if type(list) ~= 'table' then return end
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        player.Functions.SetMetaData('wornClothing', list)
    end
end)

RegisterNetEvent('qbx_core:server:requestClothing', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local list = player and player.PlayerData.metadata.wornClothing or {}
    TriggerClientEvent('qbx_core:client:reapplyClothing', src, list)
end)
