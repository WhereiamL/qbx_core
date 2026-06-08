window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || d.action !== 'process') return;

    const img = new Image();
    img.onload = () => {
        const w = img.width, h = img.height;
        const canvas = document.createElement('canvas');
        canvas.width = w; canvas.height = h;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);

        const imgData = ctx.getImageData(0, 0, w, h);
        const px = imgData.data;
        const gMin = (d.chroma && d.chroma.gMin) || 90;
        const ratio = (d.chroma && d.chroma.ratio) || 1.35;

        let minX = w, minY = h, maxX = 0, maxY = 0, found = false;
        for (let y = 0; y < h; y++) {
            for (let x = 0; x < w; x++) {
                const i = (y * w + x) * 4;
                const r = px[i], g = px[i + 1], b = px[i + 2];
                if (g > gMin && g > r * ratio && g > b * ratio) {
                    px[i + 3] = 0;
                } else {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                    found = true;
                }
            }
        }
        ctx.putImageData(imgData, 0, 0);

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
    };
    img.src = d.image;
});
