import * as THREE from "three";

// HD-2D characters: hand-built pixel art (outlined, three-tone shading,
// walk and idle frames) drawn on camera-facing planes that are lit by the
// scene's lights and cast real shadows, like the sprites in HD-2D games.
//
// Each character is an atlas of 6 frames, 26 x 44 px:
//   0 stand, 1 step, 2 stand, 3 step (other foot), 4-5 idle breathing.

const FW = 26, FH = 44, FRAMES = 6;
const OUTLINE = "#1a1210";

export const billboards = [];   // every character plane, turned to face the camera each frame

function hex(c) { return typeof c === "string" ? parseInt(c.slice(1), 16) : c; }
function shade(c, f) {
    c = hex(c);
    let r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
    if (f < 0) { r *= 1 + f; g *= 1 + f; b *= 1 + f * 0.85; }         // darker, slightly cool
    else { r += (255 - r) * f; g += (255 - g) * f; b += (255 - b) * f * 0.8; } // lighter, slightly warm
    return `rgb(${r | 0},${g | 0},${b | 0})`;
}

// ---------------------------------------------------------------- painter

function paintFrame(ctx, ox, spec, frame) {
    const P = (x, y, c) => { ctx.fillStyle = c; ctx.fillRect(ox + 1 + x, 1 + y, 1, 1); };
    const R = (x0, y0, x1, y1, c) => { ctx.fillStyle = c; ctx.fillRect(ox + 1 + x0, 1 + y0, x1 - x0 + 1, y1 - y0 + 1); };

    const child = spec.build === "child";
    const legLen = child ? 7 : 10, torsoLen = child ? 9 : 12;
    const feet = 41;
    const step = frame === 1 ? 1 : frame === 3 ? -1 : 0;
    const bounce = frame === 1 || frame === 3 ? -1 : 0;
    const breathe = frame === 5 ? 1 : 0;
    const stoop = spec.stoop ? 1 : 0;

    const legTop = feet - 2 - legLen + 1;
    const torsoTop = legTop - torsoLen + bounce + breathe;
    const headTop = torsoTop - 12 + stoop;
    const hx = 7 + stoop;                          // head left x

    const skin = spec.skin || "#e0b48e";
    const top = spec.top, bottom = spec.bottom || "#2f3440", shoes = spec.shoes || "#241c18";
    const hair = spec.hair || "#1c1410";

    // --- legs (back leg first, darker)
    const legY0 = legTop + bounce, legY1 = feet - 2;
    const backX = 9 - step, frontX = 12 + step;
    R(backX, legY0, backX + 2, legY1, shade(bottom, -0.35));
    R(frontX, legY0, frontX + 2, legY1, bottom);
    P(frontX + 2, legY0 + 1, shade(bottom, -0.2));
    R(backX, feet - 1, backX + 3, feet, shade(shoes, -0.2));
    R(frontX, feet - 1, frontX + 3, feet, shoes);
    P(frontX + 3, feet - 1, shade(shoes, 0.3));
    if (spec.skirt) {
        R(8, legY0, 16, legY0 + 3, spec.skirt);
        R(15, legY0, 16, legY0 + 3, shade(spec.skirt, -0.3));
    }

    // --- back arm
    const armTop = torsoTop + 1;
    const armLen = child ? 7 : 9;
    const backArmX = 6 + (step < 0 ? 1 : step > 0 ? -1 : 0);
    R(backArmX, armTop, backArmX + 1, armTop + armLen, shade(top, -0.4));
    R(backArmX, armTop + armLen + 1, backArmX + 1, armTop + armLen + 2, shade(skin, -0.3));

    // --- torso
    const tx0 = 8, tx1 = 16;
    R(tx0, torsoTop, tx1, torsoTop + torsoLen - 1, top);
    R(tx1 - 1, torsoTop, tx1, torsoTop + torsoLen - 1, shade(top, -0.3));      // shadow side
    R(tx0, torsoTop + 1, tx0, torsoTop + torsoLen - 2, shade(top, 0.25));       // light side
    R(tx0 + 2, torsoTop, tx1 - 3, torsoTop, shade(top, 0.15));                  // shoulders
    if (spec.coat) {                                                           // open white coat
        R(tx0, torsoTop, tx0 + 2, torsoTop + torsoLen, spec.coat);
        R(tx1 - 2, torsoTop, tx1, torsoTop + torsoLen, shade(spec.coat, -0.12));
        R(tx0, torsoTop + torsoLen, tx1, torsoTop + torsoLen + 1, spec.coat);
    }
    if (spec.apron) {
        R(tx0 + 2, torsoTop + 3, tx1 - 2, torsoTop + torsoLen + 2, spec.apron);
        R(tx1 - 3, torsoTop + 3, tx1 - 2, torsoTop + torsoLen + 2, shade(spec.apron, -0.2));
        R(tx0 + 3, torsoTop + 2, tx1 - 3, torsoTop + 2, shade(spec.apron, -0.25));
    }
    if (spec.belt) R(tx0, torsoTop + torsoLen - 2, tx1, torsoTop + torsoLen - 2, spec.belt);

    // --- neck + head
    R(11 + stoop, torsoTop - 1, 13 + stoop, torsoTop - 1, shade(skin, -0.25));
    const hy = headTop;
    R(hx + 1, hy, hx + 9, hy + 10, skin);
    R(hx, hy + 1, hx, hy + 9, skin);
    R(hx + 10, hy + 2, hx + 10, hy + 8, skin);
    R(hx + 9, hy + 1, hx + 10, hy + 9, shade(skin, -0.18));                     // cheek shadow
    R(hx + 2, hy + 10, hx + 8, hy + 10, shade(skin, -0.22));                    // jaw
    P(hx + 3, hy + 6, shade(skin, -0.25));                                     // ear
    P(hx + 3, hy + 7, shade(skin, -0.25));
    // eyes (facing right)
    const eye = spec.eyes || "#2a1a14";
    R(hx + 6, hy + 5, hx + 6, hy + 6, eye);
    R(hx + 9, hy + 5, hx + 9, hy + 6, eye);
    P(hx + 6, hy + 5, shade(eye, 0.5));
    if (spec.blush) { P(hx + 5, hy + 8, spec.blush); P(hx + 9, hy + 8, spec.blush); }
    P(hx + 8, hy + 9, shade(skin, -0.35));                                     // mouth
    if (spec.glasses) {
        ctx.fillStyle = "#20242a";
        [[hx + 5, hy + 4], [hx + 8, hy + 4]].forEach(([x, y]) => {
            R(x, y, x + 2, y, "#20242a"); R(x, y + 3, x + 2, y + 3, "#20242a");
            R(x, y, x, y + 3, "#20242a");
        });
        R(hx + 7, hy + 5, hx + 7, hy + 5, "#20242a");
    }

    // --- hair
    const hl = shade(hair, 0.3), hd = shade(hair, -0.3);
    switch (spec.hairStyle) {
        case "bob":
            R(hx, hy - 1, hx + 9, hy + 3, hair);
            R(hx - 1, hy + 1, hx + 3, hy + 10, hair);          // back of the bob
            R(hx + 4, hy + 2, hx + 10, hy + 3, hair);          // fringe
            R(hx + 2, hy - 1, hx + 6, hy - 1, hl);
            R(hx - 1, hy + 8, hx + 2, hy + 10, hd);
            P(hx + 10, hy + 4, hair);
            break;
        case "bun":
            R(hx, hy - 1, hx + 9, hy + 2, hair);
            R(hx, hy + 2, hx + 3, hy + 7, hair);
            R(hx - 3, hy - 3, hx + 1, hy + 1, hair);           // bun at the back
            R(hx - 2, hy - 3, hx, hy - 2, hl);
            R(hx + 3, hy - 1, hx + 7, hy - 1, hl);
            break;
        case "cap":
            R(hx, hy + 1, hx + 2, hy + 6, hair);
            R(hx, hy - 2, hx + 9, hy + 2, spec.capColor || "#3d4a3a");
            R(hx + 7, hy + 2, hx + 12, hy + 3, shade(spec.capColor || "#3d4a3a", -0.3));   // brim
            R(hx + 2, hy - 2, hx + 6, hy - 2, shade(spec.capColor || "#3d4a3a", 0.3));
            break;
        case "bald":
            R(hx, hy + 2, hx + 3, hy + 7, hair);
            R(hx + 2, hy - 1, hx + 7, hy - 1, shade(skin, 0.2));
            P(hx + 4, hy, shade(skin, 0.35));
            break;
        case "grey":
            R(hx, hy - 1, hx + 9, hy + 2, hair);
            R(hx, hy + 2, hx + 3, hy + 8, hair);
            R(hx + 2, hy - 1, hx + 6, hy - 1, hl);
            break;
        default: // short
            R(hx, hy - 1, hx + 9, hy + 2, hair);
            R(hx, hy + 2, hx + 3, hy + 6, hair);
            R(hx + 8, hy + 2, hx + 10, hy + 3, hair);
            R(hx + 2, hy - 1, hx + 6, hy - 1, hl);
    }

    // --- front arm (over the torso)
    const fax = 13 + (step > 0 ? 1 : step < 0 ? -1 : 0);
    const carrying = spec.accessory === "box" || spec.accessory === "newspaper";
    if (!carrying) {
        R(fax, armTop, fax + 2, armTop + armLen, top);
        R(fax + 2, armTop, fax + 2, armTop + armLen, shade(top, -0.3));
        R(fax, armTop + armLen + 1, fax + 2, armTop + armLen + 2, skin);
        P(fax + 2, armTop + armLen + 2, shade(skin, -0.25));
        if (spec.coat) R(fax, armTop, fax + 2, armTop + armLen, spec.coat);
    }

    // --- accessories
    switch (spec.accessory) {
        case "camera": {
            for (let i = 0; i < 9; i++) P(9 + i * 0.7 | 0, torsoTop + 1 + i, "#3a2618");
            R(14, torsoTop + 8, 18, torsoTop + 11, "#e9e1cc");
            R(14, torsoTop + 11, 18, torsoTop + 11, "#b8ae98");
            R(16, torsoTop + 9, 17, torsoTop + 10, "#1c1c22");
            P(15, torsoTop + 8, "#d05040");
            break;
        }
        case "cane":
            R(19, torsoTop + 9, 19, feet, "#6b4a2b");
            R(17, torsoTop + 8, 19, torsoTop + 8, "#6b4a2b");
            R(fax, armTop + armLen, fax + 3, armTop + armLen + 1, skin);
            break;
        case "newspaper":
            R(11, armTop + 2, 20, armTop + 9, "#ebe4d2");
            R(19, armTop + 2, 20, armTop + 9, "#c9c0aa");
            for (let i = 0; i < 3; i++) R(12, armTop + 4 + i * 2, 18, armTop + 4 + i * 2, "#8a8478");
            R(12, armTop + 3, 15, armTop + 3, "#b0443a");
            R(10, armTop + 9, 12, armTop + 10, skin);
            break;
        case "box":
            R(9, armTop + 1, 20, armTop + 8, "#b08452");
            R(18, armTop + 1, 20, armTop + 8, "#8a6238");
            R(9, armTop + 4, 20, armTop + 4, "#d8c8a0");
            R(8, armTop + 6, 9, armTop + 7, skin);
            break;
        case "tray":
            R(fax - 1, armTop + armLen, fax + 5, armTop + armLen, "#c8ccd0");
            break;
    }
}

