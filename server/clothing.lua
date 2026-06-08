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
    if def.stats then existing.stats = def.stats end
    if def.label then existing.label = def.label end
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

-- ===================== /dodaj : definicija + slika =====================
-- snimi def (bez davanja itema; item se da nakon što slika stigne)
RegisterNetEvent('qbx_core:server:saveClothingDef', function(name, def)
    local src = source
    if not config.addCommand then return end
    if not IsPlayerAceAllowed(src, 'group.admin') then return end
    if type(name) ~= 'string' or type(def) ~= 'table' or type(def.pieces) ~= 'table' then return end
    local merged = mergeDef(name, def)
    persist()
    TriggerClientEvent('qbx_core:client:clothingDefUpdated', -1, name, merged)
end)

-- base64 dekoder (za PNG iz NUI canvasa)
local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64decode(data)
    data = data:gsub('[^' .. B64 .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (B64:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- primi obrađenu sliku, upiši u ox_inventory/web/images i daj item
RegisterNetEvent('qbx_core:server:saveClothingImage', function(name, b64)
    local src = source
    if not config.addCommand then return end
    if not IsPlayerAceAllowed(src, 'group.admin') then return end
    if type(name) ~= 'string' or type(b64) ~= 'string' or b64 == '' then return end

    local png = b64decode(b64)
    SaveResourceFile('ox_inventory', ('web/images/%s.png'):format(name), png, -1)

    -- zapamti lokalnu sliku u definiciji (za metadata.imageurl)
    if savedDefs[name] then
        savedDefs[name].image = ('nui://ox_inventory/web/images/%s.png'):format(name)
        persist()
        TriggerClientEvent('qbx_core:client:clothingDefUpdated', -1, name, savedDefs[name])
    end

    giveClothing(src, name, 1) -- sad daj item (metadata ima sliku)
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
