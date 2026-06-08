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
    genericItem = 'clothing', -- ox_inventory item koji nosi svu odjeću kroz metadata

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
