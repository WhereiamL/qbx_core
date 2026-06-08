local config = require 'config.clothing'
if not config.addCommand then return end

local function getGender()
    return IsPedModel(cache.ped, `mp_f_freemode_01`) and 'female' or 'male'
end

-- napravi filename/def-safe ime
local function sanitize(name)
    return (name:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', ''))
end

-- parsiraj "11,4,p0" -> lista {type,id}
local function parseSlots(str)
    local slots = {}
    for token in (str or ''):gmatch('[^,%s]+') do
        if token:sub(1, 1):lower() == 'p' then
            local id = tonumber(token:sub(2))
            if id then slots[#slots + 1] = { type = 'prop', id = id } end
        else
            local id = tonumber(token)
            if id then slots[#slots + 1] = { type = 'component', id = id } end
        end
    end
    return slots
end

-- izgradi pieces iz trenutnog izgleda za date slotove
local function buildPieces(slots, gender)
    local ped = cache.ped
    local pieces = {}
    for _, s in ipairs(slots) do
        if s.type == 'prop' then
            local d = GetPedPropIndex(ped, s.id)
            if d ~= -1 then
                pieces[#pieces + 1] = { type = 'prop', id = s.id, [gender] = { drawable = d, texture = GetPedPropTextureIndex(ped, s.id) } }
            end
        else
            pieces[#pieces + 1] = { type = 'component', id = s.id, [gender] = { drawable = GetPedDrawableVariation(ped, s.id), texture = GetPedTextureVariation(ped, s.id) } }
        end
    end
    return pieces
end

-- camera preset za prvi (frame) slot
local function frameInfo(slot)
    local cam = config.greenScreen.camera
    if slot.type == 'prop' then return cam.prop[slot.id] or cam.default end
    return cam.component[slot.id] or cam.default
end

-- ============== GENERATOR SLIKE (greenscreen + screenshot-basic) ==============
local function generateImage(name, slots)
    local gs = config.greenScreen
    if GetResourceState('screenshot-basic') ~= 'started' then
        exports.qbx_core:Notify('screenshot-basic nije pokrenut — slika preskočena', 'error')
        return
    end

    local info = frameInfo(slots[1])
    local capturedComp, capturedProp = {}, {}
    for _, s in ipairs(slots) do
        if s.type == 'prop' then capturedProp[s.id] = true else capturedComp[s.id] = true end
    end

    DoScreenFadeOut(400)
    Wait(450)

    -- skloni igrača da klon može renderovati
    local backCoords = GetEntityCoords(cache.ped)
    local backHeading = GetEntityHeading(cache.ped)
    FreezeEntityPosition(cache.ped, true)
    SetEntityCoordsNoOffset(cache.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)

    if not lib.requestModel(gs.model, 5000) then
        SetEntityCoordsNoOffset(cache.ped, backCoords.x, backCoords.y, backCoords.z, false, false, false)
        FreezeEntityPosition(cache.ped, false)
        DoScreenFadeIn(400)
        exports.qbx_core:Notify('Green box model nije učitan (provjeri stream)', 'error')
        return
    end
    local modelHash = joaat(gs.model)
    local box = CreateObject(modelHash, gs.position.x, gs.position.y, gs.position.z, false, false, false)
    SetEntityHeading(box, gs.heading)
    FreezeEntityPosition(box, true)

    -- klon nosi trenutni izgled; sakrij sve osim uhvaćenih komada
    local clone = ClonePed(cache.ped, false, false, true)
    SetEntityCoordsNoOffset(clone, gs.position.x, gs.position.y, gs.position.z, false, false, false)
    for _, c in ipairs({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 }) do
        if not capturedComp[c] then SetPedComponentVariation(clone, c, -1, 0, 0) end
    end
    for _, p in ipairs({ 0, 1, 2, 6, 7 }) do
        if not capturedProp[p] then ClearPedProp(clone, p) end
    end
    SetEntityRotation(clone, 0.0, 0.0, info.rz, 2, false)
    FreezeEntityPosition(clone, true)
    SetEntityInvincible(clone, true)
    SetEntityCollision(clone, false, false)

    -- konzistentno svjetlo
    NetworkOverrideClockTime(12, 0, 0)
    RequestCollisionAtCoord(gs.position.x, gs.position.y, gs.position.z)
    Wait(300)

    -- kamera: 1.2m ispred peda (replika fivem-greenscreener)
    local coords = GetEntityCoords(clone)
    local fwd = GetEntityForwardVector(clone)
    local dist = gs.camDistance
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        coords.x + fwd.x * dist, coords.y + fwd.y * dist, coords.z + fwd.z + info.zPos,
        0.0, 0.0, 0.0, info.fov, true, 0)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + info.zPos)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)

    -- sakrij HUD nekoliko frejmova pa slikaj
    for _ = 1, 30 do
        HideHudAndRadarThisFrame()
        Wait(0)
    end

    exports['screenshot-basic']:requestScreenshot({ encoding = 'png', quality = 1.0 }, function(data)
        -- cleanup
        RenderScriptCams(false, false, 0, true, false, 0)
        DestroyCam(cam, false)
        if DoesEntityExist(clone) then DeleteEntity(clone) end
        if DoesEntityExist(box) then DeleteEntity(box) end
        SetModelAsNoLongerNeeded(modelHash)
        NetworkClearClockTimeOverride()

        SetEntityCoordsNoOffset(cache.ped, backCoords.x, backCoords.y, backCoords.z, false, false, false)
        SetEntityHeading(cache.ped, backHeading)
        FreezeEntityPosition(cache.ped, false)
        DoScreenFadeIn(500)

        if data then
            SendNUIMessage({
                action = 'process',
                name = name,
                image = data,
                size = gs.imageSize,
                chroma = gs.chroma,
                resource = GetCurrentResourceName(),
            })
        else
            exports.qbx_core:Notify('Screenshot nije uspio', 'error')
        end
    end)
end

-- NUI vrati obrađenu (chroma-key + crop + resize) sliku
RegisterNUICallback('clothingImageDone', function(data, cb)
    if data and data.name and data.image then
        TriggerServerEvent('qbx_core:server:saveClothingImage', data.name, data.image)
        exports.qbx_core:Notify(('Slika "%s" sačuvana u ox_inventory'):format(data.name), 'success')
    end
    cb('ok')
end)

-- ===================== /dodaj : meni + spremanje =====================
RegisterCommand(config.addCommand, function()
    local input = lib.inputDialog('Dodaj odjeću', {
        { type = 'input',  label = 'Naziv',          description = 'Jedinstveno ime (mala slova/_)', required = true },
        { type = 'input',  label = 'Komponente',     description = 'npr. 11 (jakna), 11,4,6 (outfit), p0 (kapa)', default = '11', required = true },
        { type = 'number', label = 'Toplina',        description = 'Grije na hladnoći (0 = ništa)', default = 0, min = 0 },
        { type = 'number', label = 'Pregrijavanje',  description = 'Diže temp u vrućim zonama (0 = ništa)', default = 0, min = 0 },
        { type = 'slider', label = 'Zaštita od radijacije (%)', default = 0, min = 0, max = 100 },
    })
    if not input then return end

    local name = sanitize(input[1])
    if name == '' then exports.qbx_core:Notify('Neispravan naziv', 'error') return end
    local gender = getGender()
    local slots = parseSlots(input[2])
    if #slots == 0 then exports.qbx_core:Notify('Nisi naveo komponente', 'error') return end

    local pieces = buildPieces(slots, gender)
    local stats = {
        warmth = input[3] or 0,
        heatPenalty = input[4] or 0,
        radProtection = (input[5] or 0) / 100,
    }

    -- snimi definiciju (bez davanja itema — item se da nakon slike)
    TriggerServerEvent('qbx_core:server:saveClothingDef', name, { label = input[1], pieces = pieces, stats = stats })
    exports.qbx_core:Notify(('Pravim sliku za "%s" (%s)...'):format(name, gender), 'inform')
    generateImage(name, slots)
end, false)
