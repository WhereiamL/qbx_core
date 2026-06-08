return {
    unequipCommand = 'skini',
    devCapture = true,
    addCommand = 'dodaj',
    genericItem = 'clothing',

    greenScreen = {
        model = 'jim_g_green_screen',
        position = vec3(-1289.02, -3409.83, 20.91),
        hiddenSpot = vec3(-1224.22, -3349.63, 13.96),
        heading = 330.0,
        camDistance = 1.2,
        imageSize = 320,
        screenshotResource = 'screencapture',

        chroma = { gMin = 90, ratio = 1.35 },

        camera = {
            default = { fov = 50.0, rz = 155.0, zPos = 0.2 },
            component = {
                [1]  = { fov = 30.0, rz = 120.0, zPos = 0.65 },
                [3]  = { fov = 55.0, rz = 155.0, zPos = 0.30 },
                [4]  = { fov = 60.0, rz = 155.0, zPos = -0.46 },
                [5]  = { fov = 40.0, rz = -25.0, zPos = 0.30 },
                [6]  = { fov = 40.0, rz = 120.0, zPos = -0.85 },
                [7]  = { fov = 45.0, rz = 155.0, zPos = 0.30 },
                [8]  = { fov = 45.0, rz = 155.0, zPos = 0.30 },
                [9]  = { fov = 45.0, rz = 155.0, zPos = 0.30 },
                [11] = { fov = 55.0, rz = 155.0, zPos = 0.26 },
            },
            prop = {
                [0] = { fov = 30.0, rz = 120.0, zPos = 0.75 },
                [1] = { fov = 20.0, rz = 120.0, zPos = 0.70 },
                [2] = { fov = 20.0, rz = 237.5, zPos = 0.675 },
                [6] = { fov = 20.0, rz = 59.0,  zPos = 0.03 },
                [7] = { fov = 20.0, rz = 250.0, zPos = 0.03 },
            },
        },
    },

    items = {
        ['jacket_black'] = {
            label = 'Crna jakna',
            stats = { warmth = 12, heatPenalty = 8 },
            pieces = {
                { type = 'component', id = 11, male = { drawable = 26, texture = 0 }, female = { drawable = 26, texture = 0 } },
            },
        },

        ['cap_black'] = {
            label = 'Crna kapa',
            stats = { warmth = 3 },
            pieces = {
                { type = 'prop', id = 0, male = { drawable = 13, texture = 0 }, female = { drawable = 13, texture = 0 } },
            },
        },

        ['hazmat'] = {
            label = 'Hazmat odijelo',
            stats = { radProtection = 1.0, warmth = 8, heatPenalty = 20 },
            pieces = {
                { type = 'component', id = 11, male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } },
                { type = 'component', id = 4,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } },
                { type = 'component', id = 8,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } },
                { type = 'component', id = 6,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } },
                { type = 'prop',      id = 0,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } },
            },
        },
    },
}
