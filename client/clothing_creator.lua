local config = require 'config.clothing'
if not config.addCommand then return end

local function getGender()
    return IsPedModel(cache.ped, `mp_f_freemode_01`) and 'female' or 'male'
end

local SLOT_TYPES = {
    { value = 'jakna',      label = 'Jakna',         comps = '11' },
    { value = 'majica',     label = 'Majica',        comps = '11' },
    { value = 'undershirt', label = 'Majica ispod',  comps = '8' },
    { value = 'pantalone',  label = 'Pantalone',     comps = '4' },
    { value = 'obuca',      label = 'Obuća',         comps = '6' },
    { value = 'maska',      label = 'Maska',         comps = '1' },
    { value = 'kapa',       label = 'Kapa/Šešir',    comps = 'p0' },
    { value = 'naocale',    label = 'Naočale',       comps = 'p1' },
    { value = 'pancir',     label = 'Pancir/Prsluk', comps = '9' },
    { value = 'torba',      label = 'Torba/Ranac',   comps = '5' },
    { value = 'rukavice',   label = 'Rukavice',      comps = '3' },
    { value = 'outfit',     label = 'Cijeli outfit', comps = '11,4,6,8' },
}

local OUTFIT_SLOTS = {
    { type = 'component', id = 11, prefix = 'jakna',     label = 'Jakna' },
    { type = 'component', id = 8,  prefix = 'majica',    label = 'Majica' },
    { type = 'component', id = 4,  prefix = 'pantalone', label = 'Pantalone' },
    { type = 'component', id = 6,  prefix = 'obuca',     label = 'Obuća' },
    { type = 'component', id = 1,  prefix = 'maska',     label = 'Maska' },
    { type = 'component', id = 9,  prefix = 'pancir',    label = 'Pancir' },
    { type = 'component', id = 5,  prefix = 'torba',     label = 'Torba' },
    { type = 'prop',      id = 0,  prefix = 'kapa',      label = 'Kapa' },
    { type = 'prop',      id = 1,  prefix = 'naocale',   label = 'Naočale' },
}
local OPTIONAL = { [1] = true, [5] = true, [9] = true }

local function findType(value)
    for _, t in ipairs(SLOT_TYPES) do
        if t.value == value then return t end
    end
end

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

