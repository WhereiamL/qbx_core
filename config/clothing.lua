-- Clothing-as-item: odjeća kao predmet u inventaru (radi preko illenium-appearance).
-- Svaki predmet definiše "pieces" (komponente/propove) + per-gender drawable/texture.
-- Komponente (component_id): 1=maska, 3=ruke/torzo, 4=noge, 5=torba, 6=cipele,
--   7=vrat/ogrlica, 8=majica ispod, 9=pancir, 10=decal, 11=gornji dio/jakna
-- Propovi (prop_id): 0=šešir/kaciga, 1=naočale, 2=uši, 6=sat, 7=narukvica
-- NAPOMENA: drawable/texture zavise od tvojih clothing pakova (EUP/addon) i razlikuju
--   se za muški/ženski model — dolje su PRIMJERI, prilagodi svom serveru.
--
-- STATS (survival efekti, sve opcionalno):
--   warmth        = grije (smanjuje hladnoću)
--   heatPenalty   = pregrijavanje u vrućim zonama (diže temperaturu)
--   radProtection = 0..1 zaštita od radijacije (1 = puni imunitet)
-- Sve odjeća se daje kao GENERIČKI item (config.genericItem) sa metadata.clothing = ime
-- definicije. Statovi se nose u metadata.stats (mogu se override-ati po komadu/lootu).
return {
    unequipCommand = 'skini', -- komanda za skidanje sve obučene item-odjeće
    devCapture = true,        -- DEV: /outfitcapture snima trenutni izgled u clothing.json (isključi na produkciji)
    addCommand = 'dodaj',     -- DEV: /dodaj -> meni (ime+statovi) + auto slika za inventar
    genericItem = 'clothing', -- ox_inventory item koji nosi svu odjeću kroz metadata

    -- Generator slike (greenscreen + chroma-key). Treba: screenshot-basic + green box stream.
    greenScreen = {
        model = 'jim_g_green_screen', -- prop koji ti streamuješ
        position = vec3(-1289.02, -3409.83, 20.91), -- gdje stoji ped (iz greenscreenera)
        hiddenSpot = vec3(-1224.22, -3349.63, 13.96), -- gdje se igrač teleportuje za vrijeme slikanja
        heading = 330.0,
        camDistance = 1.2,     -- udaljenost kamere (podesi ako je preblizu/predaleko)
        imageSize = 320,       -- finalna veličina (px)
        -- chroma-key prag (zelena -> providno); podesi ako "jede" rubove
        chroma = { gMin = 90, ratio = 1.35 },
        -- kamera po komponenti/propu (fov, z rotacija, visina) — iz fivem-greenscreener
        camera = {
            default = { fov = 50.0, rz = 155.0, zPos = 0.2 },
            component = {
                [1]  = { fov = 30.0, rz = 120.0, zPos = 0.65 },  -- maske
                [3]  = { fov = 55.0, rz = 155.0, zPos = 0.30 },  -- torzo/ruke
                [4]  = { fov = 60.0, rz = 155.0, zPos = -0.46 }, -- noge
                [5]  = { fov = 40.0, rz = -25.0, zPos = 0.30 },  -- torbe
                [6]  = { fov = 40.0, rz = 120.0, zPos = -0.85 }, -- cipele
                [7]  = { fov = 45.0, rz = 155.0, zPos = 0.30 },  -- dodaci/vrat
                [8]  = { fov = 45.0, rz = 155.0, zPos = 0.30 },  -- majica ispod
                [9]  = { fov = 45.0, rz = 155.0, zPos = 0.30 },  -- pancir
                [11] = { fov = 55.0, rz = 155.0, zPos = 0.26 },  -- gornji dio/jakna
            },
            prop = {
                [0] = { fov = 30.0, rz = 120.0, zPos = 0.75 },  -- šeširi/kacige
                [1] = { fov = 20.0, rz = 120.0, zPos = 0.70 },  -- naočale
                [2] = { fov = 20.0, rz = 237.5, zPos = 0.675 }, -- uši
                [6] = { fov = 20.0, rz = 59.0,  zPos = 0.03 },  -- satovi
                [7] = { fov = 20.0, rz = 250.0, zPos = 0.03 },  -- narukvice
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

        -- Hazmat odijelo: više komponenti + maska; puna zaštita od radijacije ali se grije.
        -- Drawable indeksi su PLACEHOLDER — upiši prave (ili capture-uj /outfitcapture hazmat).
        ['hazmat'] = {
            label = 'Hazmat odijelo',
            stats = { radProtection = 1.0, warmth = 8, heatPenalty = 20 },
            pieces = {
                { type = 'component', id = 11, male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } }, -- gornji
                { type = 'component', id = 4,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } }, -- noge
                { type = 'component', id = 8,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } }, -- majica ispod
                { type = 'component', id = 6,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } }, -- cipele
                { type = 'prop',      id = 0,  male = { drawable = 0, texture = 0 }, female = { drawable = 0, texture = 0 } }, -- maska/kapuljača
            },
        },
    },
}
