local config = require 'config.clothing'
local CLOTHING_FILE = 'data/clothing.json'

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

local function allDefs()
    local defs = {}
    for name, def in pairs(config.items) do defs[name] = def end
    for name, def in pairs(savedDefs) do defs[name] = def end
    return defs
end

local function persist()
    SaveResourceFile(GetCurrentResourceName(), CLOTHING_FILE, json.encode(savedDefs, { indent = true }), -1)
end

lib.callback.register('qbx_core:getClothingDefs', function()
    return allDefs()
end)

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
    if def.image then meta.imageurl = def.image end
    return meta
end

local function giveClothing(src, defName, count)
    local def = allDefs()[defName]
    if not def then return false end
    local ok = exports.ox_inventory:AddItem(src, config.genericItem, count or 1, buildMeta(defName, def))
    if not ok then
        exports.qbx_core:Notify(src, ('Ne mogu dati "%s" — provjeri da je item "%s" registrovan u inventaru'):format(defName, config.genericItem), 'error')
    end
    return ok
end
exports('GiveClothingItem', giveClothing)

RegisterCommand('giveclothing', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'group.admin') then return end
    local target = tonumber(args[1])
    local defName = args[2]
    if not defName then

        defName = args[1]
        target = src ~= 0 and src or nil
    end
    if not target or not defName then return end
    giveClothing(target, defName, tonumber(args[3]) or 1)
end, true)

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

RegisterNetEvent('qbx_core:server:captureClothing', function(name, def)
    local src = source
    if not config.devCapture then return end
    if config.adminOnly and not IsPlayerAceAllowed(src, 'group.admin') then return end
    if type(name) ~= 'string' or type(def) ~= 'table' or type(def.pieces) ~= 'table' then return end

    local merged = mergeDef(name, def)
    persist()
    TriggerClientEvent('qbx_core:client:clothingDefUpdated', -1, name, merged)
    giveClothing(src, name, 1)
    TriggerClientEvent('qbx_core:client:captureDone', src, name)
end)

local function uniqueName(prefix)
    prefix = (tostring(prefix or 'item'):lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', ''))
    if prefix == '' then prefix = 'item' end
    local n = 1
    while savedDefs[prefix .. '_' .. n] or config.items[prefix .. '_' .. n] do n = n + 1 end
    return prefix .. '_' .. n
end

local function defGender(def)
    local p = def.pieces and def.pieces[1]
    if not p then return nil end
    if p.male then return 'male' elseif p.female then return 'female' end
end

local function defSignature(def, gender)
    local parts, has = {}, false
    for _, p in ipairs(def.pieces or {}) do
        local v = p[gender]
        if v then
            has = true
            parts[#parts + 1] = ('%s:%s:%s:%s'):format(p.type, p.id, v.drawable, v.texture)
        end
    end
    if not has then return nil end
    table.sort(parts)
    return table.concat(parts, '|')
end

local function findDuplicate(def)
    local gender = defGender(def)
    if not gender then return nil end
    local sig = defSignature(def, gender)
    if not sig then return nil end
    for name, ed in pairs(allDefs()) do
        if defSignature(ed, gender) == sig then return name end
    end
end

lib.callback.register('qbx_core:createClothingDef', function(source, prefix, def)
    if not config.addCommand then return false end
    if config.adminOnly and not IsPlayerAceAllowed(source, 'group.admin') then return false end
    if type(def) ~= 'table' or type(def.pieces) ~= 'table' then return false end

    local dup = findDuplicate(def)
    if dup then return dup, true end

    local name = uniqueName(prefix)
    savedDefs[name] = def
    persist()
    TriggerClientEvent('qbx_core:client:clothingDefUpdated', -1, name, def)
    return name, false
end)

local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64map = {}
for i = 1, #B64 do b64map[B64:byte(i)] = i - 1 end

local function b64decode(data)
    data = data:gsub('[^' .. B64 .. ']', '')
    local out, n = {}, #data
    local pad = 0
    for i = 1, n, 4 do
        local c1 = b64map[data:byte(i)] or 0
        local c2 = b64map[data:byte(i + 1)] or 0
        local c3 = b64map[data:byte(i + 2)] or 0
        local c4 = b64map[data:byte(i + 3)] or 0
        local v = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
        out[#out + 1] = string.char(math.floor(v / 65536) % 256, math.floor(v / 256) % 256, v % 256)
    end
    local res = table.concat(out)
    local rem = n % 4
    if rem == 2 then res = res:sub(1, #res - 2)
    elseif rem == 3 then res = res:sub(1, #res - 1) end
    return res
end

RegisterNetEvent('qbx_core:server:saveClothingImage', function(name, b64)
    local src = source
    if not config.addCommand then return end
    if config.adminOnly and not IsPlayerAceAllowed(src, 'group.admin') then return end
    if type(name) ~= 'string' or type(b64) ~= 'string' or b64 == '' then return end

    local png = b64decode(b64)
    local res = GetCurrentResourceName()
    local saved = SaveResourceFile(res, ('images/%s.png'):format(name), png, #png)
    if saved == false or #png == 0 then
        exports.qbx_core:Notify(src, ('Slika nije zapisana (duzina %d)'):format(#png), 'error')
    end

    if savedDefs[name] then
        savedDefs[name].image = ('https://cfx-nui-%s/images/%s.png'):format(res, name)
        persist()
        TriggerClientEvent('qbx_core:client:clothingDefUpdated', -1, name, savedDefs[name])
    end

    giveClothing(src, name, 1)
    TriggerClientEvent('qbx_core:client:captureDone', src, name)
end)

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
