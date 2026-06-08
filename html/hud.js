const ICONS = {
    health: '<svg viewBox="0 0 24 24"><path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6z"/></svg>',
    armor: '<svg viewBox="0 0 24 24"><path d="M12 2l8 3v6c0 5-3.4 8.9-8 11-4.6-2.1-8-6-8-11V5z"/></svg>',
    hunger: '<svg viewBox="0 0 24 24"><path d="M12 7c-3 0-5 2-5 6s2 8 5 8c.7 0 1.3-.3 2-.6.7.3 1.3.6 2 .6 3 0 5-5 5-8s-2-6-5-6c-1 0-1.6.4-2 1-.4-.6-1-1-2-1z"/><path d="M12.5 6c.2-1.6 1.4-3 3.2-3.2-.1 1.7-1.4 3.1-3.2 3.2z"/></svg>',
    thirst: '<svg viewBox="0 0 24 24"><path d="M10 2h4v2.5l1.2 2.3V20a2 2 0 0 1-2 2h-2.4a2 2 0 0 1-2-2V6.8L10 4.5z"/></svg>',
    temperature: '<svg viewBox="0 0 24 24"><path d="M12 2a3 3 0 0 0-3 3v8.1a5 5 0 1 0 6 0V5a3 3 0 0 0-3-3zm0 2a1 1 0 0 1 1 1v9.3l.6.3a3 3 0 1 1-3.2 0l.6-.3V5a1 1 0 0 1 1-1z"/><circle cx="12" cy="17.5" r="2.3"/></svg>',
    bladder: '<svg viewBox="0 0 24 24"><path d="M12 3c4.2 5.2 6.5 8.3 6.5 11.3A6.5 6.5 0 1 1 5.5 14.3C5.5 11.3 7.8 8.2 12 3z"/></svg>',
    bowel: '<svg viewBox="0 0 24 24"><path d="M9 4c-3 0-5 2-5 5 0 3.5 3 4.5 3 7.5 0 2.2 1.8 3.5 4 3.5 4 0 7-3 7-7 0-2.6-1-4.4-3-5.4-.9-.5-1.2-1-1.2-2C13.6 5.8 11.8 4 9 4z"/></svg>',
    radiation: '<svg viewBox="0 0 24 24"><path d="M12 12 8 3.6a10 10 0 0 1 8 0z"/><path d="M12 12 3.7 16a10 10 0 0 1-1.5-7.8z"/><path d="M12 12l8.3 4a10 10 0 0 1-6.8 4z"/><circle cx="12" cy="12" r="2.3"/></svg>',
};

const STATS = [
    { key: 'health', icon: 'health', mode: 'deplete', alwaysShow: true },
    { key: 'armor', icon: 'armor', mode: 'deplete', onlyIfPositive: true },
    { key: 'hunger', icon: 'hunger', mode: 'deplete' },
    { key: 'thirst', icon: 'thirst', mode: 'deplete' },
    { key: 'temperature', icon: 'temperature', mode: 'temp' },
    { key: 'bowel', icon: 'bowel', mode: 'rise' },
    { key: 'bladder', icon: 'bladder', mode: 'rise' },
    { key: 'radiation', icon: 'radiation', mode: 'rise' },
];

