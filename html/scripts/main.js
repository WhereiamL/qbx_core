// FiveZ HUD render (vanilla). Driver: qbx_core/client/hud.lua salje realne procente (100 = puno).
(function () {
  const root = document.documentElement;
  const byId = (id) => document.getElementById(id);
  const qs = (s) => document.querySelector(s);
  const setVar = (n, v) => root.style.setProperty(n, v);
  const setSrc = (id, src) => { const e = byId(id); if (e && e.getAttribute('src') !== src) e.setAttribute('src', src); };

  const prev = {};
  function arrow(prefix, value) {
    const p = prev[prefix];
    prev[prefix] = value;
    if (p === undefined) return;
    const id = value > p ? prefix + '-bottom-arrow' : value < p ? prefix + '-top-arrow' : null;
    if (!id) return;
    const el = byId(id);
    if (!el) return;
    el.style.display = 'block';
    clearTimeout(el._t);
    el._t = setTimeout(() => { el.style.display = 'none'; }, 700);
  }

  // fill: clip ide od var() prema dnu -> da puno bude pun bar, var = 100 - realni%
  function fill(name, value) { setVar(name, (100 - value) + '%'); }

  function cls(id, map) {
    const el = byId(id);
    if (!el) return;
    el.classList.remove('warning', 'critical', 'cold', 'warm', 'hot');
    if (map) el.classList.add(map);
  }

  const conditions = [
    ['overweight', '.overweight-container'],
    ['wetness', '.wetness-container'],
    ['bleeding', '.bleeding-container'],
    ['digestion', '.digesting-container'],
    ['disease', '.disease-container'],
    ['illness', '.illness-container'],
    ['brokenbone', '.brokenbone-container'],
  ];

  let micPrev;

  window.addEventListener('message', function (e) {
    const d = e.data;
    if (!d) return;

    if (d.action === 'loaded') {
      const su = qs('.speed-unit'); if (su) su.textContent = d.speedUnit ? 'MPH' : 'KMH';
      if (d.useTemp === false) { const t = qs('.temp-container'); if (t) t.style.display = 'none'; }
      if (d.useBlood === false) { const b = qs('.blood-container'); if (b) b.style.display = 'none'; }
      if (d.useThickIcons) {
        setSrc('overweight', 'img/overweight_thick.svg');
        setSrc('wetness', 'img/wetness_thick.png');
        setSrc('illness', 'img/illness_thick.png');
        setSrc('digesting', 'img/digesting_thick.png');
        setSrc('disease', 'img/disease_thick.png');
        setSrc('bleeding', 'img/bleeding_thick.png');
      }
      document.body.style.display = 'block';
      return;
    }

    if (d.action === 'inVehicle') {
      const v = qs('.vehicle-container'); if (v) v.style.display = 'block';
      const s = qs('.stamina-container'); if (s) s.style.display = 'none';
      const num = qs('.speed-num'); if (num) num.textContent = String(Math.round(d.speed)).padStart(3, '0');
      const fuel = d.fuel || 0;
      const bar = qs('.inner-fuel-bar'); const icon = qs('.fuel-icon');
      if (bar) {
        bar.style.width = fuel + '%';
        if (fuel <= 4) { bar.style.backgroundColor = '#FF2929'; if (icon) icon.style.color = '#FF2929'; }
        else if (fuel <= 20) { bar.style.backgroundColor = '#FF2929'; if (icon) icon.style.color = '#FFFFFF'; }
        else if (fuel <= 40) { bar.style.backgroundColor = '#FFA229'; if (icon) icon.style.color = '#FFFFFF'; }
        else { bar.style.backgroundColor = '#FFFFFF'; if (icon) icon.style.color = '#FFFFFF'; }
      }
      return;
    }

    if (d.action === 'noVehicle') {
      const v = qs('.vehicle-container'); if (v) v.style.display = 'none';
      const s = qs('.stamina-container'); if (s) s.style.display = 'block';
      const stam = Math.round(d.stamina);
      const bar = qs('.inner-stamina-bar');
      if (bar) {
        bar.style.width = stam + '%';
        bar.style.backgroundColor = stam <= 20 ? '#FF2929' : stam <= 50 ? '#FFA229' : '#FFFFFF';
      }
      return;
    }

    if (d.action === 'hudVisibility') {
      const m = qs('main'); if (m) m.style.display = d.showHud ? 'block' : 'none';
      return;
    }

    if (d.action !== 'onFoot') return;

    // mic
    if (micPrev !== d.voice) {
      micPrev = d.voice;
      const mt = qs('.mic-text');
      if (mt) {
        mt.textContent = d.voice === 1.5 ? 'Whisper' : d.voice === 6.0 ? 'Shouting' : 'Normal';
        mt.style.opacity = '1';
        clearTimeout(mt._t);
        mt._t = setTimeout(() => { mt.style.opacity = '0'; }, 1000);
      }
    }
    { const mic = qs('.status-mic'); if (mic) mic.setAttribute('src', d.talking ? 'img/microphone_on.png' : 'img/microphone_off.png'); }

    // health
    arrow('health', d.health);
    fill('--health-percent', d.health);
    if (d.health >= 60) { setSrc('health-empty', 'img/hp_empty_25.png'); setSrc('health-bar', 'img/hp_full_20.png'); }
    else { setSrc('health-empty', 'img/hp_empty.png'); setSrc('health-bar', 'img/hp_full.png'); }
    cls('health-bar', d.health <= 20 ? 'critical' : d.health <= 40 ? 'warning' : null);

    // armor (samo kad ga ima)
    const ac = qs('.armor-container');
    if (d.armor <= 0) { if (ac) ac.style.display = 'none'; }
    else { if (ac) ac.style.display = 'flex'; arrow('armor', d.armor); fill('--armor-percent', d.armor); }

    // hunger / thirst
    arrow('food', d.hunger); fill('--food-percent', d.hunger);
    cls('food-bar', d.hunger <= 25 ? 'critical' : null);
    arrow('water', d.water); fill('--water-percent', d.water);
    cls('water-bar', d.water <= 25 ? 'critical' : d.water <= 50 ? 'warning' : null);

    // temperatura (realno 0-100, 50 normalno)
    arrow('temp', d.temp); fill('--temp-percent', d.temp);
    cls('temp-bar', d.temp <= 35 ? 'cold' : d.temp >= 75 ? 'hot' : 'warm');

    // krv
    arrow('blood', d.blood); fill('--blood-percent', d.blood);
    cls('blood-bar', d.blood <= 30 ? 'critical' : null);

    // debuff ikone
    let any = false;
    conditions.forEach(([prop, sel]) => {
      const on = !!d[prop];
      if (on) any = true;
      const el = qs(sel);
      if (el) el.style.display = on ? 'flex' : 'none';
    });
    const breaker = byId('breaker');
    if (breaker) breaker.style.display = any ? 'block' : 'none';
  });
})();
