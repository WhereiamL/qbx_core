# FiveZ — Survival sistem (dokumentacija)

Survival nadogradnja za **Qbox** framework, podijeljena u dva resursa:

- **qbx_core** — temperatura, mjehur/crijeva, radijacija, odjeća-kao-item (clothing), HUD.
- **qbx_medical** — hardcore medicina (krv, infekcija/groznica, lomovi/bol, puzanje, pljačka leša, oporavak).

---

## 1. Zavisnosti

| Resurs | Obavezno | Za šta |
|--------|----------|--------|
| `ox_lib` | da | callback, inputDialog, requestModel, cache |
| `ox_inventory` | da | itemi, slike odjeće, geiger provjera |
| `oxmysql` | da | qbx_core baza |
| `qbx_medical` | da (za debuffe/infekciju) | bleeding, infection, fractures |
| `screenshot-basic` | opcionalno | slike odjeće u `/dodaj` (bez njega se slika preskače) |
| stream: `jim_g_green_screen` | opcionalno | green box prop za slikanje odjeće |

Redoslijed pokretanja: `ox_lib` → `oxmysql` → `ox_inventory` → `qbx_core` → `qbx_medical`.

---

## 2. ox_inventory itemi

> Ovi itemi su **već dodani** u `ox_inventory-gridstyle/data/items.lua`. Lista ispod je referenca (item poziva naš export preko `client.export`):

```lua
['clothing']    = { label = 'Odjeća',        weight = 200, client = { export = 'qbx_core.equipClothing' } },
['geiger']      = { label = 'Geiger brojač', weight = 500, client = { export = 'qbx_core.toggleGeiger' } },
['radx']        = { label = 'Rad-X',         weight = 50,  client = { export = 'qbx_core.useAntiRad' } },
['coffee']      = { label = 'Topli napitak', weight = 100, client = { export = 'qbx_core.useHotDrink' } },
['cold_water']  = { label = 'Hladna voda',   weight = 100, client = { export = 'qbx_core.useColdDrink' } },
['bandage']     = { label = 'Zavoj',         weight = 50,  client = { export = 'qbx_medical.useBandage' } },
['bloodbag']    = { label = 'Kesa krvi',     weight = 100, client = { export = 'qbx_medical.useBloodbag' } },
['antibiotics'] = { label = 'Antibiotici',   weight = 50,  client = { export = 'qbx_medical.useAntibiotics' } },
['splint']      = { label = 'Udlaga',        weight = 100, client = { export = 'qbx_medical.useSplint' } },
['painkillers'] = { label = 'Lijek protiv bolova', weight = 50, client = { export = 'qbx_medical.usePainkillers' } },
```

> `clothing` je **jedan** item koji nosi svu odjeću kroz `metadata` (`config.clothing.genericItem`). Slika svake definicije se čuva u `ox_inventory/web/images/<ime>.png`.

---

## 3. Survival statovi (statebagovi)

Svi su na `Player(src).state` (server) i replicirani na klijent (`LocalPlayer.state`):

| Statebag | Raspon | Opis |
|----------|--------|------|
| `temperature` | 0–100 | 50 = komforno; nisko = hladno, visoko = vruće |
| `bladder` | 0–100 | mjehur; 100 = automatsko pišanje |
| `bowel` | 0–100 | crijeva; 100 = automatska nužda |
| `radiation` | 0–100 | radijacija |
| `wet` | bool | mokar (kiša/voda) — za HUD debuff |
| `hunger`, `thirst` | 0–100 | iz qbx_core needs |

### config/survival.lua (ključna polja)

- `tickInterval` — period sporog ticka (mjehur/crijeva), sek.
- `temperature` — `comfortMin/Max`, `maxDelta`, padovi (`nightDrop`, `rainDrop`, `waterDrop`, `snowDrop`), `heatRise`, `coldAltitude`, `hotZones`, pragovi štete (`coldDamageThreshold`, `hotDamageThreshold`, `damage`).
- `bladder` / `bowel` — `timeGain` (rast po ticku), `drinkGain`/`eatGain` (rast od pića/hrane), `auto` (prag automatske nužde).
- `relieve` — animacije/ptfx za pišanje i nuždu, `minToRelieve`, `autoInfectionChance`.
- `radiation` — `zones` (lista `{coords, radius, intensity}`), `sicknessThreshold`, `damageThreshold`, `decayPerTick`, `geiger` (zvuk i intervali).

---

## 4. Komande

| Komanda | Ko | Opis |
|---------|-----|------|
| `/dodaj` | admin | Meni za kreiranje odjeće + automatska slika |
| `/outfitcapture <ime>` | admin (`devCapture`) | Brzo snimanje trenutnog izgleda u `clothing.json` (bez slike) |
| `/giveclothing [id] [ime] [kol]` | admin | Daje clothing item |
| `/skini` | svi | Skida svu obučenu item-odjeću |
| `/piski` | svi | Pražnjenje mjehura |
| `/kaki` | svi | Pražnjenje crijeva |
| `/geiger` | svi | Uključi/isključi geiger (treba `geiger` item) |

---

## 5. Exporti

### qbx_core — server
```lua
exports.qbx_core:GetTemperature(src)         -- vrati temperaturu
exports.qbx_core:SetTemperature(src, v)
exports.qbx_core:AddTemperature(src, delta)
exports.qbx_core:AddBladder(src, delta)
exports.qbx_core:AddBowel(src, delta)
exports.qbx_core:GetRadiation(src)
exports.qbx_core:SetRadiation(src, v)
exports.qbx_core:AddRadiation(src, delta)
exports.qbx_core:RemoveRadiation(src, amount)
exports.qbx_core:GiveClothingItem(src, defName, count)  -- daj odjeću po imenu definicije
```

