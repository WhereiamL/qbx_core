local config = require 'config.clothing'

local worn = {}

local function recomputeStats()
    local warmth, heat, rad = 0, 0, 0
    for _, w in pairs(worn) do
        local s = w.stats or {}
        warmth = warmth + (s.warmth or 0)
        heat = heat + (s.heatPenalty or 0)
        if (s.radProtection or 0) > rad then rad = s.radProtection end
    end
    exports.qbx_core:SetClothingWarmth(warmth)
    exports.qbx_core:SetClothingHeat(heat)
    exports.qbx_core:SetRadiationProtection(rad)
end

local clothingDefs = {}
local function fetchDefs()
    clothingDefs = lib.callback.await('qbx_core:getClothingDefs', false) or {}
end
CreateThread(fetchDefs)

RegisterNetEvent('qbx_core:client:clothingDefUpdated', function(name, def)
    clothingDefs[name] = def
end)

local function getGender()
    return IsPedModel(cache.ped, `mp_f_freemode_01`) and 'female' or 'male'
end

local function currentValue(piece)
    if piece.type == 'prop' then
        return { drawable = GetPedPropIndex(cache.ped, piece.id), texture = GetPedPropTextureIndex(cache.ped, piece.id) }
    end
    return { drawable = GetPedDrawableVariation(cache.ped, piece.id), texture = GetPedTextureVariation(cache.ped, piece.id) }
end

local function applyValue(kind, id, drawable, texture)
    if kind == 'prop' then
        exports['illenium-appearance']:setPedProp(cache.ped, { prop_id = id, drawable = drawable, texture = texture })
    else
        exports['illenium-appearance']:setPedComponent(cache.ped, { component_id = id, drawable = drawable, texture = texture })
    end
end

local function wornList()
    local list = {}
    for name, w in pairs(worn) do list[#list + 1] = { name = name, stats = w.stats } end
    return list
end

local function unequip(name, skipSync)
    local w = worn[name]
    if not w then return end

    for i = #w.pieces, 1, -1 do
        local p = w.pieces[i]
        applyValue(p.type, p.id, p.prev.drawable, p.prev.texture)
    end
    worn[name] = nil
    recomputeStats()
    if not skipSync then TriggerServerEvent('qbx_core:server:syncClothing', wornList()) end
end

local function equip(name, skipSync, stats)
    local def = clothingDefs[name]
    if not def then return end
    local gender = getGender()

    for other, w in pairs(worn) do
        if other ~= name then
            for _, np in ipairs(def.pieces) do
                for _, op in ipairs(w.pieces) do
                    if np.type == op.type and np.id == op.id then
                        unequip(other, true)
                        break
                    end
                end
            end
        end
    end

    local pieces = {}
    for _, piece in ipairs(def.pieces) do
        local v = piece[gender] or piece.male
        if v then
            pieces[#pieces + 1] = { type = piece.type, id = piece.id, prev = currentValue(piece) }
            applyValue(piece.type, piece.id, v.drawable, v.texture)
        end
    end

    worn[name] = { pieces = pieces, stats = stats or def.stats }
    recomputeStats()
    if not skipSync then TriggerServerEvent('qbx_core:server:syncClothing', wornList()) end
end

local function toggle(name, stats)
    if worn[name] then unequip(name) else equip(name, false, stats) end
end

exports('equipClothing', function(data)
    if not data then return end
    local meta = data.metadata
    local name = (meta and meta.clothing) or data.name
    if name then toggle(name, meta and meta.stats) end
end)

RegisterCommand(config.unequipCommand, function()
    for name in pairs(worn) do unequip(name, true) end
    TriggerServerEvent('qbx_core:server:syncClothing', {})
end, false)

RegisterNetEvent('qbx_core:client:reapplyClothing', function(list)
    worn = {}
    if type(list) ~= 'table' then return end
    for _, entry in ipairs(list) do

        if type(entry) == 'string' then
            equip(entry, true)
        elseif type(entry) == 'table' and entry.name then
            equip(entry.name, true, entry.stats)
        end
    end
    recomputeStats()
end)

if config.devCapture then
    RegisterCommand('outfitcapture', function(_, args)
        local name = args[1] or 'novi_item'
        local ped = cache.ped
        local gender = getGender()
        local wantComponents = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
        if args[2] then
            wantComponents = {}
            for i = 2, #args do wantComponents[#wantComponents + 1] = tonumber(args[i]) end
        end

        local pieces = {}
        for _, id in ipairs(wantComponents) do
            if id then
                pieces[#pieces + 1] = { type = 'component', id = id, [gender] = { drawable = GetPedDrawableVariation(ped, id), texture = GetPedTextureVariation(ped, id) } }
            end
        end
        for _, id in ipairs({ 0, 1, 2, 6, 7 }) do
            local d = GetPedPropIndex(ped, id)
            if d ~= -1 then
                pieces[#pieces + 1] = { type = 'prop', id = id, [gender] = { drawable = d, texture = GetPedPropTextureIndex(ped, id) } }
            end
        end

        TriggerServerEvent('qbx_core:server:captureClothing', name, { label = name, pieces = pieces })
    end, false)

    RegisterNetEvent('qbx_core:client:captureDone', function(name)
        exports.qbx_core:Notify(('Odjeća "%s" (%s) sačuvana u clothing.json'):format(name, getGender()), 'success')
    end)
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    fetchDefs()
    SetTimeout(2000, function() TriggerServerEvent('qbx_core:server:requestClothing') end)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and QBX.IsLoggedIn then
        SetTimeout(2000, function() TriggerServerEvent('qbx_core:server:requestClothing') end)
    end
end)
