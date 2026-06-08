// FiveZ HUD - jednostavan, citljiv. Driver: qbx_core/client/hud.lua (action 'hud').
(function () {
  const ICON = {
    health: 'M12 20s-6.5-4-9-8c-1.6-2.6 0-6 3.5-6 2 0 3 1.3 3.5 2.2C13.5 7.3 14.5 6 16.5 6 20 6 21.6 9.4 21 12c-2.5 4-9 8-9 8z',
    armor: 'M12 2l8 3v6c0 5-3.4 8.9-8 11-4.6-2.1-8-6-8-11V5z',
    blood: 'M12 3c4.2 5.2 6.5 8.3 6.5 11.3A6.5 6.5 0 1 1 5.5 14.3C5.5 11.3 7.8 8.2 12 3z',
    hunger: 'M12 7c-3 0-5 2-5 6s2 8 5 8c.7 0 1.3-.3 2-.6.7.3 1.3.6 2 .6 3 0 5-5 5-8s-2-6-5-6c-1 0-1.6.4-2 1-.4-.6-1-1-2-1z',
    thirst: 'M10 2h4v2.5l1.2 2.3V20a2 2 0 0 1-2 2h-2.4a2 2 0 0 1-2-2V6.8L10 4.5z',
    temp: 'M12 2a3 3 0 0 0-3 3v8.1a5 5 0 1 0 6 0V5a3 3 0 0 0-3-3z',
    bladder: 'M12 3c4.2 5.2 6.5 8.3 6.5 11.3A6.5 6.5 0 1 1 5.5 14.3C5.5 11.3 7.8 8.2 12 3z',
    bowel: 'M9 4c-3 0-5 2-5 5 0 3.5 3 4.5 3 7.5 0 2.2 1.8 3.5 4 3.5 4 0 7-3 7-7 0-2.6-1-4.4-3-5.4-.9-.5-1.2-1-1.2-2C13.6 5.8 11.8 4 9 4z',
    radiation: 'RAD',
    stamina: 'M13 3a2 2 0 1 1-2 2 2 2 0 0 1 2-2zM7 8l5-1 4 3 3 1-.6 1.9-3.6-1.2-2 1.6 2.2 2.3L17 22h-2l-1.2-5-2.8-2-1.5 5.5-2-.5L11 13l-1.5-1-1.8 2.8-1.7-1L8.5 9z',
  };
  const DICON = {
    bleeding: 'M12 3c4.2 5.2 6.5 8.3 6.5 11.3A6.5 6.5 0 1 1 5.5 14.3C5.5 11.3 7.8 8.2 12 3z',
    fracture: 'M7 3a2.5 2.5 0 0 1 2.3 3.5l8.2 8.2A2.5 2.5 0 1 1 17 18.5l-1.5 1.5a2.5 2.5 0 1 1-3.5-2.3L3.8 9.5A2.5 2.5 0 1 1 5.5 5L7 3.5z',
    disease: 'M11 2h2v3.1a7 7 0 0 1 2.5 1l2.2-2.2 1.4 1.4-2.2 2.2a7 7 0 0 1 1 2.5H21v2h-3.1a7 7 0 0 1-1 2.5l2.2 2.2-1.4 1.4-2.2-2.2a7 7 0 0 1-2.5 1V21h-2v-3.1a7 7 0 0 1-2.5-1l-2.2 2.2-1.4-1.4 2.2-2.2a7 7 0 0 1-1-2.5H3v-2h3.1a7 7 0 0 1 1-2.5L4.9 6.3l1.4-1.4 2.2 2.2a7 7 0 0 1 2.5-1zm1 6a4 4 0 1 0 0 8 4 4 0 0 0 0-8z',
    wetness: 'M7 4c2.2 2.8 3.5 4.6 3.5 6.2A3.5 3.5 0 1 1 3.5 10C3.5 8.5 4.8 6.7 7 4z M16 9c1.8 2.3 2.8 3.8 2.8 5A2.8 2.8 0 1 1 13.2 14c0-1.2 1-2.7 2.8-5z',
  };

  function svg(path) {
    if (path === 'RAD') {
      return '<svg viewBox="0 0 24 24"><path d="M12 12 8 3.6a10 10 0 0 1 8 0z"/><path d="M12 12 3.7 16a10 10 0 0 1-1.5-7.8z"/><path d="M12 12l8.3 4a10 10 0 0 1-6.8 4z"/><circle cx="12" cy="12" r="2.3"/></svg>';
    }
    return '<svg viewBox="0 0 24 24"><path d="' + path + '"/></svg>';
  }

  // mode: deplete (vrijednost veca = bolje), rise (veca = gore), temp (sredina dobra)
  const ROWS = [
    { key: 'health', mode: 'deplete' },
    { key: 'armor', mode: 'deplete', hideZero: true },
    { key: 'blood', mode: 'deplete' },
    { key: 'hunger', mode: 'deplete' },
    { key: 'thirst', mode: 'deplete' },
    { key: 'temp', mode: 'temp' },
    { key: 'bladder', mode: 'rise' },
    { key: 'bowel', mode: 'rise' },
    { key: 'radiation', mode: 'rise', hideZero: true },
    { key: 'stamina', mode: 'deplete', hideFull: true },
  ];
  const DEBUFFS = ['bleeding', 'fracture', 'disease', 'wetness'];

  const depleteColor = (v) => v > 50 ? '#3fb950' : v > 25 ? '#d29922' : '#f85149';
  const riseColor = (v) => v < 50 ? '#3fb950' : v < 80 ? '#d29922' : '#f85149';
  const tempColor = (v) => v <= 35 ? '#4ab8e8' : v >= 75 ? '#f85149' : '#3fb950';
  const clamp = (v) => Math.max(0, Math.min(100, v));

  const hud = document.getElementById('hud');
  const statsEl = document.getElementById('stats');
  const debuffsEl = document.getElementById('debuffs');
  const vehEl = document.getElementById('veh');
  const rows = {};

  for (const r of ROWS) {
    const el = document.createElement('div');
    el.className = 'row';
    el.innerHTML = '<span class="ic">' + svg(ICON[r.key]) + '</span><span class="track"><span class="fill"></span></span><span class="num">0</span>';
    statsEl.appendChild(el);
    rows[r.key] = { el, fill: el.querySelector('.fill'), num: el.querySelector('.num') };
  }
  const dEls = {};
  for (const k of DEBUFFS) {
    const el = document.createElement('div');
    el.className = 'debuff ' + k;
    el.innerHTML = svg(DICON[k]);
    debuffsEl.appendChild(el);
    dEls[k] = el;
  }

  window.addEventListener('message', function (e) {
    const d = e.data;
    if (!d || d.action !== 'hud') return;
    if (!d.show) { hud.style.display = 'none'; return; }
    hud.style.display = 'flex';

    const s = d.stats || {};
    const inVeh = d.veh && d.veh.inv;

    for (const r of ROWS) {
      const ref = rows[r.key];
      const v = clamp(Math.round(s[r.key] || 0));
      let hide = false;
      if (r.hideZero && v <= 0) hide = true;
      if (r.hideFull && v >= 99) hide = true;
      if (r.key === 'stamina' && inVeh) hide = true;
      ref.el.classList.toggle('hide', hide);
      if (hide) continue;
      ref.fill.style.width = v + '%';
      ref.fill.style.background = r.mode === 'temp' ? tempColor(v) : r.mode === 'rise' ? riseColor(v) : depleteColor(v);
      ref.num.textContent = v;
    }

    const db = d.debuffs || {};
    for (const k of DEBUFFS) dEls[k].classList.toggle('show', !!db[k]);

    if (inVeh) {
      vehEl.style.display = 'block';
      vehEl.querySelector('.spd b').textContent = Math.round(d.veh.speed || 0);
      vehEl.querySelector('.fuel i').style.width = clamp(d.veh.fuel || 0) + '%';
    } else {
      vehEl.style.display = 'none';
    }
  });
})();
