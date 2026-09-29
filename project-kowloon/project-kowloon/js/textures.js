import * as THREE from "three";

// Procedural HD surface library. Every texture is painted on a canvas at
// start-up (no image files), mostly in light neutral tones so the existing
// colour of each object tints it. A matching normal map is derived from the
// painted luminance so lights rake across the grain, grout and grime.
//
// Types: plaster, tiles, floor, wood, concrete, facade, tar, rust, fabric, grain

const SIZE = 512;
const cache = {};

function rng(seed) {
    let s = seed >>> 0;
    return () => {
        s = (s + 0x6D2B79F5) >>> 0;
        let t = Math.imul(s ^ (s >>> 15), s | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

function canvas(w = SIZE, h = SIZE) {
    const c = document.createElement("canvas");
    c.width = w; c.height = h;
    return [c, c.getContext("2d")];
}

// Soft value noise, tiled.
function noiseLayer(ctx, w, h, cell, alpha, r, dark = true) {
    const cols = Math.ceil(w / cell), rows = Math.ceil(h / cell);
    for (let y = 0; y < rows; y++) for (let x = 0; x < cols; x++) {
        const v = r();
        ctx.fillStyle = dark ? `rgba(40,30,20,${v * alpha})` : `rgba(255,250,240,${v * alpha})`;
        ctx.fillRect(x * cell, y * cell, cell, cell);
    }
}

function speckle(ctx, w, h, n, r, colors) {
    for (let i = 0; i < n; i++) {
        ctx.fillStyle = colors[(r() * colors.length) | 0];
        const s = 1 + r() * 2.5;
        ctx.fillRect(r() * w, r() * h, s, s);
    }
}

function blurCopy(src, px) {
    const [c, ctx] = canvas(src.width, src.height);
    ctx.filter = `blur(${px}px)`;
    // draw tiled so edges wrap
    for (const dx of [-1, 0, 1]) for (const dy of [-1, 0, 1]) ctx.drawImage(src, dx * src.width, dy * src.height);
    return c;
}

function grime(ctx, w, h, r, strength = 0.35) {
    // water streaks from the top and dirt pooling at the bottom
    for (let i = 0; i < 14; i++) {
        const x = r() * w, len = h * (0.2 + r() * 0.6), wd = 3 + r() * 14;
        const g = ctx.createLinearGradient(0, 0, 0, len);
        g.addColorStop(0, `rgba(60,45,30,${strength * (0.3 + r() * 0.5)})`);
        g.addColorStop(1, "rgba(60,45,30,0)");
        ctx.fillStyle = g;
        ctx.fillRect(x, 0, wd, len);
    }
    const g = ctx.createLinearGradient(0, h * 0.75, 0, h);
    g.addColorStop(0, "rgba(40,30,20,0)");
    g.addColorStop(1, `rgba(40,30,20,${strength})`);
    ctx.fillStyle = g;
    ctx.fillRect(0, h * 0.75, w, h * 0.25);
}

function cracks(ctx, w, h, r, n = 6) {
    ctx.strokeStyle = "rgba(40,30,25,0.3)";
    ctx.lineWidth = 1;
    for (let i = 0; i < n; i++) {
        let x = r() * w, y = r() * h;
        ctx.beginPath(); ctx.moveTo(x, y);
        for (let k = 0; k < 8; k++) { x += (r() - 0.5) * 30; y += r() * 18; ctx.lineTo(x, y); }
        ctx.stroke();
    }
}

// Normal map from luminance (Sobel), wrapping at the edges.
function normalFrom(src, strength = 2) {
    const w = src.width, h = src.height;
    const sctx = src.getContext("2d");
    const d = sctx.getImageData(0, 0, w, h).data;
    const lum = new Float32Array(w * h);
    for (let i = 0; i < w * h; i++) lum[i] = (d[i * 4] * 0.3 + d[i * 4 + 1] * 0.59 + d[i * 4 + 2] * 0.11) / 255;
    const L = (x, y) => lum[((y + h) % h) * w + ((x + w) % w)];
    const [c, ctx] = canvas(w, h);
    const out = ctx.createImageData(w, h);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const dx = (L(x + 1, y - 1) + 2 * L(x + 1, y) + L(x + 1, y + 1)) - (L(x - 1, y - 1) + 2 * L(x - 1, y) + L(x - 1, y + 1));
        const dy = (L(x - 1, y + 1) + 2 * L(x, y + 1) + L(x + 1, y + 1)) - (L(x - 1, y - 1) + 2 * L(x, y - 1) + L(x + 1, y - 1));
        let nx = -dx * strength, ny = -dy * strength, nz = 1;
        const len = Math.hypot(nx, ny, nz);
        const i = (y * w + x) * 4;
        out.data[i] = (nx / len * 0.5 + 0.5) * 255;
        out.data[i + 1] = (-ny / len * 0.5 + 0.5) * 255;
        out.data[i + 2] = (nz / len * 0.5 + 0.5) * 255;
        out.data[i + 3] = 255;
    }
    ctx.putImageData(out, 0, 0);
    return c;
}

// ---------------------------------------------------------------- painters

const painters = {
    plaster(ctx, w, h, r) {
        ctx.fillStyle = "#e9e4d8"; ctx.fillRect(0, 0, w, h);
        noiseLayer(ctx, w, h, 32, 0.10, r);
        noiseLayer(ctx, w, h, 8, 0.06, r);
        // peeling patches revealing concrete
        for (let i = 0; i < 4; i++) {
            ctx.fillStyle = `rgba(170,160,145,${0.12 + r() * 0.15})`;
            ctx.beginPath();
            const x = r() * w, y = r() * h, s = 18 + r() * 50;
            ctx.ellipse(x, y, s, s * (0.4 + r() * 0.6), r() * 3, 0, Math.PI * 2);
            ctx.fill();
        }
        cracks(ctx, w, h, r, 2);
        grime(ctx, w, h, r, 0.28);
        speckle(ctx, w, h, 900, r, ["rgba(80,70,60,0.25)", "rgba(255,255,255,0.3)"]);
    },
    tiles(ctx, w, h, r) {
        const n = 8, s = w / n;
        ctx.fillStyle = "#a8ada6"; ctx.fillRect(0, 0, w, h);            // grout
        for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
            const v = 225 + r() * 25 | 0;
            ctx.fillStyle = `rgb(${v},${v + 2},${v - 4})`;
            ctx.fillRect(x * s + 3, y * s + 3, s - 6, s - 6);
            ctx.fillStyle = "rgba(255,255,255,0.35)";
            ctx.fillRect(x * s + 5, y * s + 5, s - 14, 3);
            if (r() < 0.12) { ctx.fillStyle = "rgba(90,80,70,0.4)"; ctx.fillRect(x * s + r() * s, y * s + r() * s, 6, 4); }
        }
        grime(ctx, w, h, r, 0.28);
    },
    floor(ctx, w, h, r) {
        // worn terrazzo / cement tiles
        const n = 4, s = w / n;
        ctx.fillStyle = "#8f8a80"; ctx.fillRect(0, 0, w, h);
        for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
            const v = 190 + r() * 40 | 0;
            ctx.fillStyle = `rgb(${v},${v - 4},${v - 12})`;
            ctx.fillRect(x * s + 2, y * s + 2, s - 4, s - 4);
        }
        speckle(ctx, w, h, 5000, r, ["rgba(60,55,50,0.5)", "rgba(250,245,235,0.6)", "rgba(150,90,60,0.35)"]);
        noiseLayer(ctx, w, h, 64, 0.18, r);
        // scuffed walking path
        ctx.fillStyle = "rgba(40,30,20,0.12)";
        ctx.fillRect(0, h * 0.35, w, h * 0.3);
    },
    wood(ctx, w, h, r) {
        const planks = 6, s = h / planks;
        for (let i = 0; i < planks; i++) {
            const v = 170 + r() * 40 | 0;
            ctx.fillStyle = `rgb(${v},${v * 0.78 | 0},${v * 0.55 | 0})`;
            ctx.fillRect(0, i * s, w, s);
            ctx.strokeStyle = "rgba(60,35,15,0.35)";
            for (let k = 0; k < 12; k++) {
                ctx.beginPath();
                const y = i * s + r() * s;
                ctx.moveTo(0, y);
                ctx.bezierCurveTo(w * 0.3, y + (r() - 0.5) * 6, w * 0.6, y + (r() - 0.5) * 6, w, y);
                ctx.stroke();
            }
            ctx.fillStyle = "rgba(40,20,10,0.6)";
            ctx.fillRect(0, i * s, w, 2);
            ctx.fillRect((r() * w) | 0, i * s, 2, s);
        }
    },
    concrete(ctx, w, h, r) {
        ctx.fillStyle = "#c9c5bc"; ctx.fillRect(0, 0, w, h);
        noiseLayer(ctx, w, h, 48, 0.16, r);
        noiseLayer(ctx, w, h, 12, 0.08, r);
        speckle(ctx, w, h, 3000, r, ["rgba(70,65,60,0.35)", "rgba(255,255,255,0.35)"]);
        cracks(ctx, w, h, r, 8);
        grime(ctx, w, h, r, 0.4);
        // formwork seams
        ctx.fillStyle = "rgba(60,55,50,0.25)";
        ctx.fillRect(0, h / 2, w, 2); ctx.fillRect(w / 2, 0, 2, h);
    },
    tar(ctx, w, h, r) {
        ctx.fillStyle = "#9a968c"; ctx.fillRect(0, 0, w, h);
        noiseLayer(ctx, w, h, 16, 0.2, r);
        for (let i = 0; i < 18; i++) {
            ctx.fillStyle = `rgba(${40 + r() * 30},${40 + r() * 30},${40 + r() * 25},${0.2 + r() * 0.3})`;
            ctx.fillRect(r() * w, r() * h, 20 + r() * 120, 20 + r() * 90);
        }
        speckle(ctx, w, h, 2500, r, ["rgba(30,30,30,0.35)", "rgba(230,230,220,0.35)"]);
        // puddle stains
        for (let i = 0; i < 4; i++) {
            ctx.fillStyle = "rgba(60,70,80,0.18)";
            ctx.beginPath(); ctx.ellipse(r() * w, r() * h, 30 + r() * 50, 15 + r() * 30, 0, 0, Math.PI * 2); ctx.fill();
        }
    },
    rust(ctx, w, h, r) {
        // corrugated sheet with rust
        for (let x = 0; x < w; x += 16) {
            const g = ctx.createLinearGradient(x, 0, x + 16, 0);
            g.addColorStop(0, "#9aa0a0"); g.addColorStop(0.5, "#d8dcd8"); g.addColorStop(1, "#8a9090");
            ctx.fillStyle = g; ctx.fillRect(x, 0, 16, h);
        }
        for (let i = 0; i < 26; i++) {
            ctx.fillStyle = `rgba(${140 + r() * 40},${70 + r() * 30},${30},${0.25 + r() * 0.4})`;
            const x = r() * w;
            ctx.fillRect(x, r() * h * 0.3, 4 + r() * 20, h * (0.3 + r() * 0.7));
        }
        speckle(ctx, w, h, 1500, r, ["rgba(120,50,20,0.5)"]);
    },
    fabric(ctx, w, h, r) {
        ctx.fillStyle = "#f2efe8"; ctx.fillRect(0, 0, w, h);
        for (let y = 0; y < h; y += 3) { ctx.fillStyle = "rgba(0,0,0,0.04)"; ctx.fillRect(0, y, w, 1); }
        for (let x = 0; x < w; x += 3) { ctx.fillStyle = "rgba(0,0,0,0.03)"; ctx.fillRect(x, 0, 1, h); }
        noiseLayer(ctx, w, h, 64, 0.08, r);
    },
    grain(ctx, w, h, r) {
        ctx.fillStyle = "#e8e4dc"; ctx.fillRect(0, 0, w, h);
        noiseLayer(ctx, w, h, 16, 0.1, r);
        speckle(ctx, w, h, 1500, r, ["rgba(60,50,40,0.25)", "rgba(255,255,255,0.3)"]);
        grime(ctx, w, h, r, 0.18);
    }
};