function outline(ctx, w, h) {
    const img = ctx.getImageData(0, 0, w, h);
    const d = img.data;
    const solid = (x, y) => x >= 0 && y >= 0 && x < w && y < h && d[(y * w + x) * 4 + 3] > 0;
    const add = [];
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        if (solid(x, y)) continue;
        if (solid(x - 1, y) || solid(x + 1, y) || solid(x, y - 1) || solid(x, y + 1)) add.push([x, y]);
    }
    ctx.fillStyle = OUTLINE;
    add.forEach(([x, y]) => ctx.fillRect(x, y, 1, 1));
}

function paintAtlas(spec) {
    const c = document.createElement("canvas");
    c.width = FW * FRAMES; c.height = FH;
    const ctx = c.getContext("2d");
    for (let f = 0; f < FRAMES; f++) {
        const fc = document.createElement("canvas");
        fc.width = FW; fc.height = FH;
        const fctx = fc.getContext("2d");
        paintFrame(fctx, 0, spec, f);
        outline(fctx, FW, FH);
        ctx.drawImage(fc, f * FW, 0);
    }
    return c;
}

// ---------------------------------------------------------------- billboards

const atlasCache = new Map();
function atlasFor(key, spec) {
    if (!atlasCache.has(key)) atlasCache.set(key, paintAtlas(spec));
    return atlasCache.get(key);
}

