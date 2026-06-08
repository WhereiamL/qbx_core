local config = require 'config.clothing'
if not config.equip then return end

local SLOTS = config.equip.slots
local SLOTCOUNT = #SLOTS
local PREFIX = 'fivez_clothing:'

local function stashId(cid) return PREFIX .. cid end

local function cidOf(src)
    local p = exports.qbx_core:GetPlayer(src)
    return p and p.PlayerData.citizenid
end

local function registerFor(cid)
    exports.ox_inventory:RegisterStash(stashId(cid), 'Odjeća', SLOTCOUNT, 200000, false)
end

local function defMatchesSlot(def, idx)
    local s = SLOTS[idx]
    if not s or not def or not def.pieces then return false end
    for _, p in ipairs(def.pieces) do
        if p.type == s.type and p.id == s.id then return true end
    end
    return false
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local cid = cidOf(src)
    if not cid then return end
    registerFor(cid)
    SetTimeout(4000, function()
        local items = exports.ox_inventory:GetInventoryItems(stashId(cid))
        if not items then return end
        for _, item in pairs(items) do
            if item.metadata and item.metadata.clothing then
                TriggerClientEvent('qbx_core:client:equipDef', src, item.metadata.clothing)
            end
        end
    end)
end)

RegisterNetEvent('qbx_core:server:openClothing', function()
    local src = source
    local cid = cidOf(src)
    if not cid then return end
    registerFor(cid)
    exports.ox_inventory:forceOpenInventory(src, 'stash', stashId(cid))
end)

local function isCloth(id)
    return type(id) == 'string' and id:sub(1, #PREFIX) == PREFIX
end

exports.ox_inventory:registerHook('swapItems', function(payload)
    local toCloth = isCloth(payload.toInventory)
    local fromCloth = isCloth(payload.fromInventory)
    if not toCloth and not fromCloth then return true end

    local src = payload.source
    local moving = payload.fromSlot

    if toCloth then
        if not moving or moving.name ~= config.genericItem then return false end
        local defName = moving.metadata and moving.metadata.clothing
        local def = defName and exports.qbx_core:GetClothingDef(defName)
        if not def then return false end
        local idx = type(payload.toSlot) == 'number' and payload.toSlot or (type(payload.toSlot) == 'table' and payload.toSlot.slot)
        if idx and not defMatchesSlot(def, idx) then
            TriggerClientEvent('qbx_core:client:clothNotify', src, 'Pogrešan slot za ovaj komad')
            return false
        end
        TriggerClientEvent('qbx_core:client:equipDef', src, defName)
        return true
    end

    if fromCloth then
        local defName = moving and moving.metadata and moving.metadata.clothing
        if defName then TriggerClientEvent('qbx_core:client:unequipDef', src, defName) end
        return true
    end

    return true
end)
