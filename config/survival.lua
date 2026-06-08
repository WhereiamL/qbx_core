-- Faza 5: survival needs (temperatura + mjehur/crijeva). Sve tunable.
-- Glad/žeđ ostaju u config/server.lua (već postoje i vode u DOWNED preko qbx_medical).
return {
    tickInterval = 60, -- sekundi: server tick za mjehur/crijeva (vremenski prirast + auto)

    temperature = {
        enabled = true,
        default = 50, min = 0, max = 100,
        comfortMin = 40, comfortMax = 60,
        tickInterval = 30,   -- sekundi: klijent šalje okolinu serveru
        maxDelta = 8,        -- anti-abuse: max promjena po ticku

        -- okolinski uticaji (po ticku)
        nightDrop = 2,       -- noć hladi
        rainDrop = 2,        -- kiša hladi
        waterDrop = 6,       -- voda jako hladi
        snowDrop = 4,        -- visina/snijeg hladi
        heatRise = 3,        -- vruće zone griju
        baseRegen = 1,       -- vraćanje ka komforu kad nema uticaja

        coldAltitude = 250.0, -- iznad ove visine je hladno (planina)
        hotZones = {          -- GetNameOfZone kodovi za vruće zone (pustinja)
            SANDY = true, GRAPES = true, DESRT = true, ARMYB = true, CANNY = true,
        },

        -- napici (preko exporta useHotDrink/useColdDrink)
        hotDrink = 10,
        coldDrink = 10,

        -- efekti
        coldShiverThreshold = 30, -- ispod = drhtanje
        coldDamageThreshold = 10, -- ispod = HP šteta (vodi u DOWNED)
        hotDamageThreshold = 90,  -- iznad = HP šteta
        damage = 3,               -- HP po ciklusu na ekstremu
    },

    bladder = {
        enabled = true, default = 0, max = 100,
        drinkGain = 12,   -- prirast kad piješ (porast žeđi)
        timeGain = 1,     -- prirast po server ticku
        discomfort = 80,  -- iznad = nelagoda (bez sprinta)
        auto = 100,       -- na max se automatski isprazniš (sramota)
    },

    bowel = {
        enabled = true, default = 0, max = 100,
        eatGain = 12,     -- prirast kad jedeš (porast gladi)
        timeGain = 0.7,
        discomfort = 80,
        auto = 100,
    },

    relieve = {
        -- anime iz renzu_hygiene (+ particle efekti)
        pee = {
            anim = { dict = 'misscarsteal2peeing', clip = 'peeing_loop' },
            ptfx = { dict = 'core', name = 'ent_amb_peeing', offset = vec3(0.0, 0.1, -0.05) },
            duration = 6000,
        },
        poop = {
            anim = { dict = 'timetable@ron@ig_3_couch', clip = 'base' },
            ptfx = { dict = 'core', name = 'ent_anim_dog_poo', offset = vec3(0.0, -0.1, -0.45) },
            duration = 9000,
        },
        minToRelieve = 15,        -- ispod ovog "ne treba ti"
        autoInfectionChance = 20, -- % šansa infekcije pri auto-pražnjenju (preko qbx_medical)
    },
}