// Building facades: a separate painter because it also needs an emissive map
// for lit windows (so bloom picks them up at night).
function paintFacade(seed) {
    const r = rng(seed);
    const [c, ctx] = canvas();
    const [e, ectx] = canvas();
    ectx.fillStyle = "#000"; ectx.fillRect(0, 0, SIZE, SIZE);
    painters.concrete(ctx, SIZE, SIZE, r);
    const cols = 4, rows = 3, cw = SIZE / cols, rh = SIZE / rows;
    for (let j = 0; j < rows; j++) {
        // floor slab line
        ctx.fillStyle = "rgba(50,45,40,0.45)";
        ctx.fillRect(0, j * rh + rh - 6, SIZE, 6);
        for (let i = 0; i < cols; i++) {
            const x = i * cw + cw * 0.18, y = j * rh + rh * 0.2, ww = cw * 0.64, hh = rh * 0.5;
            const lit = r() < 0.22;
            ctx.fillStyle = lit ? "#f3cf88" : (r() < 0.5 ? "#2a2e34" : "#3a4048");
            ctx.fillRect(x, y, ww, hh);
            if (lit) {
                ectx.fillStyle = r() < 0.7 ? "#ffcf80" : "#b8e0ff";
                ectx.fillRect(x, y, ww, hh);
                ctx.fillStyle = "rgba(120,80,40,0.35)";         // curtain
                ctx.fillRect(x, y, ww * (0.2 + r() * 0.4), hh);
            }
            // steel window frame + bars (the metal cages of Kowloon)
            ctx.strokeStyle = "#3c3a36"; ctx.lineWidth = 3;
            ctx.strokeRect(x, y, ww, hh);
            if (r() < 0.7) {
                ctx.strokeStyle = "rgba(60,58,54,0.9)"; ctx.lineWidth = 2;
                const cage = 6;
                ctx.strokeRect(x - cage, y - cage, ww + cage * 2, hh + cage * 2 + 8);
                for (let k = 1; k < 6; k++) { ctx.beginPath(); ctx.moveTo(x - cage + k * (ww + cage * 2) / 6, y - cage); ctx.lineTo(x - cage + k * (ww + cage * 2) / 6, y + hh + cage + 8); ctx.stroke(); }
                ctx.fillStyle = "#4a4640"; ctx.fillRect(x - cage, y + hh + cage + 4, ww + cage * 2, 5);
            }
            // AC unit
            if (r() < 0.45) {
                const ax = x + ww * (r() < 0.5 ? -0.05 : 0.55), ay = y + hh + 14;
                ctx.fillStyle = "#d0cec6"; ctx.fillRect(ax, ay, ww * 0.5, rh * 0.16);
                ctx.fillStyle = "#8a8880";
                for (let k = 0; k < 5; k++) ctx.fillRect(ax + 4, ay + 4 + k * 5, ww * 0.5 - 8, 2);
                ctx.fillStyle = "rgba(70,55,40,0.35)"; ctx.fillRect(ax + ww * 0.2, ay + rh * 0.16, 4, rh * 0.25); // drip
            }
            // laundry pole with clothes
            if (r() < 0.25) {
                ctx.strokeStyle = "#555"; ctx.lineWidth = 2;
                ctx.beginPath(); ctx.moveTo(x, y + hh + 2); ctx.lineTo(x + ww, y + hh + 2); ctx.stroke();
                for (let k = 0; k < 3; k++) {
                    ctx.fillStyle = ["#c9463a", "#3f6fa8", "#e8e2d4", "#d8b040"][(r() * 4) | 0];
                    ctx.fillRect(x + 6 + k * ww / 3, y + hh + 3, ww / 4, 18 + r() * 14);
                }
            }
        }
    }
    grime(ctx, SIZE, SIZE, r, 0.45);
    return [c, e];
}