function pixelTexture(canvas, frames) {
    const t = new THREE.CanvasTexture(canvas);
    t.colorSpace = THREE.SRGBColorSpace;
    t.magFilter = THREE.NearestFilter;
    t.minFilter = THREE.NearestFilter;
    t.generateMipmaps = false;
    t.repeat.set(1 / frames, 1);
    return t;
}

// A character: a lit, shadow-casting plane with its feet at the origin.
export function makeCharacter(key, spec, height = 1.7) {
    const map = pixelTexture(atlasFor(key, spec), FRAMES);
    const planeH = height * (FH / 38), planeW = planeH * FW / FH;
    const geo = new THREE.PlaneGeometry(planeW, planeH);
    geo.translate(0, planeH / 2 - planeH * (2 / FH), 0);
    const mat = new THREE.MeshStandardMaterial({
        map, alphaTest: 0.5, side: THREE.DoubleSide, roughness: 0.9, metalness: 0,
        emissive: 0xffffff, emissiveMap: map, emissiveIntensity: 0.28   // keeps pixels readable in dim rooms
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = false;
    mesh.customDepthMaterial = new THREE.MeshDepthMaterial({
        depthPacking: THREE.RGBADepthPacking, map, alphaTest: 0.5, side: THREE.DoubleSide
    });
    mesh.userData.character = true;
    mesh.userData.frames = FRAMES;
    mesh.userData.baseScale = new THREE.Vector3(1, 1, 1);
    mesh.userData.frame = 0;
    billboards.push(mesh);
    return mesh;
}

export function setFrame(mesh, frame) {
    if (mesh.userData.frame === frame) return;
    mesh.userData.frame = frame;
    mesh.material.map.offset.x = frame / mesh.userData.frames;
}

// Character palettes (section 61 colour coding, now as pixel-art costumes).
export const Looks = {
    mei:         { top: "#e0823a", bottom: "#2e3a4a", hair: "#1c1410", hairStyle: "bob", accessory: "camera", blush: "#e89a80", shoes: "#6a2a24" },
    grandfather: { top: "#cdbd98", bottom: "#4a4436", hair: "#b9b6ad", hairStyle: "bald", accessory: "cane", stoop: true, skin: "#d6a882" },
    lau:         { top: "#5f9a62", bottom: "#33383a", hair: "#222", hairStyle: "short", glasses: true, coat: "#e9ede6" },
    chan:        { top: "#7d5aa0", bottom: "#3a2f45", hair: "#1e1a1a", hairStyle: "bun", apron: "#c9b99a" },
    son:         { top: "#3f78c0", bottom: "#2a2a2a", hair: "#141414", hairStyle: "short", build: "child", blush: "#e09a80" },
    ng:          { top: "#7a5a3c", bottom: "#3b3024", hair: "#555", hairStyle: "cap", capColor: "#4a5a48", belt: "#2a2018" },
    wong:        { top: "#d98aa3", bottom: "#4d3a42", hair: "#c9c6c0", hairStyle: "bun", stoop: true, skin: "#d8ae8c" },

    chopper:     { top: "#6f7d74", bottom: "#333", hair: "#222", hairStyle: "bun", apron: "#b9b2a0" },
    child:       { top: "#b0443a", bottom: "#333", hair: "#111", hairStyle: "short", build: "child", blush: "#e09a80" },
    fanman:      { top: "#5b6b7a", bottom: "#2d2d2d", hair: "#333", hairStyle: "cap", capColor: "#8a3a30" },
    worker:      { top: "#8a8466", bottom: "#3a3a3a", hair: "#222", hairStyle: "short", accessory: "box" },
    mahjong1:    { top: "#8c6d5a", bottom: "#333", hair: "#999", hairStyle: "bald", build: "child" },
    mahjong2:    { top: "#56707c", bottom: "#333", hair: "#222", hairStyle: "bun", build: "child" },
    mahjong3:    { top: "#9a8f6a", bottom: "#333", hair: "#444", hairStyle: "short", build: "child" },
    shopkeeper:  { top: "#6a5d7a", bottom: "#333", hair: "#444", hairStyle: "grey", accessory: "newspaper", glasses: true }
};

// ---------------------------------------------------------------- pigeons

let pigeonAtlas = null;
function paintPigeon() {
    const c = document.createElement("canvas");
    c.width = 16 * 2; c.height = 12;
    const ctx = c.getContext("2d");
    for (let f = 0; f < 2; f++) {
        const fc = document.createElement("canvas"); fc.width = 16; fc.height = 12;
        const g = fc.getContext("2d");
        const R = (x0, y0, x1, y1, col) => { g.fillStyle = col; g.fillRect(x0, y0, x1 - x0 + 1, y1 - y0 + 1); };
        const dy = f;                                   // head bob
        R(3, 5, 11, 9, "#8d9199");                      // body
        R(3, 8, 11, 9, "#767a82");
        R(1, 6, 3, 8, "#5c6068");                       // tail
        R(5, 5, 9, 6, "#a4a8b0");                       // wing light
        R(6, 7, 9, 7, "#4a4e56");                       // wing bars
        R(10, 2 + dy, 13, 5 + dy, "#6c7078");           // head
        R(10, 5 + dy, 12, 6 + dy, "#5d8a7a");           // iridescent neck
        R(14, 3 + dy, 14, 3 + dy, "#d08040");           // beak
        R(12, 3 + dy, 12, 3 + dy, "#e8a040");           // eye
        R(6, 10, 6, 11, "#c0605a"); R(9, 10, 9, 11, "#c0605a");
        outline(g, 16, 12);
        ctx.drawImage(fc, f * 16, 0);
    }
    return c;
}

export function makePigeon() {
    pigeonAtlas = pigeonAtlas || paintPigeon();
    const map = pixelTexture(pigeonAtlas, 2);
    const geo = new THREE.PlaneGeometry(0.56, 0.42);
    geo.translate(0, 0.21, 0);
    const mat = new THREE.MeshStandardMaterial({ map, alphaTest: 0.5, side: THREE.DoubleSide,
        emissive: 0xffffff, emissiveMap: map, emissiveIntensity: 0.25 });
    const m = new THREE.Mesh(geo, mat);
    m.castShadow = true;
    m.customDepthMaterial = new THREE.MeshDepthMaterial({ depthPacking: THREE.RGBADepthPacking, map, alphaTest: 0.5 });
    m.userData.frames = 2;
    m.userData.frame = 0;
    m.userData.pigeon = true;
    billboards.push(m);
    return m;
}

// ---------------------------------------------------------------- signs

// Painted shop-sign texture with Chinese and English lines.
export function signTexture(lines, { bg = "#a8453a", fg = "#f3e6c8", w = 256, h = 128 } = {}) {
    const c = document.createElement("canvas");
    c.width = w; c.height = h;
    const ctx = c.getContext("2d");
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = fg;
    ctx.lineWidth = 4;
    ctx.strokeRect(6, 6, w - 12, h - 12);
    ctx.fillStyle = fg;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    const step = h / (lines.length + 1);
    lines.forEach((line, i) => {
        const size = i === 0 ? Math.floor(h * 0.36) : Math.floor(h * 0.16);
        ctx.font = `bold ${size}px "Noto Serif TC", "Noto Sans TC", "PingFang TC", "Microsoft JhengHei", serif`;
        ctx.fillText(line, w / 2, step * (i + 1) + (i === 0 ? -4 : 6));
    });
    // grime
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, "rgba(0,0,0,0)"); g.addColorStop(1, "rgba(30,20,10,0.35)");
    ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.anisotropy = 4;
    return tex;
}

// Vertical neon shop sign (texture for an emissive panel).
export function neonTexture(text, color = "#ff4a5a", { w = 96, h = 320 } = {}) {
    const c = document.createElement("canvas");
    c.width = w; c.height = h;
    const ctx = c.getContext("2d");
    ctx.fillStyle = "#140c10";
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = color;
    ctx.lineWidth = 5;
    ctx.shadowColor = color; ctx.shadowBlur = 12;
    ctx.strokeRect(8, 8, w - 16, h - 16);
    ctx.fillStyle = "#fff4f0";
    ctx.textAlign = "center"; ctx.textBaseline = "middle";
    const chars = [...text];
    const size = Math.min(w * 0.62, (h - 40) / chars.length * 0.85);
    ctx.font = `700 ${size}px "Noto Serif TC", "Noto Sans TC", "PingFang TC", serif`;
    chars.forEach((ch, i) => {
        const y = 20 + (h - 40) * (i + 0.5) / chars.length;
        ctx.shadowColor = color; ctx.shadowBlur = 16;
        ctx.fillStyle = color; ctx.fillText(ch, w / 2, y);
        ctx.shadowBlur = 0; ctx.fillStyle = "#fff6f2"; ctx.fillText(ch, w / 2, y);
    });
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    return tex;
}

// kept for compatibility with older callers
export function characterTexture(key, spec) {
    return pixelTexture(atlasFor(key, spec), FRAMES);
}
