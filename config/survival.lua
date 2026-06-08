return {
    tickInterval = 60,

    temperature = {
        enabled = true,
        default = 50, min = 0, max = 100,
        comfortMin = 40, comfortMax = 60,
        tickInterval = 30,
        maxDelta = 8,

        nightDrop = 2,
        rainDrop = 2,
        waterDrop = 6,
        snowDrop = 4,
        heatRise = 3,
        baseRegen = 1,

        coldAltitude = 250.0,
        hotZones = {
            SANDY = true, GRAPES = true, DESRT = true, ARMYB = true, CANNY = true,
        },

        hotDrink = 10,
        coldDrink = 10,

        coldShiverThreshold = 30,
        coldDamageThreshold = 10,
        hotDamageThreshold = 90,
        damage = 3,
    },

    bladder = {
        enabled = true, default = 0, max = 100,
        drinkGain = 12,
        timeGain = 1,
        discomfort = 80,
        auto = 100,
    },

    bowel = {
        enabled = true, default = 0, max = 100,
        eatGain = 12,
        timeGain = 0.7,
        discomfort = 80,
        auto = 100,
    },

    relieve = {

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
        minToRelieve = 15,
        autoInfectionChance = 20,
    },

    radiation = {
        enabled = true,
        default = 0, min = 0, max = 100,
        tickInterval = 5,
        maxDelta = 12,
        decayPerTick = 2,

        sicknessThreshold = 40,
        damageThreshold = 70,
        damage = 4,
        vomitChance = 15,
        screenFx = 'DrugsTrevorClownsFight',
        vomitAnim = { dict = 'missfbi3_party_d', clip = 'vomit_loop' },

        geiger = {
            soundName = 'NAV_UP_DOWN',
            soundSet = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
            minInterval = 120,
            maxInterval = 1500,
        },

        zones = {
            { coords = vec3(3550.0, 3680.0, 30.0), radius = 120.0, intensity = 6 },
        },
    },
}
