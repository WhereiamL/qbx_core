local config = require 'config.clothing'

-- obučeni predmeti: [itemName] = { pieces = { {type,id,prev={drawable,texture}}... }, radProtection }
local worn = {}

-- definicije odjeće (config + data/clothing.json), dolaze sa servera
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
    for name in pairs(worn) do list[#list + 1] = name end
    return list
end

local function unequip(name, skipSync)
    local w = worn[name]
    if not w then return end
    -- vrati slotove u prethodno stanje (obrnutim redom)
    for i = #w.pieces, 1, -1 do
        local p = w.pieces[i]
        applyValue(p.type, p.id, p.prev.drawable, p.prev.texture)
    end
    if w.radProtection then exports.qbx_core:SetRadiationProtection(0) end
    worn[name] = nil
    if not skipSync then TriggerServerEvent('qbx_core:server:syncClothing', wornList()) end
end

local function equip(name, skipSync)
    local def = clothingDefs[name]
    if not def then return end
    local gender = getGender()

    -- skini sve što već zauzima iste slotove (npr. druga jakna)
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
    worn[name] = { pieces = pieces, radProtection = def.radProtection }
    if def.radProtection then exports.qbx_core:SetRadiationProtection(def.radProtection) end
    if not skipSync then TriggerServerEvent('qbx_core:server:syncClothing', wornList()) end
end

local function toggle(name)
    if worn[name] then unequip(name) else equip(name) end
end

-- ox_inventory: item sa client.export = 'qbx_core.equipClothing' (consume = 0)
exports('equipClothing', function(data)
    if data and data.name then toggle(data.name) end
end)

-- skini svu obučenu item-odjeću
RegisterCommand(config.unequipCommand, function()
    for name in pairs(worn) do unequip(name, true) end
    TriggerServerEvent('qbx_core:server:syncClothing', {})
end, false)

-- ponovo obuci sačuvano (poslije reapply-a osnovnog izgleda na loginu/restartu)
RegisterNetEvent('qbx_core:client:reapplyClothing', function(list)
    worn = {}
    if type(list) ~= 'table' then return end
    for _, name in ipairs(list) do
        equip(name, true) -- prev se uzima iz tek primijenjenog osnovnog izgleda
    end
end)

-- DEV alat: obuci se u illenium-u pa /outfitcapture <ime_itema> [id...] -> ispiše config-snippet
-- Bez id-eva ispiše sve komponente; sa id-evima samo te (npr. /outfitcapture jakna 11).
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
        -- server spaja varijante (capture-uj isti item na M pa na Ž da imaš oba spola) i snima u json
        TriggerServerEvent('qbx_core:server:captureClothing', name, { label = name, pieces = pieces })
    end, false)

    RegisterNetEvent('qbx_core:client:captureDone', function(name)
        exports.qbx_core:Notify(('Odjeća "%s" (%s) sačuvana u clothing.json'):format(name, getGender()), 'success')
    end)
end

-- traži sačuvanu odjeću kad se igrač učita (illenium do tad postavi osnovni izgled)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    fetchDefs()
    SetTimeout(2000, function() TriggerServerEvent('qbx_core:server:requestClothing') end)
end)

-- restart resursa dok je igrač online
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and QBX.IsLoggedIn then
        SetTimeout(2000, function() TriggerServerEvent('qbx_core:server:requestClothing') end)
    end
end)
