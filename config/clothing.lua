-- Clothing-as-item: odjeća kao predmet u inventaru (radi preko illenium-appearance).
-- Svaki predmet definiše "pieces" (komponente/propove) + per-gender drawable/texture.
-- Komponente (component_id): 1=maska, 3=ruke/torzo, 4=noge, 5=torba, 6=cipele,
--   7=vrat/ogrlica, 8=majica ispod, 9=pancir, 10=decal, 11=gornji dio/jakna
-- Propovi (prop_id): 0=šešir/kaciga, 1=naočale, 2=uši, 6=sat, 7=narukvica
-- NAPOMENA: drawable/texture zavise od tvojih clothing pakova (EUP/addon) i razlikuju
--   se za muški/ženski model — dolje su PRIMJERI, prilagodi svom serveru.
return {
    unequipCommand = 'skini', -- komanda za skidanje sve obučene item-odjeće
    devCapture = true,        -- DEV: /outfitcapture ispisuje config-snippet trenutnog izgleda (isključi na produkciji)

    items = {
        ['jacket_black'] = {
            label = 'Crna jakna',
            pieces = {
                { type = 'component', id = 11, male = { drawable = 26, texture = 0 }, female = { drawable = 26, texture = 0 } },
            },
        },

        ['cap_black'] = {
            label = 'Crna kapa',
            pieces = {
                { type = 'prop', id = 0, male = { drawable = 13, texture = 0 }, female = { drawable = 13, texture = 0 } },
            },
        },

        -- Hazmat odijelo: više komponenti + maska; daje punu zaštitu od radijacije.
        -- Drawable indeksi su PLACEHOLDER — upiši prave iz svog hazmat pakovanja.
        ['hazmat'] = {
            label = 'Hazmat odijelo',
            radProtection = 1.0, -- 0..1 (1 = puni imunitet na radijaciju)
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
