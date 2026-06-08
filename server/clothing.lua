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