function toTexture(c, srgb = true) {
    const t = new THREE.CanvasTexture(c);
    t.wrapS = t.wrapT = THREE.RepeatWrapping;
    if (srgb) t.colorSpace = THREE.SRGBColorSpace;
    t.anisotropy = 8;
    return t;
}

// Returns { map, normalMap, emissiveMap?, tile } where tile is metres per repeat.
export function surface(type) {
    if (cache[type]) return cache[type];
    let result;
    if (type === "facade") {
        const [c, e] = paintFacade(7);
        result = { map: toTexture(c), normalMap: toTexture(normalFrom(blurCopy(c, 1), 3), false),
            emissiveMap: toTexture(e), tile: [6, 4.5] };
    } else {
        const r = rng(type.length * 977 + type.charCodeAt(0));
        const [c, ctx] = canvas();
        painters[type](ctx, SIZE, SIZE, r);
        const tiles = { plaster: [3, 3], tiles: [2, 2], floor: [3, 3], wood: [2.5, 2.5], concrete: [4, 4],
            tar: [5, 5], rust: [2, 2], fabric: [1.5, 1.5], grain: [2, 2] };
        const strength = { plaster: 2.5, tiles: 4, floor: 2, wood: 3, concrete: 3, tar: 2, rust: 5, fabric: 1, grain: 1.5 };
        result = { map: toTexture(c), normalMap: toTexture(normalFrom(blurCopy(c, 1), strength[type]), false),
            tile: tiles[type] };
    }
    cache[type] = result;
    return result;
}

// Give a box's faces UVs in metres so textures keep their real-world scale
// no matter how long a wall is.
export function worldUV(geo, w, h, d, tile) {
    const uv = geo.attributes.uv;
    const [tu, tv] = tile;
    // BoxGeometry face order: +x, -x, +y, -y, +z, -z (4 verts each)
    const dims = [[d, h], [d, h], [w, d], [w, d], [w, h], [w, h]];
    for (let f = 0; f < 6; f++) {
        const [fu, fv] = dims[f];
        for (let k = 0; k < 4; k++) {
            const i = f * 4 + k;
            uv.setXY(i, uv.getX(i) * fu / tu, uv.getY(i) * fv / tv);
        }
    }
    uv.needsUpdate = true;
}