const DEBUFF_ICONS = {
    bleeding: '<svg viewBox="0 0 24 24"><path d="M12 3c4.2 5.2 6.5 8.3 6.5 11.3A6.5 6.5 0 1 1 5.5 14.3C5.5 11.3 7.8 8.2 12 3z"/></svg>',
    disease: '<svg viewBox="0 0 24 24"><path d="M11 2h2v3.1a7 7 0 0 1 2.5 1l2.2-2.2 1.4 1.4-2.2 2.2a7 7 0 0 1 1 2.5H21v2h-3.1a7 7 0 0 1-1 2.5l2.2 2.2-1.4 1.4-2.2-2.2a7 7 0 0 1-2.5 1V21h-2v-3.1a7 7 0 0 1-2.5-1l-2.2 2.2-1.4-1.4 2.2-2.2a7 7 0 0 1-1-2.5H3v-2h3.1a7 7 0 0 1 1-2.5L4.9 6.3l1.4-1.4 2.2 2.2a7 7 0 0 1 2.5-1zm1 6a4 4 0 1 0 0 8 4 4 0 0 0 0-8z"/></svg>',
    brokenBone: '<svg viewBox="0 0 24 24"><path d="M7 3a2.5 2.5 0 0 1 2.3 3.5l8.2 8.2A2.5 2.5 0 1 1 17 18.5l-1.5 1.5a2.5 2.5 0 1 1-3.5-2.3L3.8 9.5A2.5 2.5 0 1 1 5.5 5L7 3.5z"/></svg>',
    wetness: '<svg viewBox="0 0 24 24"><path d="M7 4c2.2 2.8 3.5 4.6 3.5 6.2A3.5 3.5 0 1 1 3.5 10C3.5 8.5 4.8 6.7 7 4z"/><path d="M16 9c1.8 2.3 2.8 3.8 2.8 5A2.8 2.8 0 1 1 13.2 14c0-1.2 1-2.7 2.8-5z"/></svg>',
};
const DEBUFFS = ['bleeding', 'disease', 'brokenBone', 'wetness'];
const debuffEls = {};
const debuffCluster = document.getElementById('debuffs');
for (const k of DEBUFFS) {
    const d = document.createElement('div');
    d.className = 'debuff' + (k === 'wetness' ? ' wet' : '');
    d.innerHTML = DEBUFF_ICONS[k];
    debuffCluster.appendChild(d);
    debuffEls[k] = d;
}

const els = {};
const cluster = document.getElementById('status');
for (const s of STATS) {
    const wrap = document.createElement('div');
    wrap.className = 'stat hidden';
    wrap.innerHTML = `<div class="chevrons"><span>⌃</span><span>⌃</span></div>${ICONS[s.icon]}`;
    cluster.appendChild(wrap);
    els[s.key] = { wrap, chev: wrap.querySelector('.chevrons') };
}

function severity(mode, v) {
    if (mode === 'deplete') return Math.min(1, Math.max(0, (100 - v) / 100));
    if (mode === 'rise') return Math.min(1, Math.max(0, v / 100));

    const d = Math.abs(v - 50);
    return d <= 10 ? 0 : Math.min(1, (d - 10) / 40);
}

function applyStat(s, data) {
    const el = els[s.key];
    if (!data) return;
    const v = data.v;
    const sev = severity(s.mode, v);
    const wrap = el.wrap;
    wrap.className = 'stat';

    const hide = (s.onlyIfPositive && v <= 0) || (!s.alwaysShow && sev < 0.12);
    if (hide) { wrap.classList.add('hidden'); el.chev.classList.remove('show'); return; }

    if (sev >= 0.9) wrap.classList.add('critical', 'ring');
    else if (sev >= 0.7) wrap.classList.add('high');
    else if (sev >= 0.4) wrap.classList.add('warn');

    if (s.mode === 'temp' && sev > 0) wrap.classList.add(v < 50 ? 'cold' : 'hot');

    if (data.t === 1) { el.chev.className = 'chevrons show'; }
    else if (data.t === -1) { el.chev.className = 'chevrons show down'; }
    else { el.chev.classList.remove('show'); }
}

const staminaWrap = document.getElementById('stamina-wrap');
const staminaBar = document.getElementById('stamina-bar');
const hud = document.getElementById('hud');

window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || d.action !== 'hud') return;

    if (!d.show) { hud.style.display = 'none'; return; }
    hud.style.display = 'block';

    const st = d.stats || {};
    for (const s of STATS) applyStat(s, st[s.key]);

    const db = d.debuffs || {};
    for (const k of DEBUFFS) debuffEls[k].classList.toggle('show', !!db[k]);

    const stam = st.stamina ? st.stamina.v : 100;
    if (stam < 99) {
        staminaWrap.classList.add('show');
        staminaBar.style.width = Math.max(0, Math.min(100, stam)) + '%';
        staminaBar.classList.toggle('low', stam < 25);
    } else {
        staminaWrap.classList.remove('show');
    }
});