### qbx_core — klijent
```lua
exports.qbx_core:equipClothing(data)          -- obuci (poziva ox_inventory item)
exports.qbx_core:SetClothingWarmth(level)     -- ručno postavi toplinu odjeće
exports.qbx_core:SetClothingHeat(level)       -- ručno postavi heat-penalty
exports.qbx_core:SetRadiationProtection(0..1) -- zaštita od radijacije (0–1)
exports.qbx_core:useHotDrink()                -- +temperatura
exports.qbx_core:useColdDrink()               -- -temperatura
exports.qbx_core:useAntiRad()                 -- smanji radijaciju
exports.qbx_core:toggleGeiger()               -- geiger on/off
```

### qbx_medical (najvažniji)
```lua
-- server
exports.qbx_medical:GetPlayerStatus(src)      -- {injuries, bleedLevel, bleedState, damageCauses}
exports.qbx_medical:Revive(src) / :Heal(src) / :HealPartially(src)
exports.qbx_medical:GetBlood(src) / :SetBlood(src,v) / :AddBlood(src,v)
exports.qbx_medical:GetInfection(src) / :SetInfection(src,v) / :AddInfection(src,v)
-- klijent
exports.qbx_medical:IsDead() / :IsLaststand()
exports.qbx_medical:useBandage() / :useBloodbag() / :useAntibiotics() / :useSplint() / :usePainkillers()
```

---

## 6. Clothing sistem

### Kako radi
- Sva odjeća je **definicija** (`pieces` = komponente/propovi po spolu) + `stats` (`warmth`, `heatPenalty`, `radProtection`).
- Definicije dolaze iz `config/clothing.lua` (`items`) **i** iz `data/clothing.json` (kreirane preko `/dodaj`).
- Item `clothing` nosi `metadata.clothing = <ime def>`; na korištenje se obuče i sinhronizuje sa serverom (perzistira kroz karaktere).

### `/dodaj` (generator)
1. Dropdown tipa (Jakna, Majica, Pantalone, Obuća, Maska, Kapa, Naočale, Pancir, Torba, Rukavice, Cijeli outfit).
2. Opcionalni naziv, override komponenti, statovi, checkbox **Sve teksture (boje)**.
3. **Cijeli outfit** = svaki nošeni komad postaje zaseban item + slika.
4. Server dodjeljuje **jedinstveno ime** (`jakna_1`, `jakna_2`…) i preskače **duplikate** (isti izgled).
5. Slika: green box + nevidljivi klon (vidi se samo odjeća) → `screenshot-basic` → NUI chroma-key + crop + resize 320×320 → upis u `ox_inventory/web/images`.

### config/clothing.lua
- `genericItem` — ime ox_inventory itema (default `clothing`).
- `greenScreen` — `model`, `position`, `hiddenSpot`, `heading`, `camDistance`, `imageSize`, `chroma` (`gMin`, `ratio`), `camera` preseti po komponenti/propu.
- `items` — ručne definicije (primjeri: `jacket_black`, `cap_black`, `hazmat`).

---

## 7. HUD

Vanilla NUI (`html/index.html`, `hud.css`, `hud.js`) + `client/hud.lua`.

- **Statusi (dole-desno):** health, armor, hunger, thirst, temperatura, crijeva, mjehur, radijacija.
- Ikone mijenjaju boju po težini (sivo → amber → crveno → kritično + prsten + puls); temperatura plavo/crveno; chevroni ▲/▼ = trend.
- Ikona **blijedi** kad je stat ok, pojača se kad treba pažnja.
- **Debuffi (dole-lijevo, samo kad aktivni):** krvarenje, bolest, slomljena kost, mokar.
- **Stamina bar** dole-lijevo. HUD se krije na smrti/pauzi.
- Izgled se mijenja u `html/hud.css`; zamjena ikona u `html/hud.js` (`ICONS` / `DEBUFF_ICONS`).
- `html/hud_preview.html` / `hud_preview.png` su samo pregled, ne učitavaju se u igri.

---

## 8. qbx_medical (hardcore)

Statebagovi (`shared/main.lua`):
- `qbx_medical:bleedLevel` (0–4), `qbx_medical:infection` (0–100), `qbx_medical:blood`,
- `qbx_medical:pain`, `qbx_medical:hasFracture` (bool, za HUD),
- `qbx_medical:deathState`, `qbx_medical:injuries:<dio tijela>`.

Feature fajlovi: `blood` (krv/transfuzija), `infection` (groznica + efekti), `fractures` (lomovi + bol + udlaga/lijek), `crawl` (puzanje), `corpse` (pljačka leša), `coop` (podizanje ranjenog), `recovery` (oporavak).

Pragovi i parametri: `config/shared.lua` → `hardcore` (infection, fracture, pain).

---

## 9. Tuning savjeti

- **Slika odjeće loše uokvirena** → `config.clothing.greenScreen.camDistance` i `camera[...]` (`fov`, `zPos`, `rz`).
- **Chroma jede rubove / ostavlja zeleno** → `greenScreen.chroma.gMin` i `ratio`.
- **Temperatura prebrza/spora** → `config.survival.temperature.maxDelta` i padovi/regen.
- **Radijacijske zone** → `config.survival.radiation.zones`.
- **Stamina bar obrnut** → invertovanje u `client/hud.lua` (`GetPlayerSprintStaminaRemaining`).