local function expandTextures(targets, gender)
    local out = {}
    for _, t in ipairs(targets) do
        local piece = #t.pieces == 1 and t.pieces[1] or nil
        local v = piece and (piece[gender] or piece.male)
        local n = 0
        if v then
            n = piece.type == 'prop'
                and GetNumberOfPedPropTextureVariations(cache.ped, piece.id, v.drawable)
                or GetNumberOfPedTextureVariations(cache.ped, piece.id, v.drawable)
        end
        if not v or n <= 1 then
            out[#out + 1] = t
        else
            for tex = 0, n - 1 do
                out[#out + 1] = {
                    prefix = t.prefix, label = t.label, slot = t.slot, stats = t.stats,
                    pieces = { { type = piece.type, id = piece.id, [gender] = { drawable = v.drawable, texture = tex } } },
                }
            end
        end
    end
    return out
end

local function frameInfo(slot)
    local cam = config.greenScreen.camera
    if slot.type == 'prop' then return cam.prop[slot.id] or cam.default end
    return cam.component[slot.id] or cam.default
end

local nuiPromise
RegisterNUICallback('clothingImageDone', function(data, cb)
    if data and data.name and data.image then
        TriggerServerEvent('qbx_core:server:saveClothingImage', data.name, data.image)
    end
    if nuiPromise then nuiPromise:resolve(true) end
    cb('ok')
end)

local function processImage(name, raw, bg)
    nuiPromise = promise.new()
    SendNUIMessage({
        action = 'process',
        name = name,
        image = raw,
        bg = bg,
        size = config.greenScreen.imageSize,
        chroma = config.greenScreen.chroma,
        diffThreshold = config.greenScreen.diffThreshold or 38,
        resource = GetCurrentResourceName(),
    })
    Citizen.Await(nuiPromise)
    nuiPromise = nil
end

local function takeShot()
    local p = promise.new()
    local res = config.greenScreen.screenshotResource or 'screenshot-basic'
    exports[res]:requestScreenshot({ encoding = 'png', quality = 1.0 }, function(data) p:resolve(data) end)
    return Citizen.Await(p)
end

local function isolateOnClone(clone, pieces, gender)
    for _, c in ipairs({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11 }) do SetPedComponentVariation(clone, c, -1, 0, 0) end
    for _, p in ipairs({ 0, 1, 2, 6, 7 }) do ClearPedProp(clone, p) end
    for _, piece in ipairs(pieces) do
        local v = piece[gender] or piece.male
        if v then
            if piece.type == 'prop' then
                SetPedPropIndex(clone, piece.id, v.drawable, v.texture, true)
            else
                SetPedComponentVariation(clone, piece.id, v.drawable, v.texture, 0)
            end
        end
    end
end

local function captureBatch(targets, gender)
    local gs = config.greenScreen
    local res = gs.screenshotResource or 'screenshot-basic'
    if GetResourceState(res) ~= 'started' then
        exports.qbx_core:Notify(res .. ' nije pokrenut — slika preskočena', 'error')
        return
    end
    local method = gs.method or 'diff'

    DoScreenFadeOut(400)
    Wait(450)

    local backCoords = GetEntityCoords(cache.ped)
    local backHeading = GetEntityHeading(cache.ped)
    FreezeEntityPosition(cache.ped, true)
    SetEntityCoordsNoOffset(cache.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)

    local box, modelHash
    if method == 'chroma' then
        modelHash = joaat(gs.model)
        if not IsModelValid(modelHash) or not lib.requestModel(gs.model, 5000) then
            SetEntityCoordsNoOffset(cache.ped, backCoords.x, backCoords.y, backCoords.z, false, false, false)
            FreezeEntityPosition(cache.ped, false)
            DoScreenFadeIn(400)
            exports.qbx_core:Notify(('Model "%s" nije streaman — prebaci na method=diff'):format(gs.model), 'error')
            return
        end
        box = CreateObject(modelHash, gs.position.x, gs.position.y, gs.position.z, false, false, false)
        SetEntityHeading(box, gs.heading)
        FreezeEntityPosition(box, true)
    end

    local clone = ClonePed(cache.ped, false, false, true)
    SetEntityCoordsNoOffset(clone, gs.position.x, gs.position.y, gs.position.z, false, false, false)
    FreezeEntityPosition(clone, true)
    SetEntityInvincible(clone, true)
    SetEntityCollision(clone, false, false)

    NetworkOverrideClockTime(12, 0, 0)
    RequestCollisionAtCoord(gs.position.x, gs.position.y, gs.position.z)
    Wait(300)

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0, true, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)

    local done = 0
    for _, tgt in ipairs(targets) do
        local info = frameInfo(tgt.slot)
        isolateOnClone(clone, tgt.pieces, gender)
        SetEntityRotation(clone, 0.0, 0.0, info.rz, 2, false)
        Wait(60)

        local coords = GetEntityCoords(clone)
        local fwd = GetEntityForwardVector(clone)
        SetCamCoord(cam, coords.x + fwd.x * gs.camDistance, coords.y + fwd.y * gs.camDistance, coords.z + fwd.z + info.zPos)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + info.zPos)
        SetCamFov(cam, info.fov)

        for _ = 1, 12 do HideHudAndRadarThisFrame() Wait(0) end

        if method == 'diff' then
            SetEntityVisible(clone, false, false)
            for _ = 1, 6 do HideHudAndRadarThisFrame() Wait(0) end
            local bg = takeShot()
            SetEntityVisible(clone, true, false)
            for _ = 1, 6 do HideHudAndRadarThisFrame() Wait(0) end
            local fg = takeShot()
            if fg and bg then processImage(tgt.name, fg, bg) done = done + 1 end
        else
            local raw = takeShot()
            if raw then processImage(tgt.name, raw) done = done + 1 end
        end
    end

    RenderScriptCams(false, false, 0, true, false, 0)
    DestroyCam(cam, false)
    if DoesEntityExist(clone) then DeleteEntity(clone) end
    if box and DoesEntityExist(box) then DeleteEntity(box) end
    if modelHash then SetModelAsNoLongerNeeded(modelHash) end
    NetworkClearClockTimeOverride()

    SetEntityCoordsNoOffset(cache.ped, backCoords.x, backCoords.y, backCoords.z, false, false, false)
    SetEntityHeading(cache.ped, backHeading)
    FreezeEntityPosition(cache.ped, false)
    DoScreenFadeIn(500)

    exports.qbx_core:Notify(('Gotovo — napravljeno %d komada'):format(done), 'success')
