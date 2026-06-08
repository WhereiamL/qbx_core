// Obrada slike odjeće: 'diff' (oduzmi pozadinu, 2 slike) ili 'chroma' (zelena).
function loadImg(src) {
  return new Promise((resolve) => { const i = new Image(); i.onload = () => resolve(i); i.src = src; });
}

function finish(d, canvas, w, h, minX, minY, maxX, maxY, found) {
  if (!found) { minX = 0; minY = 0; maxX = w - 1; maxY = h - 1; }
  const pad = 12;
  minX = Math.max(0, minX - pad); minY = Math.max(0, minY - pad);
  maxX = Math.min(w - 1, maxX + pad); maxY = Math.min(h - 1, maxY + pad);
  const cw = maxX - minX + 1, ch = maxY - minY + 1;

  const size = d.size || 320;
  const out = document.createElement('canvas');
  out.width = size; out.height = size;
  const octx = out.getContext('2d');
  const scale = Math.min(size / cw, size / ch);
  const dw = cw * scale, dh = ch * scale;
  octx.drawImage(canvas, minX, minY, cw, ch, (size - dw) / 2, (size - dh) / 2, dw, dh);

  const b64 = out.toDataURL('image/png').split(',')[1];
  fetch(`https://${d.resource}/clothingImageDone`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({ name: d.name, image: b64 }),
  });
}

window.addEventListener('message', async (event) => {
  const d = event.data;
  if (!d || d.action !== 'process') return;

  const fg = await loadImg(d.image);
  const w = fg.width, h = fg.height;
  const canvas = document.createElement('canvas');
  canvas.width = w; canvas.height = h;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(fg, 0, 0);
  const fd = ctx.getImageData(0, 0, w, h);
  const px = fd.data;

  let minX = w, minY = h, maxX = 0, maxY = 0, found = false;
  const mark = (x, y) => { if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; found = true; };

  if (d.bg) {
    // DIFF: oduzmi pozadinu (sve sto je isto kao pozadina -> providno)
    const bgImg = await loadImg(d.bg);
    const bc = document.createElement('canvas');
    bc.width = w; bc.height = h;
    const bctx = bc.getContext('2d');
    bctx.drawImage(bgImg, 0, 0);
    const bp = bctx.getImageData(0, 0, w, h).data;
    const thr = d.diffThreshold || 38;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const i = (y * w + x) * 4;
        const diff = Math.abs(px[i] - bp[i]) + Math.abs(px[i + 1] - bp[i + 1]) + Math.abs(px[i + 2] - bp[i + 2]);
        if (diff < thr) { px[i + 3] = 0; } else { mark(x, y); }
      }
    }
  } else {
    // CHROMA: ukloni zelenu
    const gMin = (d.chroma && d.chroma.gMin) || 90;
    const ratio = (d.chroma && d.chroma.ratio) || 1.35;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const i = (y * w + x) * 4;
        const r = px[i], g = px[i + 1], b = px[i + 2];
        if (g > gMin && g > r * ratio && g > b * ratio) { px[i + 3] = 0; } else { mark(x, y); }
      }
    }
  }

  ctx.putImageData(fd, 0, 0);
  finish(d, canvas, w, h, minX, minY, maxX, maxY, found);
});