end

RegisterCommand(config.addCommand, function()
    local typeOptions = {}
    for _, t in ipairs(SLOT_TYPES) do
        typeOptions[#typeOptions + 1] = { value = t.value, label = t.label }
    end

    local input = lib.inputDialog('Dodaj odjeću', {
        { type = 'select', label = 'Tip odjeće', options = typeOptions, default = 'jakna', required = true },
        { type = 'input',  label = 'Naziv (prikaz)', description = 'Prazno = koristi tip. Kod outfita se ignoriše (svaki komad svoj naziv).' },
        { type = 'input',  label = 'Komponente (napredno)', description = 'Override, npr. 11,4,6 ili p0. Prazno = po tipu' },
        { type = 'number', label = 'Toplina', description = 'Grije na hladnoći (0 = ništa)', default = 0, min = 0 },
        { type = 'number', label = 'Pregrijavanje', description = 'Diže temp u vrućim zonama (0 = ništa)', default = 0, min = 0 },
        { type = 'slider', label = 'Zaštita od radijacije (%)', default = 0, min = 0, max = 100 },
        { type = 'checkbox', label = 'Sve teksture (boje) kao zasebne iteme' },
    })
    if not input then return end

    local slotType = findType(input[1])
    if not slotType then exports.qbx_core:Notify('Izaberi tip odjeće', 'error') return end

    local gender = getGender()
    local override = input[3] and input[3] ~= '' and input[3]
    local stats = {
        warmth = input[4] or 0,
        heatPenalty = input[5] or 0,
        radProtection = (input[6] or 0) / 100,
    }

    local targets = {}
    if slotType.value == 'outfit' and not override then

        local ped = cache.ped
        for _, os in ipairs(OUTFIT_SLOTS) do
            local present = true
            if os.type == 'prop' then
                if GetPedPropIndex(ped, os.id) == -1 then present = false end
            elseif OPTIONAL[os.id] and GetPedDrawableVariation(ped, os.id) == 0 then
                present = false
            end
            if present then
                local pieces = buildPieces({ { type = os.type, id = os.id } }, gender)
                if #pieces > 0 then

                    local pieceStats = (os.type == 'component' and os.id == 11) and stats or { warmth = 0, heatPenalty = 0, radProtection = 0 }
                    targets[#targets + 1] = { prefix = os.prefix, label = os.label, pieces = pieces, slot = { type = os.type, id = os.id }, stats = pieceStats }
                end
            end
        end
        if #targets == 0 then exports.qbx_core:Notify('Nema komada na sebi', 'error') return end
    else

        local label = (input[2] and input[2] ~= '' and input[2]) or slotType.label
        local compStr = override or slotType.comps
        local slots = parseSlots(compStr)
        if #slots == 0 then exports.qbx_core:Notify('Neispravne komponente', 'error') return end
        targets[1] = { prefix = slotType.value, label = label, pieces = buildPieces(slots, gender), slot = slots[1], stats = stats }
    end

    if input[7] then targets = expandTextures(targets, gender) end

    local valid, skipped = {}, 0
    for _, t in ipairs(targets) do
        local name, existed = lib.callback.await('qbx_core:createClothingDef', false, t.prefix, { label = t.label, pieces = t.pieces, stats = t.stats })
        if name and not existed then
            t.name = name
            valid[#valid + 1] = t
        elseif existed then
            skipped = skipped + 1
        end
    end

    if #valid == 0 then
        exports.qbx_core:Notify(skipped > 0 and ('Sve već postoji (%d preskočeno)'):format(skipped) or 'Nije moguće kreirati (dozvola?)', 'inform')
        return
    end
    exports.qbx_core:Notify(('Pravim slike za %d komada%s...'):format(#valid, skipped > 0 and (', %d preskočeno'):format(skipped) or ''), 'inform')
    captureBatch(valid, gender)
end, false)
