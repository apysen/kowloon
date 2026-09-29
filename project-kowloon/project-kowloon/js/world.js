import * as THREE from "three";
import { GameState } from "./gameState.js";
import { addFloor, addObstacle, floors } from "./collision.js";
import { makeCharacter, makePigeon, Looks, signTexture, neonTexture, billboards, setFrame } from "./sprites.js";
import { surface, worldUV } from "./textures.js";

// Graybox Kowloon (sections 15-17, 26-27, 34, 62-64).
//
// Three stacked levels share one footprint:
//   Level A  y = 0   apartment, hall, hidden corridor, Lau's clinic
//   Level B  y = 5   landing, Chan's room, airshaft base, catwalk, Mrs. Wong
//   Roof     y = 13  Mr. Ng's pigeons, water tank, laundry lines
//
// Visibility "bands": geometry above the player's level is hidden (cutaway),
// and walls/buildings on the camera side of the player fade out.

export const GRID = 2;
export const LEVEL = { A: 0, B: 5, ROOF: 13 };

const PAL = {
    concrete: 0x8a8c86,
    dirtyGreen: 0x6f7d62,
    warmYellow: 0xc9a55a,
    rust: 0x8a5a3a,
    fadedRed: 0xa8534a,
    pipeBlue: 0x2f74c0,
    fluoro: 0xeef3f0
};

// Deterministic RNG so the city is the same every load.
function rng(seed) {
    let s = seed >>> 0;
    return () => {
        s = (s + 0x6D2B79F5) >>> 0;
        let t = s;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

const eachMat = (o, fn) => {
    if (!o.material) return;
    if (Array.isArray(o.material)) o.material.forEach(fn); else fn(o.material);
};

function bandOf(y) {
    if (y < 4.9) return 0;
    if (y < 8.9) return 1;
    if (y < 12.4) return 1.5;
    return 2;
}

export class World {
    constructor(scene) {
        this.scene = scene;
        this.items = [];          // { obj, band, fadeable, box, opacity }
        this.closedRooms = [];    // { id, rects: [[x0,x1,z0,z1]], y } rooms that stay shut until entered
        this.doors = [];          // real doors: solid until discovered and opened
        this.holds = [];          // airshaft handholds: usable once seen
        this.currentRoom = null;
        this.npcs = {};
        this.refs = {};
        this.lights = [];
        this.cloths = [];
        this.pigeons = [];
        this.rand = rng(1993);
        this.roofMix = 0;
        this.time = 0;

        this.shared = {};

        this.buildLighting();
        this.buildLevelA();
        this.buildLevelB();
        this.buildAirshaft();
        this.buildRoof();
        this.buildPipes();
        this.buildFiller();
        this.buildDistantCity();
        this.buildDressing();
        const ground = this.box(-40, 60, -0.9, -0.35, -60, 30, 0x5a5650, { band: 0, surface: "concrete", castShadow: false });
        void ground;
        this.buildCharacters();
        this.tagRoomContents();
    }

    // Furniture and people inside a closed room are only drawn while Mei is
    // in it. (The shell may fade when it stands in front of her; the inside
    // stays secret until she walks in.)
    tagRoomContents() {
        const c = new THREE.Vector3();
        for (const it of this.items) {
            if (it.room || it.isFloor || it.obj.userData.character) continue;
            it.box.getCenter(c);
            const id = this.roomAtPoint(c);
            if (id) it.contentOf = id;
        }
    }

    roomAtPoint(c) {
        for (const r of this.closedRooms) {
            if (c.y < r.y - 0.1 || c.y > r.y + 4.2) continue;
            for (const [x0, x1, z0, z1] of r.rects) {
                if (c.x > x0 && c.x < x1 && c.z > z0 && c.z < z1) return r.id;
            }
        }
        return null;
    }

    // ------------------------------------------------------------------
    // Primitive helpers
    // ------------------------------------------------------------------

    mat(color, opts = {}) {
        return new THREE.MeshStandardMaterial({
            color, roughness: 0.88, metalness: 0.02, ...opts
        });
    }

    // Material using one of the procedural HD surfaces, tinted by colour.
    surfaceMat(type, color, extra = {}) {
        const S = surface(type);
        const o = { map: S.map, normalMap: S.normalMap, normalScale: new THREE.Vector2(0.8, 0.8), ...extra };
        if (S.emissiveMap) Object.assign(o, { emissive: 0xffffff, emissiveMap: S.emissiveMap, emissiveIntensity: 0.85 });
        return this.mat(color, o);
    }

    // Axis-aligned box from extents. Registers it for band visibility.
    box(x0, x1, y0, y1, z0, z1, color, opts = {}) {
        const w = Math.abs(x1 - x0), h = Math.abs(y1 - y0), d = Math.abs(z1 - z0);
        const geo = new THREE.BoxGeometry(w, h, d);
        let material = opts.material;
        if (!material) {
            const type = opts.surface === undefined ? "grain" : opts.surface;
            if (type) {
                worldUV(geo, w, h, d, surface(type).tile);
                const side = this.surfaceMat(type, color, opts.matOpts);
                if (opts.topSurface) {
                    const top = this.surfaceMat(opts.topSurface, opts.topColor ?? color, opts.matOpts);
                    material = [side, side, top, top, side, side];
                } else material = side;
            } else material = this.mat(color, opts.matOpts);
        }
        const mesh = new THREE.Mesh(geo, material);
        mesh.castShadow = opts.castShadow ?? true;
        mesh.receiveShadow = true;
        mesh.position.set((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2);
        this.scene.add(mesh);
        const item = this.register(mesh, {
            band: opts.band ?? bandOf(Math.min(y0, y1) + 0.5),
            fadeable: opts.fadeable ?? false
        });
        if (opts.room) item.room = opts.room;
        if (opts.collide) {
            addObstacle(x0, x1, z0, z1, opts.collideY ?? Math.min(y0, y1), { name: opts.name });
        }
        return mesh;
    }

    register(obj, { band = 0, fadeable = false } = {}) {
        obj.updateMatrixWorld(true);
        const item = {
            obj, band, fadeable,
            box: new THREE.Box3().setFromObject(obj),
            opacity: 1
        };
        if (fadeable) {
            obj.traverse(o => {
                if (!o.material) return;
                o.material = Array.isArray(o.material) ? o.material.map(m => m.clone()) : o.material.clone();
                eachMat(o, m => { m.transparent = false; });
            });
        }
        this.items.push(item);
        return item;
    }

    // Room = floor slab + walls just outside the rectangle, with openings.
    // open: { n: [[a,b]], s: [...], e: [...], w: [...] } coordinates along the wall
    // skip: sides with no wall at all.
    // id: a closed room. Its walls never fade and a lid covers it until Mei
    // is inside, so what's in it (and any door on its far side) stays hidden.
    room({ x0, x1, z0, z1, y, h = 4.2, wall = PAL.concrete, floor = 0x55504a,
        open = {}, skip = [], name = "", band, wallBand, lintel = true, id = null,
        wallSurface = "plaster", floorSurface = "floor" }) {
        const T = 0.3;
        addFloor(x0, x1, z0, z1, y, name);
        this.box(x0 - T, x1 + T, y - 0.3, y, z0 - T, z1 + T, floor, { band: band ?? bandOf(y + 0.2), surface: floorSurface });
        this.items[this.items.length - 1].isFloor = true;
        if (id) this.closedRoom(id, [x0, x1, z0, z1], y, h, band ?? bandOf(y + 0.2));

        const wb = wallBand ?? band;
        const sides = {
            n: { a0: x0 - T, a1: x1 + T, fixed: z0 - T / 2, axis: "x" },
            s: { a0: x0 - T, a1: x1 + T, fixed: z1 + T / 2, axis: "x" },
            w: { a0: z0, a1: z1, fixed: x0 - T / 2, axis: "z" },
            e: { a0: z0, a1: z1, fixed: x1 + T / 2, axis: "z" }
        };

        for (const [side, s] of Object.entries(sides)) {
            if (skip.includes(side)) continue;
            const gaps = (open[side] || []).slice().sort((a, b) => a[0] - b[0]);
            let cursor = s.a0;
            const segments = [];
            for (const [g0, g1] of gaps) {
                if (g0 > cursor) segments.push([cursor, g0]);
                cursor = Math.max(cursor, g1);
            }
            if (cursor < s.a1) segments.push([cursor, s.a1]);

            const build = (a, b, yy0, yy1) => {
                let m;
                if (s.axis === "x") {
                    m = this.box(a, b, yy0, yy1, s.fixed - T / 2, s.fixed + T / 2, wall,
                        { fadeable: true, band: wb, room: id, surface: wallSurface });
                } else {
                    m = this.box(s.fixed - T / 2, s.fixed + T / 2, yy0, yy1, a, b, wall,
                        { fadeable: true, band: wb, room: id, surface: wallSurface });
                }
                m.userData.side = side;
                return m;
            };

            segments.forEach(([a, b]) => build(a, b, y, y + h));
            if (lintel) gaps.forEach(([a, b]) => build(a, b, y + 2.7, y + h));
        }
    }

    // Register (or extend) a closed room and give that part of it a lid.
    closedRoom(id, rect, y, h = 4.2, band = bandOf(y + 0.2)) {
        let r = this.closedRooms.find(c => c.id === id);
        if (!r) { r = { id, rects: [], y }; this.closedRooms.push(r); }
        r.rects.push(rect);
        const [x0, x1, z0, z1] = rect;
        const lid = this.box(x0 - 0.3, x1 + 0.3, y + h, y + h + 0.25, z0 - 0.3, z1 + 0.3, 0x8a857a,
            { fadeable: true, band, room: id, surface: "concrete", topSurface: "tar" });
        this.items[this.items.length - 1].isLid = true;
        void lid;
    }

    roomAt(p) {
        for (const r of this.closedRooms) {
            if (Math.abs(p.y - r.y) > 2) continue;
            for (const [x0, x1, z0, z1] of r.rects) {
                if (p.x > x0 && p.x < x1 && p.z > z0 && p.z < z1) return r.id;
            }
        }
        return null;
    }

    // A real door in a wall opening. normal points to the side Mei first
    // approaches from. Solid until it has been discovered and opened.
    door({ id, x, z, y, normal, width = 1.4, color = 0x4f6470, band = 0, room = null, lightSpill = false }) {
        const n = new THREE.Vector3(...normal);
        const ax = Math.abs(n.x) > 0.5;
        const tangent = new THREE.Vector3(-n.z, 0, n.x);
        const hingePos = new THREE.Vector3(x, y, z).addScaledVector(tangent, -width / 2);
        const pivot = new THREE.Group();
        pivot.position.copy(hingePos);
        const baseYaw = Math.atan2(-tangent.z, tangent.x);   // panel runs along the wall
        pivot.rotation.y = baseYaw;
        const panel = new THREE.Mesh(new THREE.BoxGeometry(width, 2.6, 0.1), this.mat(color));
        panel.position.set(width / 2, 1.3, 0);
        pivot.add(panel);
        const knob = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 0.22), this.mat(0xc9a55a, { metalness: 0.4 }));
        knob.position.set(width - 0.18, 1.2, 0);
        pivot.add(knob);
        // "Staff only" plate (閒人免進), the classic Hong Kong service-door sign
        const plateTex = signTexture(["閒人免進", "STAFF ONLY"], { bg: "#f2eee4", fg: "#b0302a", w: 256, h: 128 });
        const plate = new THREE.Mesh(new THREE.PlaneGeometry(0.62, 0.3),
            new THREE.MeshStandardMaterial({ map: plateTex, emissiveMap: plateTex, emissive: 0x6a5a48, roughness: 0.6 }));
        plate.position.set(width / 2, 1.75, -0.056);   // on the face that looks back down the hall
        plate.rotation.y = Math.PI;
        pivot.add(plate);
        panel.castShadow = panel.receiveShadow = true;
        this.scene.add(pivot);
        this.register(pivot, { band });

        // Door frame, so the opening reads as a doorway from the side it faces.
        const fw = 0.12, frameCol = 0x3a3632;
        const along = (a, b, y0, y1) => ax
            ? this.box(x - 0.2, x + 0.2, y + y0, y + y1, z + a, z + b, frameCol, { band, surface: null })
            : this.box(x + a, x + b, y + y0, y + y1, z - 0.2, z + 0.2, frameCol, { band, surface: null });
        along(-width / 2 - fw, -width / 2, 0, 2.75);
        along(width / 2, width / 2 + fw, 0, 2.75);
        along(-width / 2 - fw, width / 2 + fw, 2.62, 2.75);

        const half = width / 2 + 0.05;
        const obstacle = addObstacle(
            ax ? x - 0.18 : x - half, ax ? x + 0.18 : x + half,
            ax ? z - half : z - 0.18, ax ? z + half : z + 0.18, y, { name: id });
        const d = { id, pos: new THREE.Vector3(x, y, z), normal: n, tangent, width, pivot, obstacle, baseYaw,
            room, discovered: false, open: false, openT: 0 };
        obstacle.active = () => !d.open;

        if (lightSpill) {
            // Light spilling under the door onto the floor: visible from the
            // starting view even though the door itself is edge-on.
            const spill = new THREE.Mesh(new THREE.PlaneGeometry(1.4, width * 1.1),
                new THREE.MeshBasicMaterial({ color: 0xffd890, transparent: true, opacity: 0.7, depthWrite: false }));
            spill.rotation.x = -Math.PI / 2;
            spill.rotation.z = ax ? 0 : Math.PI / 2;
            spill.position.set(x + n.x * 0.8, y + 0.02, z + n.z * 0.8);
            const glow = new THREE.PointLight(0xffc878, 4, 3.5, 1.5);
            glow.position.set(x + n.x * 0.5, y + 0.4, z + n.z * 0.5);
            this.scene.add(glow);
            d.glow = glow;
            this.scene.add(spill);
            this.register(spill, { band });
            d.spill = spill;
        }
        this.doors.push(d);
        return d;
    }

    openDoor(d) {
        d.open = true;
        if (d.spill) { d.spill.userData.gone = true; d.spill.visible = false; }
    }

    // An airshaft handhold. normal = the way its usable face points (null: visible from anywhere).
    hold(id, name, mesh, normal, climbPoint) {
        this.holds.push({ id, name, mesh, normal: normal ? new THREE.Vector3(...normal) : null,
            point: climbPoint, discovered: false });
    }

    // ------------------------------------------------------------------
    // Lighting
    // ------------------------------------------------------------------

    buildLighting() {
        const scene = this.scene;
        this.hemi = new THREE.HemisphereLight(0xc8ccd0, 0x3a3228, 1.0);
        scene.add(this.hemi);

        this.sun = new THREE.DirectionalLight(0xfff0d8, 0.5);
        this.sun.castShadow = true;
        this.sun.shadow.mapSize.set(2048, 2048);
        const sc = this.sun.shadow.camera;
        sc.left = -18; sc.right = 18; sc.top = 18; sc.bottom = -18; sc.near = 1; sc.far = 90;
        this.sun.shadow.bias = -0.0004;
        this.sun.shadow.normalBias = 0.03;
        scene.add(this.sun);
        scene.add(this.sun.target);

        const point = (x, y, z, color, intensity, dist = 11) => {
            intensity *= 1.9;
            const l = new THREE.PointLight(color, intensity, dist * 1.2, 1.5);
            l.position.set(x, y, z);
            l.userData.base = intensity;
            l.userData.band = y < 4.9 ? 0 : 1;
            scene.add(l);
            this.lights.push(l);
            return l;
        };

        point(-10, 3.4, -0.5, 0xffc47e, 16);       // apartment
        point(-2, 3.6, 0, 0xe6f0ff, 12);           // hall fluorescent
        point(-2, 3.4, 2.6, 0xffd08a, 9, 7);       // mahjong alcove
        point(3, 3.4, -5, 0xffd9a0, 10);           // hidden corridor bulb
        point(4, 3.6, -12, 0xdcf7ec, 18);          // clinic
        point(9.3, 3.5, -13.5, 0xffe0b0, 7, 7);    // stairwell
        point(3, 8.4, -12, 0xffd39a, 11);          // level B corridor
        point(-5, 8.4, -12.5, 0xffbf7a, 14);       // Chan
        point(10, 8.4, -13, 0xfff0d0, 8, 7);       // landing
        point(-5, 10, -18.5, 0xbfd6ff, 9, 10);     // airshaft
        point(27.5, 8.4, -12, 0xffc07a, 14);       // Wong
        point(30.3, 6.6, -15.2, 0xff4a3a, 5, 4);   // Wong's altar lamp
        point(18, 8, -12, 0xfff3d6, 7, 9);         // catwalk
        point(-12.8, 1.5, -1, 0xff5a3a, 3, 3.5);   // family altar
    }

    // ------------------------------------------------------------------
    // Level A
    // ------------------------------------------------------------------

    buildLevelA() {
        const Y = LEVEL.A;

        // Mei's apartment
        this.room({
            x0: -14, x1: -6, z0: -4, z1: 4, y: Y, name: "apartment", id: "apartment", floorSurface: "wood",
            wall: 0x9a977a, floor: 0x6b5a45,
            open: { e: [[-1, 1]] }
        });
        this.box(-14, -12, Y, Y + 0.6, 1.8, 4, 0x8a6f5a, { collide: true, name: "bed" });
        this.box(-14, -12, Y + 0.6, Y + 0.75, 1.8, 2.6, 0xd8d0bd);
        this.box(-12.2, -10.8, Y, Y + 0.8, -1.2, 0.2, 0x6b4a30, { collide: true, name: "table" });
        this.box(-11.9, -11.3, Y + 0.8, Y + 0.95, -0.8, -0.3, 0xe8e2d0); // rice bowls
        this.box(-14, -13.4, Y, Y + 1.5, -2.2, -0.4, 0x5d4632, { collide: true, name: "shelf" });
        const radio = this.box(-13.95, -13.45, Y + 1.5, Y + 1.85, -1.8, -0.9, 0x7a2e22);
        this.refs.radio = radio;
        this.box(-13.95, -13.6, Y + 1.2, Y + 1.8, -1.2, -1.0, 0xa8453a); // altar
        // standing fan
        this.box(-7.1, -6.9, Y, Y + 1.2, 3.1, 3.3, 0x444444);
        this.refs.fan = this.box(-7.4, -6.6, Y + 1.2, Y + 1.9, 3.15, 3.25, 0x7da0a8);

        // Packing boxes, present from the very first frame (section 56).
        const boxCol = 0xa8834f;
        // They sit against the back wall, behind Grandfather's chair.
        this.box(-13.9, -12.7, Y, Y + 0.8, -3.95, -3.1, boxCol, { collide: true, name: "boxes" });
        this.box(-12.6, -11.5, Y, Y + 0.7, -3.95, -3.2, 0x9c7a48, { collide: true });
        this.box(-13.7, -12.9, Y + 0.8, Y + 1.4, -3.9, -3.2, 0xb08c58);
        this.box(-13.7, -12.9, Y + 1.12, Y + 1.18, -3.92, -3.18, 0xd8cfa8); // tape
        this.box(-13.62, -12.98, Y + 0.3, Y + 0.55, -3.09, -3.08, 0x3a2a1a); // marker label
        this.refs.boxesPos = new THREE.Vector3(-12.3, 0, -2.6);


        // Hall. It ends at a wall with an old service door set in it. The door
        // faces back down the hall, so from the starting view it's edge-on and
        // can't be seen; from the west it's plain as day.
        this.room({
            x0: -6, x1: 2, z0: -1, z1: 1, y: Y, name: "hall",
            wall: 0x7c7f74, floor: 0x4e4a44,
            open: { s: [[-4, 0]], e: [[-0.7, 0.7]] }, skip: ["w"]
        });
        this.refs.serviceDoor = this.door({
            id: "serviceDoor", x: 2.15, z: 0, y: Y, normal: [-1, 0, 0], width: 1.4,
            color: 0x7a93a0, band: 0, room: "corridor", lightSpill: true
        });

        // Hall clutter
        this.box(-5.8, -5.2, Y, Y + 0.5, 0.45, 0.95, 0x5c6b4a); // bucket crate
        this.box(-0.9, -0.3, Y, Y + 0.4, 0.5, 0.95, 0x3d4a52);  // fan parts

        // Mahjong alcove
        this.room({
            x0: -4, x1: 0, z0: 1, z1: 4, y: Y, name: "alcove",
            wall: 0x8a7a62, floor: 0x5a4c3c, skip: ["n"]
        });
        this.box(-2.8, -1.2, Y, Y + 0.75, 2.0, 3.3, 0x2e5a3a, { collide: true, name: "mahjong" });
        for (let i = 0; i < 10; i++) {
            const x = -2.6 + (i % 5) * 0.3, z = 2.2 + Math.floor(i / 5) * 0.8;
            this.box(x, x + 0.18, Y + 0.75, Y + 0.85, z, z + 0.12, 0xece6d4);
        }
        this.box(-3.95, -3.3, Y, Y + 0.8, 2.5, 3.5, 0x6b4a30, { collide: true }); // chopping table

        // Hidden corridor to Lau's
        this.room({
            x0: 2, x1: 4, z0: -9, z1: 1, y: Y, name: "corridor",
            wall: 0x77705e, floor: 0x4a463e, id: "corridor",
            open: { w: [[-6, -4], [-1.3, 1.3]] }, skip: ["n"]
        });
        // Newspaper stall
        this.room({
            x0: 0, x1: 2, z0: -6, z1: -4, y: Y, name: "stall",
            wall: 0x6a6a55, floor: 0x4a463e, skip: ["e"], id: "corridor"
        });
        this.box(1.3, 1.7, Y, Y + 1.0, -5.9, -4.1, 0x7a5c3a, { collide: true }); // counter
        this.box(0.05, 0.5, Y, Y + 2.2, -5.9, -4.1, 0x5a4a38); // magazine rack
        for (let i = 0; i < 4; i++) {
            this.box(0.5, 0.55, Y + 0.5 + i * 0.4, Y + 0.8 + i * 0.4, -5.8, -4.2,
                [0xc94f3f, 0xe0c060, 0x4f7fb0, 0xe8e2d0][i]);
        }

        // Lau's clinic
        this.room({
            x0: 0, x1: 8, z0: -15, z1: -9, y: Y, name: "clinic", id: "clinic", wallSurface: "tiles", floorSurface: "tiles",
            wall: 0x8fb3a2, floor: 0xb9c2b8,
            open: { s: [[2, 4]], e: [[-15, -12]] }
        });
        // dental chair
        this.box(4.3, 5.8, Y, Y + 0.6, -13.3, -11.7, 0xd8d6cc, { collide: true, name: "chair" });
        this.box(4.3, 4.7, Y + 0.6, Y + 1.5, -13.3, -11.7, 0x3f7a78);
        this.box(4.7, 5.8, Y + 0.6, Y + 0.8, -13.1, -11.9, 0x3f7a78);
        this.box(5.9, 6.0, Y, Y + 2.2, -13.5, -13.4, 0x999999);
        this.box(5.2, 6.0, Y + 2.1, Y + 2.2, -13.5, -12.3, 0x999999);
        this.box(5.1, 5.5, Y + 1.9, Y + 2.1, -12.5, -12.1, 0xfff8d0, { matOpts: { emissive: 0x665a30 } });
        // tray + cabinet + half-packed boxes
        this.box(6.4, 7.2, Y, Y + 0.9, -14.9, -14.3, 0xdcdcd4, { collide: true });
        this.box(6.6, 8, Y, Y + 1.3, -15, -14.4, 0xe0e4de, { collide: true });
        this.box(0.2, 1.6, Y, Y + 0.7, -14.8, -13.4, 0xa8834f, { collide: true });
        this.box(0.3, 1.4, Y + 0.7, Y + 1.2, -14.6, -13.7, 0x9c7a48);
        this.box(0.2, 1.3, Y, Y + 0.6, -10.8, -9.3, 0xa8834f, { collide: true });
        this.box(0.05, 0.1, Y + 1.2, Y + 2.2, -12.8, -11.2, 0xf4f0e4); // certificate

        // Hanging vertical sign: a landmark visible over the rooftops of Level A.
        const signMat = new THREE.MeshBasicMaterial({ map: signTexture(["劉牙科", "LAU DENTAL"], { w: 256, h: 128 }) });
        const sign = new THREE.Mesh(new THREE.PlaneGeometry(2.4, 1.2), signMat);
        sign.position.set(3, Y + 5.3, -8.65);
        this.scene.add(sign);
        this.register(sign, { band: 0 });
        const signBack = this.box(1.75, 4.25, Y + 4.65, Y + 5.95, -8.8, -8.7, 0x5a2a22, { band: 0 });
        this.box(2.9, 3.1, Y + 4.2, Y + 4.7, -8.8, -8.7, 0x333333, { band: 0 });
        this.refs.lauSign = sign;
        void signBack;

        // Stairwell
        this.room({
            x0: 8, x1: 10.5, z0: -15, z1: -12, y: Y, name: "stairwell", id: "clinic",
            wall: 0x6d6a60, floor: 0x4a463e, skip: ["w"]
        });
        for (let i = 0; i < 6; i++) {
            this.box(9.9, 10.5, Y, Y + 0.35 * (i + 1), -12.3 - i * 0.45, -12.75 - i * 0.45, 0x5d5a52);
        }
        this.refs.stairsUpA = new THREE.Vector3(9.4, Y, -14.2);

        // Ground under the catwalk light well
        this.box(11, 25, -0.3, 0, -17, -7, 0x3a3833, { band: 0 });
        for (let i = 0; i < 9; i++) {
            const x = 12 + this.rand() * 11, z = -16 + this.rand() * 8;
            this.box(x, x + 0.6 + this.rand(), 0, 0.3 + this.rand() * 0.9, z, z + 0.5 + this.rand(),
                [0x5a4a38, 0x6f7d62, 0x3d4a52, 0x8a5a3a][i % 4], { band: 0 });
        }
    }

    // ------------------------------------------------------------------
    // Level B
    // ------------------------------------------------------------------

    buildLevelB() {
        const Y = LEVEL.B;

        // Landing above the stairwell
        this.room({
            x0: 8, x1: 12, z0: -15, z1: -11, y: Y, name: "landing",
            wall: 0x7a7466, floor: 0x4e4a42,
            open: { w: [[-13, -11]], e: [[-13, -11]] }
        });
        // roof door (drawn into the north wall)
        this.box(9.9, 10.9, Y, Y + 2.3, -15.05, -14.95, 0x6a3f2c);
        this.refs.stairsDownB = new THREE.Vector3(8.7, Y, -14.3);
        this.refs.roofDoorB = new THREE.Vector3(10.4, Y, -14.4);
        for (let i = 0; i < 4; i++) {
            this.box(8.05, 8.6, Y - 0.35 * (i + 1), Y, -14.9 + i * 0.5, -14.45 + i * 0.5, 0x5d5a52, { band: 1 });
        }

        // Corridor toward Chan
        this.room({
            x0: -2, x1: 8, z0: -13, z1: -11, y: Y, name: "corridorB",
            wall: 0x807868, floor: 0x4a4640, skip: ["w", "e"]
        });
        this.box(6.2, 7.6, Y, Y + 0.9, -12.95, -12.45, 0xa8834f, { collide: true }); // stacked boxes
        this.box(6.4, 7.4, Y + 0.9, Y + 1.5, -12.9, -12.5, 0x9c7a48);
        // A small sign pointing nowhere useful, for flavor
        const s2 = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 0.7),
            new THREE.MeshBasicMaterial({ map: signTexture(["陳記", "TAILOR"], { bg: "#4a5a3a", w: 256, h: 128 }) }));
        s2.position.set(-0.8, Y + 3.1, -13.12);
        this.scene.add(s2);
        this.register(s2, { band: 1 });

        // Mrs. Chan's room (tailoring and laundry)
        this.room({
            x0: -8, x1: -2, z0: -16, z1: -9, y: Y, name: "chan", id: "chan",
            wall: 0x8c8294, floor: 0x5a4c4a,
            open: { e: [[-13, -11]], n: [[-6, -4]] }
        });
        this.box(-8, -6.6, Y, Y + 0.85, -11.5, -9.2, 0x6b4a30, { collide: true }); // sewing table
        this.box(-7.6, -7.0, Y + 0.85, Y + 1.2, -10.8, -10.2, 0x2a2a2a);       // machine
        this.box(-4.2, -3.2, Y, Y + 0.5, -10.2, -9.2, 0x5f7a88, { collide: true }); // basin
        this.box(-8, -7.2, Y, Y + 1.8, -15.9, -14.2, 0x5d4632, { collide: true });   // cabinet
        this.laundryLine(-7.8, -2.4, Y + 2.8, -14.6, "x", [0xd8c4a0, 0x5a7ab0, 0xe8e2d4, 0xb0504a]);

        // Catwalk (open-air, over a light well)
        addFloor(12, 24, -13, -11, Y, "catwalk");
        this.box(12, 24, Y - 0.15, Y, -13, -11, 0x565a5e, { band: 1 });
        for (let x = 12.5; x < 24; x += 1.5) {
            this.box(x, x + 0.08, Y - 1.2, Y - 0.15, -12.1, -11.9, 0x3a3a3a, { band: 1 });
        }
        [-13.05, -10.95].forEach(z => {
            this.box(12, 24, Y + 0.95, Y + 1.02, z - 0.04, z + 0.04, 0x6a6e70, { band: 1 });
            for (let x = 12; x <= 24; x += 1) {
                this.box(x, x + 0.06, Y, Y + 1.0, z - 0.03, z + 0.03, 0x6a6e70, { band: 1 });
            }
        });

        // The wet fabric (section 43). The same object later hangs on the roof.
        const fabric = new THREE.Group();
        const colors = [0x3f6fa8, 0xc9a55a, 0xa8534a];
        colors.forEach((c, i) => {
            const cloth = new THREE.Mesh(
                new THREE.PlaneGeometry(0.72, 2.0, 1, 6),
                new THREE.MeshStandardMaterial({ color: c, side: THREE.DoubleSide, roughness: 1, map: surface("fabric").map, normalMap: surface("fabric").normalMap })
            );
            cloth.position.set(0, -1.05, -0.78 + i * 0.78);
            cloth.rotation.y = Math.PI / 2;
            fabric.add(cloth);
            this.cloths.push(cloth);
        });
        const line = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.04, 2.4), this.mat(0x222222));
        fabric.add(line);
        fabric.position.set(16, Y + 2.6, -12);
        this.scene.add(fabric);
        this.fabricItem = this.register(fabric, { band: 1 });
        this.refs.fabric = fabric;
        // "catwalk" -> "bundle" (in the Chan boy's arms) -> "roof"
        this.fabricState = "catwalk";
        addObstacle(15.7, 16.3, -13, -11, Y, { name: "fabric", active: () => this.fabricState === "catwalk" });

        // The folded bundle he carries between the catwalk and the roof.
        const bundle = new THREE.Group();
        colors.forEach((c, i) => {
            const m = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.1, 0.42), this.mat(c));
            m.position.y = i * 0.1;
            bundle.add(m);
        });
        bundle.visible = false;
        this.scene.add(bundle);
        this.bundleItem = this.register(bundle, { band: 1 });
        this.bundleItem.dynamic = true;
        this.bundleItem.hiddenUnless = () => this.fabricState === "bundle";
        this.refs.bundle = bundle;
        this.refs.fabricPos = new THREE.Vector3(15.3, Y, -12);
        // Drips
        this.box(15.6, 16.4, Y + 0.001, Y + 0.01, -12.9, -11.1, 0x2c3a44, { band: 1 });

        // Mrs. Wong
        this.room({
            x0: 24, x1: 31, z0: -16, z1: -8, y: Y, name: "wong", id: "wong", floorSurface: "wood",
            wall: 0xa38a86, floor: 0x6b5244,
            open: { w: [[-13, -11]] }
        });
        this.box(28.6, 31, Y, Y + 0.6, -9.8, -8, 0x8a6f5a, { collide: true });   // bed
        this.box(28.6, 29.6, Y + 0.6, Y + 0.72, -9.6, -8.2, 0xe8dcc8);
        this.box(29.8, 31, Y, Y + 1.3, -16, -15, 0x7a2e22, { collide: true });   // altar
        this.box(30.1, 30.6, Y + 1.3, Y + 1.6, -15.7, -15.3, 0xff6040, { matOpts: { emissive: 0x802010 } });
        this.box(25, 26.2, Y, Y + 0.5, -15.6, -14.4, 0x6b4a30, { collide: true }); // stool/table
        this.box(25.3, 25.9, Y + 0.5, Y + 0.7, -15.2, -14.8, 0x4f7f70);           // thermos
        this.box(24.1, 24.9, Y, Y + 2.0, -9.5, -8.1, 0x5d4632, { collide: true });  // wardrobe
    }

    laundryLine(a0, a1, y, fixed, axis, colors) {
        const len = Math.abs(a1 - a0);
        const line = axis === "x"
            ? this.box(a0, a1, y, y + 0.04, fixed - 0.02, fixed + 0.02, 0x222222)
            : this.box(fixed - 0.02, fixed + 0.02, y, y + 0.04, a0, a1, 0x222222);
        void line;
        colors.forEach((c, i) => {
            const t = (i + 0.5) / colors.length;
            const a = a0 + (a1 - a0) * t;
            const h = 0.9 + this.rand() * 0.7;
            const cloth = new THREE.Mesh(
                new THREE.PlaneGeometry(len / colors.length * 0.8, h, 1, 4),
                new THREE.MeshStandardMaterial({ color: c, side: THREE.DoubleSide, roughness: 1, map: surface("fabric").map, normalMap: surface("fabric").normalMap })
            );
            if (axis === "x") cloth.position.set(a, y - h / 2, fixed);
            else { cloth.position.set(fixed, y - h / 2, a); cloth.rotation.y = Math.PI / 2; }
            this.scene.add(cloth);
            this.register(cloth, { band: bandOf(y - h + 0.3) });
            this.cloths.push(cloth);
        });
    }

    // ------------------------------------------------------------------
    // Airshaft (section 45)
    // ------------------------------------------------------------------

    buildAirshaft() {
        const Y = LEVEL.B;
        this.room({
            x0: -7, x1: -3, z0: -21, z1: -16, y: Y, name: "airshaft", wallSurface: "concrete", floorSurface: "concrete",
            wall: 0x5e615c, floor: 0x3e403c, h: 8.2, skip: ["s"],
            band: 1, wallBand: 1
        });
        this.box(-6.8, -3.2, Y, Y + 0.3, -20.8, -20.2, 0x3a3a3a, { band: 1 }); // drain

        // Handholds. Each one is only on one wall, so no single view shows a
        // whole route: you have to look from more than one side (section 45,
        // without anything appearing or disappearing).
        // Ladder, bolted to the west wall: its rungs face east.
        [-19.2, -18.6].forEach(z => this.box(-6.95, -6.85, Y + 0.1, Y + 3.8, z, z + 0.08, 0x8a5a3a, { band: 1 }));
        const rungs = new THREE.Group();
        for (let i = 0; i < 7; i++) {
            const r = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.06, 0.66), this.mat(0x8a5a3a));
            r.position.set(-6.88, Y + 0.5 + i * 0.5, -18.86);
            rungs.add(r);
        }
        this.scene.add(rungs);
        this.register(rungs, { band: 1 });
        this.hold("ladder", "A rusted ladder on the west wall.", rungs, [1, 0, 0],
            new THREE.Vector3(-6.5, Y + 3.6, -18.9));
        // Old shop sign sticking out from the east wall: a ledge you can stand on.
        const sign = this.box(-4.7, -3.0, Y + 4.1, Y + 4.5, -19.8, -19.0, 0xa8534a, { band: 1 });
        this.box(-4.72, -4.68, Y + 4.12, Y + 4.48, -19.75, -19.05, 0xe8c070, { band: 1, matOpts: { emissive: 0x3a2a10 } });
        this.hold("sign", "An old shop sign jutting from the east wall. Wide enough to stand on.", sign, [-1, 0, 0],
            new THREE.Vector3(-3.8, Y + 4.5, -19.4));
        // Laundry pole across the shaft: a handhold between the two walls.
        const pole = this.box(-7, -3, Y + 5.5, Y + 5.62, -18.3, -18.18, 0x7a7a70, { band: 1 });
        this.hold("pole", "A laundry pole across the shaft.", pole, null,
            new THREE.Vector3(-5.0, Y + 4.0, -18.24));
        // AC unit on the north wall (just scenery) and the maintenance platform above it.
        this.box(-6.6, -5.4, Y + 1.5, Y + 2.2, -20.95, -20.1, 0xb8b8ae, { band: 1 });
        this.box(-6.5, -5.5, Y + 1.6, Y + 2.1, -20.12, -20.08, 0x555555, { band: 1 });
        const platform = this.box(-5.2, -3.3, Y + 6.4, Y + 6.6, -20.95, -19.7, 0x6a6e70, { band: 1 });
        this.box(-5.2, -3.3, Y + 6.6, Y + 7.3, -19.72, -19.68, 0x6a6e70, { band: 1 }); // railing
        this.hold("platform", "A maintenance platform high on the north wall, just below the roof.", platform, [0, 0, 1],
            new THREE.Vector3(-4.2, Y + 6.6, -20.3));

        this.refs.shaftBase = new THREE.Vector3(-5, Y, -18.2);
        // up the ladder, along the pole, onto the sign, up to the platform, over the top
        this.climbNodes = [
            new THREE.Vector3(-6.3, Y, -18.9),
            new THREE.Vector3(-6.5, Y + 3.6, -18.9),
            new THREE.Vector3(-5.0, Y + 4.0, -18.24),
            new THREE.Vector3(-3.8, Y + 4.5, -19.4),
            new THREE.Vector3(-4.2, Y + 6.6, -20.3),
            new THREE.Vector3(-4.4, LEVEL.ROOF, -16.2),
            new THREE.Vector3(-5, LEVEL.ROOF, -15.2)
        ];
    }

    // ------------------------------------------------------------------
    // Roof
    // ------------------------------------------------------------------

    buildRoof() {
        const Y = LEVEL.ROOF;
        const roofCol = 0x8f8b80;
        const rects = [
            [-10, 12, -16, -6],
            [-10, -7, -24, -16],
            [-3, 12, -24, -16],
            [-7, -3, -24, -21]
        ];
        rects.forEach(([x0, x1, z0, z1]) => {
            addFloor(x0, x1, z0, z1, Y, "roof");
            this.box(x0, x1, Y - 0.5, Y, z0, z1, roofCol, { band: 2, surface: "tar" });
        });
        // tar patches
        for (let i = 0; i < 14; i++) {
            const x = -9 + this.rand() * 20, z = -23 + this.rand() * 16;
            if (x > -7.5 && x < -2.5 && z > -21.5 && z < -15.5) continue;
            this.box(x, x + 1 + this.rand() * 2, Y, Y + 0.01, z, z + 1 + this.rand() * 2,
                [0x7d796f, 0x9a968a, 0x6f6c64][i % 3], { band: 2, surface: "tar", castShadow: false });
        }
        // parapets
        const P = 0.7;
        this.box(-10.3, 12.3, Y, Y + P, -24.3, -24, 0x7d796f, { band: 2, surface: "concrete" });
        this.box(-10.3, 12.3, Y, Y + P, -6, -5.7, 0x7d796f, { band: 2, surface: "concrete" });
        this.box(-10.3, -10, Y, Y + P, -24, -6, 0x7d796f, { band: 2, surface: "concrete" });
        this.box(12, 12.3, Y, Y + P, -24, -6, 0x7d796f, { band: 2, surface: "concrete" });
        // shaft rim
        this.box(-7.2, -2.8, Y, Y + 0.35, -21.2, -21, 0x6d6a60, { band: 2 });
        this.box(-7.2, -7, Y, Y + 0.35, -21, -16, 0x6d6a60, { band: 2 });
        this.box(-3, -2.8, Y, Y + 0.35, -21, -16, 0x6d6a60, { band: 2 });

        // Stair hut with door
        this.box(8.8, 11.6, Y, Y + 2.8, -15, -12.4, 0x7a7466, { band: 2, collide: true, collideY: Y, fadeable: true, surface: "plaster", topSurface: "tar" });
        this.box(9.9, 10.9, Y, Y + 2.2, -12.42, -12.32, 0x6a3f2c, { band: 2 });
        this.refs.roofDoorTop = new THREE.Vector3(10.4, Y, -11.8);
        this.refs.shaftTop = new THREE.Vector3(-5, Y, -15.4);

        // Pigeon coop
        const coopMat = new THREE.MeshStandardMaterial({ color: 0x8a8a80, wireframe: true });
        const coop = new THREE.Mesh(new THREE.BoxGeometry(4, 2.2, 2), coopMat);
        coop.position.set(3, Y + 1.1, -22.6);
        this.scene.add(coop);
        this.register(coop, { band: 2 });
        this.box(0.9, 5.1, Y + 2.2, Y + 2.35, -23.7, -21.5, 0x6b4a30, { band: 2 });
        this.box(0.9, 5.1, Y, Y + 0.2, -23.7, -21.5, 0x6b4a30, { band: 2 });
        [0.95, 5.0].forEach(x => [-23.65, -21.55].forEach(z =>
            this.box(x, x + 0.12, Y, Y + 2.2, z - 0.06, z + 0.06, 0x5d4632, { band: 2 })));
        addObstacle(0.9, 5.1, -23.7, -21.5, Y, { name: "coop" });
        this.refs.coopPos = new THREE.Vector3(3, Y + 0.3, -22.4);

        for (let i = 0; i < 7; i++) {
            const p = makePigeon();
            p.position.set(1.4 + (i % 4) * 1.0, Y + (i < 4 ? 0.2 : 1.2), -22.9 + (i % 2) * 0.6);
            this.scene.add(p);
            this.register(p, { band: 2 });
            this.pigeons.push({ sprite: p, phase: this.rand() * 10, base: p.position.clone() });
        }
        for (let i = 0; i < 4; i++) {
            const p = makePigeon();
            p.position.set(-1 + i * 1.3, Y + 0.72, -23.95);
            this.scene.add(p);
            this.register(p, { band: 2 });
            this.pigeons.push({ sprite: p, phase: this.rand() * 10, base: p.position.clone() });
        }

        // Water tank on legs
        [[8.1, -22.3], [10.2, -22.3], [8.1, -20.1], [10.2, -20.1]].forEach(([x, z]) =>
            this.box(x, x + 0.15, Y, Y + 2.2, z, z + 0.15, 0x555555, { band: 2 }));
        const tank = new THREE.Mesh(new THREE.CylinderGeometry(1.25, 1.25, 2.0, 24), this.surfaceMat("rust", 0x9aa4a6));
        tank.castShadow = tank.receiveShadow = true;
        tank.position.set(9.2, Y + 3.2, -21.2);
        this.scene.add(tank);
        this.register(tank, { band: 2 });
        addObstacle(8, 10.4, -22.4, -20, Y, { name: "tank" });
        // antenna mast
        this.box(11.2, 11.35, Y, Y + 5.6, -21.3, -21.15, 0x444444, { band: 2 });
        this.box(11.25, 11.3, Y + 4.4, Y + 4.46, -22.6, -19.8, 0x444444, { band: 2 });
        this.box(11.25, 11.3, Y + 5.0, Y + 5.05, -22.2, -20.2, 0x444444, { band: 2 });
        // The lost pigeon, on a bracket on the far (north) side of the tank.
        // From the starting view the tank hides her completely.
        this.box(8.9, 9.5, Y + 2.5, Y + 2.56, -22.75, -22.4, 0x444444, { band: 2 });
        const lost = makePigeon();
        lost.position.set(9.2, Y + 2.56, -22.6);
        this.scene.add(lost);
        this.register(lost, { band: 2 });
        this.refs.lostPigeon = lost;
        this.refs.tank = tank;

        // A bedsheet pegged out between the tank and the coop. From her perch
        // it hangs right across her view of home.
        [-23.8, -21.3].forEach(z => this.box(6.45, 6.55, Y, Y + 2.7, z, z + 0.1, 0x5a5a55, { band: 2 }));
        this.box(6.48, 6.52, Y + 2.6, Y + 2.64, -23.8, -21.2, 0x222222, { band: 2 });
        const sheet = new THREE.Mesh(new THREE.PlaneGeometry(2.2, 2.0, 1, 6),
            new THREE.MeshStandardMaterial({ color: 0xe8e2d4, side: THREE.DoubleSide, roughness: 1, map: surface("fabric").map }));
        const sheetPivot = new THREE.Group();
        sheetPivot.position.set(6.5, Y + 2.6, -22.5);
        sheet.position.set(0, -1.0, 0);
        sheet.rotation.y = Math.PI / 2;
        sheetPivot.add(sheet);
        this.scene.add(sheetPivot);
        this.register(sheetPivot, { band: 2 });
        this.cloths.push(sheet);
        this.refs.sheet = sheetPivot;
        this.sheetObstacle = addObstacle(6.4, 6.6, -23.6, -21.4, Y, { name: "sheet" });
        this.refs.sheetSpot = new THREE.Vector3(7.0, Y, -21.0);
        this.pigeonPath = [
            new THREE.Vector3(9.2, Y + 2.56, -22.6),
            new THREE.Vector3(8.2, Y + 3.4, -22.9),
            new THREE.Vector3(6.5, Y + 3.6, -22.6),
            new THREE.Vector3(4.6, Y + 2.8, -22.5),
            new THREE.Vector3(3.2, Y + 0.25, -22.3)
        ];

        // Laundry lines (fabric arrives here later)
        [-9.2, -2.2].forEach(x => this.box(x, x + 0.12, Y, Y + 2.6, -8.6, -8.48, 0x5a5a55, { band: 2 }));
        this.laundryLine(-9.2, -2.2, Y + 2.5, -8.54, "x", [0xe8e2d4, 0x5a7ab0, 0xe8e2d4]);
        this.refs.roofFabricPos = new THREE.Vector3(-5.2, Y + 2.5, -8.54);

        // Roof clutter
        this.box(-9.6, -8.2, Y, Y + 0.45, -12, -10.6, 0x6b4a30, { band: 2, collide: true, collideY: Y }); // bench
        this.box(0, 0.6, Y, Y + 0.5, -10, -9.4, 0x5a7a4a, { band: 2 }); // pot
        this.box(0.1, 0.5, Y + 0.5, Y + 1.0, -9.9, -9.5, 0x3f7a3a, { band: 2 });
        this.box(1, 1.6, Y, Y + 0.4, -10.2, -9.6, 0x8a5a3a, { band: 2 });
        this.box(1.1, 1.5, Y + 0.4, Y + 0.8, -10.1, -9.7, 0x4a8a4a, { band: 2 });
        this.box(4.5, 6.5, Y, Y + 0.9, -9, -7.2, 0x9a9a92, { band: 2, collide: true, collideY: Y }); // ac housing
        for (let i = 0; i < 16; i++) {
            const x = -9.5 + this.rand() * 21, z = -23.5 + this.rand() * 17;
            if (x > -7.5 && x < -2.5 && z > -21.5 && z < -15.5) continue;
            if (Math.abs(x - 3) < 3 && z < -20) continue;
            const h = 2.5 + this.rand() * 3;
            this.box(x, x + 0.08, Y, Y + h, z, z + 0.08, 0x3a3a3a, { band: 2 });
            this.box(x - 0.6, x + 0.68, Y + h - 0.3, Y + h - 0.25, z, z + 0.05, 0x3a3a3a, { band: 2 });
            this.box(x - 0.4, x + 0.48, Y + h - 0.7, Y + h - 0.65, z, z + 0.05, 0x3a3a3a, { band: 2 });
        }

        // Kai Tak plane placeholder (section 48)
        const plane = new THREE.Group();
        const body = new THREE.Mesh(new THREE.CylinderGeometry(1.1, 0.9, 16, 10), this.mat(0xe8e8e4));
        body.rotation.z = Math.PI / 2;
        plane.add(body);
        const nose = new THREE.Mesh(new THREE.ConeGeometry(1.1, 2.4, 10), this.mat(0xe8e8e4));
        nose.rotation.z = -Math.PI / 2;
        nose.position.x = 9.2;
        plane.add(nose);
        const wing = new THREE.Mesh(new THREE.BoxGeometry(3.4, 0.25, 17), this.mat(0xd0d0cc));
        wing.position.x = 0.5;
        plane.add(wing);
        const tail = new THREE.Mesh(new THREE.BoxGeometry(2.4, 3.2, 0.25), this.mat(0xa8453a));
        tail.position.set(-7, 1.8, 0);
        plane.add(tail);
        const stab = new THREE.Mesh(new THREE.BoxGeometry(1.8, 0.2, 6), this.mat(0xd0d0cc));
        stab.position.set(-7, 0.4, 0);
        plane.add(stab);
        const stripe = new THREE.Mesh(new THREE.CylinderGeometry(1.12, 1.0, 12, 10, 1, true, 0, Math.PI),
            this.mat(0xa8453a));
        stripe.rotation.z = Math.PI / 2;
        stripe.rotation.x = Math.PI;
        stripe.scale.set(1, 0.3, 1);
        plane.add(stripe);
        plane.visible = false;
        plane.position.set(-120, 21, -30);
        plane.rotation.z = -0.06;
        this.scene.add(plane);
        this.refs.plane = plane;
        this.planeState = null;
    }

    // ------------------------------------------------------------------
    // The blue pipe (section 34) plus secondary pipes
    // ------------------------------------------------------------------

    pipe(points, color, radius = 0.12, opts = {}) {
        const mat = this.mat(color, { roughness: 0.72, metalness: 0.15 });
        const group = [];
        for (let i = 0; i < points.length - 1; i++) {
            const a = new THREE.Vector3(...points[i]);
            const b = new THREE.Vector3(...points[i + 1]);
            const len = a.distanceTo(b);
            const geo = new THREE.CylinderGeometry(radius, radius, len + radius * 0.5, 8);
            const m = new THREE.Mesh(geo, mat);
            m.position.copy(a).add(b).multiplyScalar(0.5);
            m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), b.clone().sub(a).normalize());
            this.scene.add(m);
            const band = opts.band ?? bandOf(Math.min(a.y, b.y));
            this.register(m, { band });
            group.push(m);
            // joint collar
            const j = new THREE.Mesh(new THREE.SphereGeometry(radius * 1.35, 8, 6), mat);
            j.position.copy(b);
            this.scene.add(j);
            this.register(j, { band });
        }
        return { meshes: group, material: mat };
    }

    buildPipes() {
        const A = 3.3, B = 8.3;
        this.bluePipe = this.pipe([
            [-7.2, 4.4, -3.7],
            [-7.2, A, -3.7],
            [-7.2, A, -0.72],
            [2.6, A, -0.72],
            [2.6, A, -1.7],      // disappears into the "wall"
            [2.3, A, -1.7],
            [2.3, A, -14.7],     // reappears down the corridor, into Lau's
            [10.2, A, -14.7],
            [10.2, B, -14.7],    // up the stairwell
            [10.2, B, -12.85],
            [-4.8, B, -12.85],   // along Level B to Chan's
            [-4.8, B, -20.7],    // into the airshaft
            [-4.8, 14.2, -20.7], // and up to the roof
            [-4.8, 14.2, -23.6]
        ], PAL.pipeBlue, 0.14);

        // Secondary pipes for density
        this.pipe([[-6, 3.8, 0.8], [4, 3.8, 0.8]], 0x8a5a3a, 0.08);
        this.pipe([[-6, 3.95, -0.85], [4, 3.95, -0.85]], 0x6f7d62, 0.07);
        this.pipe([[3.8, 3.6, -1], [3.8, 3.6, -9]], 0x9a4a3a, 0.07);
        this.pipe([[0.2, 3.7, -9.2], [7.8, 3.7, -9.2]], 0x8a8c86, 0.06);
        this.pipe([[-2, 8.6, -11.15], [8, 8.6, -11.15]], 0x8a5a3a, 0.08);
        this.pipe([[12, 7.8, -13.3], [24, 7.8, -13.3]], 0x6f7d62, 0.1);
        this.pipe([[12, 8.2, -10.7], [24, 8.2, -10.7]], 0x8a8c86, 0.07);
        this.pipe([[-3.2, 5, -16.2], [-3.2, 13.5, -16.2]], 0x8a5a3a, 0.08, { band: 1 });
    }

    // ------------------------------------------------------------------
    // Surrounding density: solid building mass filling every unused cell.
    // ------------------------------------------------------------------

    buildFiller() {
        const X0 = -22, X1 = 38, Z0 = -30, Z1 = 8;
        const cols = (X1 - X0) / GRID, rows = (Z1 - Z0) / GRID;
        this.fillerBlocks = [];
        const palette = [0x7f817a, 0x6f7d62, 0x8f8266, 0x7a6a5a, 0x8a7d6a, 0x6d7470, 0x857a70, 0x9a8a6a, 0x74675a];

        const bands = [
            { band: 0, y0: 0, y1: 4.8, level: LEVEL.A },
            { band: 1, y0: 4.8, y1: 9.0, level: LEVEL.B },
            { band: 1.5, y0: 9.0, y1: null, level: null }
        ];

        const voids = [
            { x0: 11.5, x1: 24.5, z0: -17, z1: -7, bands: [0, 1, 1.5] }, // catwalk light well
            { x0: -7, x1: -3, z0: -21, z1: -16, bands: [1, 1.5] },        // airshaft
            { x0: -10, x1: 12, z0: -24, z1: -6, bands: [1.5] }            // under the roof slab
        ];

        const overlaps = (ax0, ax1, az0, az1, b) =>
            ax0 < b.x1 - 0.01 && ax1 > b.x0 + 0.01 && az0 < b.z1 - 0.01 && az1 > b.z0 + 0.01;

        for (const band of bands) {
            const grid = [];
            for (let i = 0; i < cols; i++) {
                grid[i] = [];
                for (let j = 0; j < rows; j++) {
                    const x0 = X0 + i * GRID, z0 = Z0 + j * GRID;
                    const x1 = x0 + GRID, z1 = z0 + GRID;
                    let free = true;
                    for (const f of floors) {
                        const fb = f.y < 2 ? 0 : f.y < 9 ? 1 : 2;
                        const blocks = band.band === 1.5 ? fb === 1 && f.name === "airshaft" : fb === band.band;
                        if (blocks && overlaps(x0, x1, z0, z1, f)) { free = false; break; }
                    }
                    if (free) {
                        for (const v of voids) {
                            if (v.bands.includes(band.band) && overlaps(x0, x1, z0, z1, v)) { free = false; break; }
                        }
                    }
                    grid[i][j] = free;
                }
            }

            // Greedy merge into chunky blocks (max 3x3 cells) for variety.
            for (let j = 0; j < rows; j++) {
                for (let i = 0; i < cols; i++) {
                    if (!grid[i][j]) continue;
                    const maxW = 1 + Math.floor(this.rand() * 3);
                    const maxD = 1 + Math.floor(this.rand() * 3);
                    let w = 1;
                    while (w < maxW && i + w < cols && grid[i + w][j]) w++;
                    let d = 1;
                    outer: while (d < maxD && j + d < rows) {
                        for (let k = 0; k < w; k++) if (!grid[i + k][j + d]) break outer;
                        d++;
                    }
                    for (let a = 0; a < w; a++) for (let b = 0; b < d; b++) grid[i + a][j + b] = false;

                    const inset = 0.35;
                    const x0 = X0 + i * GRID + inset, x1 = X0 + (i + w) * GRID - inset;
                    const z0 = Z0 + j * GRID + inset, z1 = Z0 + (j + d) * GRID - inset;
                    let y1 = band.y1;
                    if (y1 === null) y1 = 9.6 + this.rand() * 2.8;
                    const col = palette[Math.floor(this.rand() * palette.length)];
                    const m = this.box(x0, x1, band.y0, y1, z0, z1, col,
                        { fadeable: true, band: band.band, surface: "facade", topSurface: "tar", topColor: 0x9a968c });
                    m.userData.filler = true;
                    this.fillerBlocks.push({ x0, x1, z0, z1, y0: band.y0, y1, band: band.band });
                    // AC units and cages on some faces
                    if (this.rand() < 0.35) {
                        const ay = band.y0 + 1 + this.rand() * 2.5;
                        this.box(x0 + 0.2, x0 + 0.9, ay, ay + 0.5, z1, z1 + 0.45, 0xa8a8a0, { band: band.band, fadeable: true });
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Set dressing: neon shop signs, overhead cables, dust in the air
    // ------------------------------------------------------------------

    buildDressing() {
        const signs = [
            ["牙科", "#ff4a5a"], ["茶餐廳", "#ffb040"], ["理髮", "#40d8ff"], ["五金", "#ff60c0"],
            ["麵家", "#ffd040"], ["藥房", "#60ff90"], ["士多", "#ff7040"], ["鐘錶", "#80a0ff"],
            ["裁縫", "#ff4a8a"], ["當", "#ffb040"], ["涼茶", "#40ffd0"], ["酒家", "#ff5040"]
        ];
        // Put signs on building faces that look onto the walkways.
        const candidates = this.fillerBlocks.filter(b => (b.band === 0 || b.band === 1) &&
            b.x1 > -16 && b.x0 < 32 && b.z1 > -26 && b.z0 < 6);
        let placed = 0;
        for (let i = 0; i < candidates.length && placed < 18; i += 3) {
            const b = candidates[(i * 7) % candidates.length];
            const [text, color] = signs[placed % signs.length];
            const h = 0.6 + text.length * 0.55;
            const y = b.y0 + 1.2 + this.rand() * Math.max(0.1, (b.y1 - b.y0) - h - 1.4);
            const faceSouth = this.rand() < 0.6;
            const mat = new THREE.MeshBasicMaterial({ map: neonTexture(text, color), toneMapped: false });
            const plane = new THREE.Mesh(new THREE.BoxGeometry(0.5, h, 0.08), mat);
            if (faceSouth) plane.position.set(b.x0 + 0.4 + this.rand() * Math.max(0.1, b.x1 - b.x0 - 0.8), y + h / 2, b.z1 + 0.35);
            else {
                plane.position.set(b.x1 + 0.35, y + h / 2, b.z0 + 0.4 + this.rand() * Math.max(0.1, b.z1 - b.z0 - 0.8));
                plane.rotation.y = Math.PI / 2;
            }
            this.scene.add(plane);
            this.register(plane, { band: b.band, fadeable: true });
            // bracket
            const br = this.box(plane.position.x - 0.03, plane.position.x + 0.03, y + h - 0.1, y + h - 0.04,
                plane.position.z - 0.35, plane.position.z + 0.05, 0x333333, { band: b.band, fadeable: true, surface: null });
            void br;
            placed++;
        }

        // Overhead cables strung between buildings (sagging tubes).
        const cableMat = new THREE.MeshStandardMaterial({ color: 0x1c1c1e, roughness: 0.6 });
        const tops = this.fillerBlocks.filter(b => b.band === 1.5 || b.band === 1);
        for (let i = 0; i < 40; i++) {
            const a = tops[(i * 13) % tops.length], b = tops[(i * 29 + 7) % tops.length];
            const pa = new THREE.Vector3(a.x0 + 0.2, a.y1 - 0.2, (a.z0 + a.z1) / 2);
            const pb = new THREE.Vector3(b.x1 - 0.2, b.y1 - 0.2, (b.z0 + b.z1) / 2);
            if (pa.distanceTo(pb) > 14 || pa.distanceTo(pb) < 3) continue;
            const mid = pa.clone().lerp(pb, 0.5); mid.y -= 0.6 + pa.distanceTo(pb) * 0.06;
            const curve = new THREE.QuadraticBezierCurve3(pa, mid, pb);
            const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 16, 0.025, 4, false), cableMat);
            this.scene.add(tube);
            this.register(tube, { band: bandOf(Math.min(pa.y, pb.y) - 1) });
        }

        // Dust drifting in the light.
        const n = 170;
        const pos = new Float32Array(n * 3);
        this.dustSeed = new Float32Array(n);
        for (let i = 0; i < n; i++) {
            pos[i * 3] = (this.rand() - 0.5) * 14;
            pos[i * 3 + 1] = this.rand() * 4;
            pos[i * 3 + 2] = (this.rand() - 0.5) * 14;
            this.dustSeed[i] = this.rand() * 100;
        }
        const g = new THREE.BufferGeometry();
        g.setAttribute("position", new THREE.BufferAttribute(pos, 3));
        const c = document.createElement("canvas"); c.width = c.height = 32;
        const ctx = c.getContext("2d");
        const grd = ctx.createRadialGradient(16, 16, 0, 16, 16, 16);
        grd.addColorStop(0, "rgba(255,240,210,1)"); grd.addColorStop(1, "rgba(255,240,210,0)");
        ctx.fillStyle = grd; ctx.fillRect(0, 0, 32, 32);
        const tex = new THREE.CanvasTexture(c);
        this.dust = new THREE.Points(g, new THREE.PointsMaterial({
            size: 3.5, sizeAttenuation: false, map: tex, transparent: true, opacity: 0.4,
            depthWrite: false, blending: THREE.AdditiveBlending, color: 0xffe0b0
        }));
        this.dust.frustumCulled = false;
        this.scene.add(this.dust);
    }

    // A late-afternoon sky dome, only seen from the roof.
    buildSky() {
        const mat = new THREE.ShaderMaterial({
            side: THREE.BackSide, depthWrite: false, fog: false,
            uniforms: {
                top: { value: new THREE.Color(0x4f86c6) },
                mid: { value: new THREE.Color(0xe9cdb0) },
                low: { value: new THREE.Color(0xc98a70) }
            },
            vertexShader: `varying vec3 vDir; void main() { vDir = normalize(position);
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
            fragmentShader: `uniform vec3 top, mid, low; varying vec3 vDir;
                void main() { float y = vDir.y;
                    vec3 c = y > -0.05 ? mix(mid, top, smoothstep(-0.05, 0.7, y)) : mix(mid, low, smoothstep(0.05, 0.4, -y));
                    gl_FragColor = vec4(c, 1.0); }`
        });
        this.sky = new THREE.Mesh(new THREE.SphereGeometry(170, 32, 16), mat);
        this.sky.renderOrder = -10;
        this.scene.add(this.sky);
        this.register(this.sky, { band: 1.5 });
    }

    buildDistantCity() {
        this.buildSky();
        // Low-detail skyline visible only from the roof.
        for (let i = 0; i < 110; i++) {
            const ang = this.rand() * Math.PI * 2;
            const r = 42 + this.rand() * 45;
            const x = 6 + Math.cos(ang) * r, z = -10 + Math.sin(ang) * r;
            const w = 3 + this.rand() * 6, d = 3 + this.rand() * 6;
            const h = 4 + this.rand() * 18;
            const c = [0x8a96a0, 0x96a0a4, 0x7d8a94, 0xa4a8a4][i % 4];
            this.box(x, x + w, -2, h, z, z + d, c, { band: 1.5, surface: "facade", castShadow: false });
        }
        // Hills to the north (Lion Rock direction)
        for (let i = 0; i < 6; i++) {
            const hill = new THREE.Mesh(
                new THREE.ConeGeometry(18 + this.rand() * 14, 22 + this.rand() * 18, 7),
                this.mat(0x5f7a66)
            );
            hill.position.set(-50 + i * 22, 5, -110 - this.rand() * 20);
            hill.scale.z = 0.5;
            this.scene.add(hill);
            this.register(hill, { band: 1.5 });
        }
        // Clouds
        this.clouds = [];
        for (let i = 0; i < 10; i++) {
            const c = new THREE.Mesh(new THREE.BoxGeometry(8 + this.rand() * 10, 1.2, 4 + this.rand() * 4),
                new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.75 }));
            c.position.set(-60 + this.rand() * 130, 30 + this.rand() * 10, -70 + this.rand() * 50);
            this.scene.add(c);
            this.register(c, { band: 1.5 });
            this.clouds.push(c);
        }
    }

    // ------------------------------------------------------------------
    // Characters
    // ------------------------------------------------------------------

    placeNPC(id, look, x, y, z, height = 1.7, opts = {}) {
        const s = makeCharacter(id, look, height);
        s.position.set(x, y, z);
        s.userData.home = new THREE.Vector3(x, y, z);
        s.userData.id = id;
        s.userData.anim = opts.anim || "idle";
        s.userData.phase = this.rand() * 6;
        this.scene.add(s);
        this.register(s, { band: bandOf(y + 0.5) }).dynamic = true;
        if (opts.collide !== false) {
            const r = 0.28;
            const o = addObstacle(x - r, x + r, z - r, z + r, y, {
                name: id, active: () => s.visible && !s.userData.gone && !s.userData.ghost
            });
            s.userData.obstacle = o;
        }
        this.npcs[id] = s;
        return s;
    }

    buildCharacters() {
        const A = LEVEL.A, B = LEVEL.B, R = LEVEL.ROOF;
        this.placeNPC("grandfather", Looks.grandfather, -12.8, A, -0.15, 1.6);
        this.placeNPC("lau", Looks.lau, 6.2, A, -10.9, 1.7);
        this.placeNPC("chan", Looks.chan, -3.4, B, -11.2, 1.65);
        this.placeNPC("son", Looks.son, 0.2, R, -19.4, 1.35);
        this.placeNPC("ng", Looks.ng, 3.4, R, -20.6, 1.7);
        this.placeNPC("wong", Looks.wong, 28.6, B, -12.6, 1.5);

        // Ambient residents (section 59)
        this.placeNPC("chopper", Looks.chopper, -3.4, A, 2.1, 1.6, { anim: "work" });
        this.placeNPC("mahjong1", Looks.mahjong1, -3.2, A, 2.7, 1.2, { anim: "work", collide: false });
        this.placeNPC("mahjong2", Looks.mahjong2, -0.8, A, 2.7, 1.2, { anim: "work", collide: false });
        this.placeNPC("mahjong3", Looks.mahjong3, -2.0, A, 3.6, 1.2, { anim: "work", collide: false });
        this.placeNPC("fanman", Looks.fanman, -1.4, A, 0.62, 1.2, { anim: "work" });
        this.placeNPC("shopkeeper", Looks.shopkeeper, 0.7, A, -5.0, 1.6);
        this.placeNPC("worker", Looks.worker, 3.0, B, -12.62, 1.7, { anim: "work" });
        this.placeNPC("child", Looks.child, 11.55, B, -14.5, 1.0);
    }

    // ------------------------------------------------------------------
    // World-state changes
    // ------------------------------------------------------------------

    // Section 52: the fabric is moved, not deleted. The Chan boy takes it
    // down from the catwalk, carries it upstairs and hangs it on the roof line.
    get fabricOnRoof() {
        return this.fabricState === "roof";
    }

    setFabricState(state) {
        this.fabricState = state;
        const f = this.refs.fabric;
        if (state === "catwalk") {
            f.position.set(16, LEVEL.B + 2.6, -12);
            f.rotation.y = 0;
            this.fabricItem.band = 1;
            f.userData.gone = false;
        } else if (state === "roof") {
            f.position.copy(this.refs.roofFabricPos);
            f.rotation.y = Math.PI / 2;
            this.fabricItem.band = 2;
            f.userData.gone = false;
        } else {
            f.userData.gone = true;   // folded up in his arms
        }
        this.fabricItem.box.setFromObject(f);
    }

    // Walk an NPC along points at a steady pace.
    walkNPC(id, points, onDone, speed = 2.4) {
        const s = this.npcs[id];
        s.userData.path = points.map(p => p.clone ? p.clone() : new THREE.Vector3(...p));
        s.userData.walkSpeed = speed;
        s.userData.walkTo = s.userData.path.shift();
        s.userData.onArrive = onDone;
    }

    placeAt(id, x, y, z) {
        const s = this.npcs[id];
        s.position.set(x, y, z);
        s.userData.home.set(x, y, z);
        s.userData.walkTo = null;
        s.userData.path = null;
    }

    playPlane() {
        const p = this.refs.plane;
        p.visible = true;
        p.position.set(-110, 21, -31);
        this.planeState = { t: 0 };
    }

    // ------------------------------------------------------------------
    // Per-frame update: closed rooms, cutaway, doors, lighting mix
    // ------------------------------------------------------------------

    // Fade a character in or out, e.g. stepping through a doorway.
    fadeNPC(id, dir, onDone) {
        const s = this.npcs[id];
        s.material.transparent = true;
        if (dir === "in") { s.userData.gone = false; s.material.opacity = 0; }
        s.userData.fade = { dir, onDone };
    }

    update(delta, player, cam, paused = false) {
        this.time += delta;
        const pb = player.band;
        const p = player.position;
        const back = cam.backVector(new THREE.Vector3());
        const right = cam.rightVector(new THREE.Vector3());

        const current = this.roomAt(p);
        this.currentRoom = current;

        // Doors swing open once opened.
        for (const d of this.doors) {
            const target = d.open ? 1 : 0;
            d.openT += (target - d.openT) * Math.min(1, delta * 6);
            d.pivot.rotation.y = d.baseYaw - d.openT * Math.PI * 0.55;   // swings away from the side you open it from
        }

        for (const it of this.items) {
            if (it.dynamic) it.band = bandOf(it.obj.position.y + 0.5);
            let vis = it.band === 1.5 ? pb === 2 : it.band <= pb;
            if (it.hiddenUnless && !it.hiddenUnless()) vis = false;
            if (it.obj.userData.character) {
                const pos = it.obj.position;
                it.contentOf = this.roomAtPoint(new THREE.Vector3(pos.x, pos.y + 0.5, pos.z));
            }
            if (it.contentOf && it.contentOf !== current) vis = false;
            it.obj.visible = vis && !it.obj.userData.gone;
            if (!vis || !it.fadeable) continue;

            let target = 1;
            // A closed room keeps its lid on unless Mei is inside (or it's
            // standing between her and the camera, like any other building).
            if (it.isLid && it.room === current) target = 0;
            else if (it.band === pb) {
                const b = it.box;
                let smin = Infinity, lmin = Infinity, lmax = -Infinity;
                for (const x of [b.min.x, b.max.x]) for (const z of [b.min.z, b.max.z]) {
                    const dx = x - p.x, dz = z - p.z;
                    const s = dx * back.x + dz * back.z;
                    const l = dx * right.x + dz * right.z;
                    smin = Math.min(smin, s);
                    lmin = Math.min(lmin, l); lmax = Math.max(lmax, l);
                }
                // A closed room Mei isn't in only fades where it actually stands
                // in front of her; everything else fades across the view.
                const reach = it.room && it.room !== current ? 2.5 : 15;
                if (smin > 0.25 && lmax > -reach && lmin < reach && b.max.y > p.y + 0.9) {
                    target = it.obj.userData.filler ? 0.2 : 0.07;
                }
            }
            if (Math.abs(it.opacity - target) > 0.005) {
                it.opacity += (target - it.opacity) * Math.min(1, delta * 10);
                const transparent = it.opacity < 0.98;
                it.obj.traverse(o => eachMat(o, m => {
                    if (m.transparent !== transparent) {
                        m.transparent = transparent;
                        m.needsUpdate = true;
                    }
                    m.opacity = it.opacity;
                    m.depthWrite = !transparent;
                    // lit windows on a faded building shouldn't float in mid-air
                    if (m.emissiveMap) {
                        if (m.userData.baseEmissive === undefined) m.userData.baseEmissive = m.emissiveIntensity;
                        m.emissiveIntensity = m.userData.baseEmissive * it.opacity * it.opacity;
                    }
                }));
            }
        }

        // Interior vs rooftop mix (sections 47, 62-63)
        const roofTarget = pb === 2 ? 1 : 0;
        this.roofMix += (roofTarget - this.roofMix) * Math.min(1, delta * 1.2);
        const t = this.roofMix;
        const bg = new THREE.Color(0x201c1a).lerp(new THREE.Color(0xa9cbe6), t);
        this.scene.background = bg;
        if (this.scene.fog) {
            this.scene.fog.color.copy(bg);
            this.scene.fog.near = THREE.MathUtils.lerp(27, 45, t);
            this.scene.fog.far = THREE.MathUtils.lerp(52, 190, t);
        }
        this.hemi.intensity = THREE.MathUtils.lerp(1.0, 1.6, t);
        this.hemi.color.setHex(0xc8ccd0).lerp(new THREE.Color(0xd8ecff), t);
        this.sun.intensity = THREE.MathUtils.lerp(0.35, 2.6, t);
        this.sun.color.setHex(0xfff0d8).lerp(new THREE.Color(0xffcf98), t);   // golden hour on the roof
        if (this.sky) this.sky.position.copy(p);
        this.sun.position.set(p.x - 14, p.y + 22, p.z + 12);
        this.sun.target.position.copy(p);
        // Only the current level's lamps are live (keeps fragment shading cheap).
        for (const l of this.lights) {
            l.visible = pb !== 2 && l.userData.band === pb;
            l.intensity = l.userData.base * (1 - 0.5 * t);
        }

        // Cloth sway
        for (const c of this.cloths) {
            c.rotation.z = Math.sin(this.time * 1.7 + c.position.x * 2 + c.position.z) * (0.03 + t * 0.06);
        }
        // Fan spin
        if (this.refs.fan) this.refs.fan.rotation.z += delta * 12;
        // Clouds drift
        for (const c of this.clouds) { c.position.x += delta * 0.8; if (c.position.x > 90) c.position.x = -70; }

        // Pixel sprites always face the camera (yaw only), like HD-2D billboards.
        for (const b of billboards) b.rotation.y = cam.currentYaw;

        // Dust follows the camera focus and drifts slowly.
        if (this.dust) {
            this.dust.position.set(p.x, p.y, p.z);
            const arr = this.dust.geometry.attributes.position.array;
            for (let i = 0; i < this.dustSeed.length; i++) {
                const sd = this.dustSeed[i];
                arr[i * 3 + 1] += delta * (0.05 + (sd % 1) * 0.08);
                arr[i * 3] += Math.sin(this.time * 0.3 + sd) * delta * 0.08;
                if (arr[i * 3 + 1] > 5) arr[i * 3 + 1] = 0;
            }
            this.dust.geometry.attributes.position.needsUpdate = true;
            this.dust.material.opacity = 0.4 * (1 - 0.7 * this.roofMix);
        }

        // NPC idle / work animation. Scripted walks pause while the player is
        // reading (dialogue, Polaroid, scrapbook) so nothing happens behind a menu.
        for (const s of Object.values(this.npcs)) {
            const ud = s.userData;
            if (ud.obstacle) {
                const r = 0.28, o = ud.obstacle;
                o.x0 = s.position.x - r; o.x1 = s.position.x + r;
                o.z0 = s.position.z - r; o.z1 = s.position.z + r;
                o.y = s.position.y;
            }
            if (ud.fade && !paused) {
                const m = s.material;
                m.opacity += (ud.fade.dir === "in" ? 1 : -1) * delta / 0.45;
                if (m.opacity >= 1 || m.opacity <= 0) {
                    m.opacity = Math.max(0, Math.min(1, m.opacity));
                    if (ud.fade.dir === "out") ud.gone = true;
                    const done = ud.fade.onDone;
                    ud.fade = null;
                    done && done();
                }
            }
            if (ud.walkTo) {
                if (paused) continue;
                const to = ud.walkTo.clone().sub(s.position);
                const d = to.length();
                // If Mei is standing just ahead, wait, say excuse me, then
                // squeeze past (the corridors are only two metres wide).
                const toPlayer = player.position.clone().sub(s.position);
                const near = Math.abs(toPlayer.y) < 1 && toPlayer.length() < 0.95;
                const ahead = toPlayer.x * to.x + toPlayer.z * to.z > 0;
                const sx = to.x * right.x + to.z * right.z;
                if (Math.abs(sx) > 0.01) s.scale.x = Math.sign(sx);
                setFrame(s, Math.floor(this.time * 8) % 4);
                if (ud.ghost && (!near || toPlayer.length() > 1.2)) ud.ghost = false;
                if (near && ahead && !ud.ghost) {
                    ud.yieldT = (ud.yieldT || 0) + delta;
                    if (ud.yieldT > 0.6 && !ud.barked) { ud.barked = true; this.onNPCBlocked && this.onNPCBlocked(s.userData.id); }
                    if (ud.yieldT < 1.6) continue;
                    ud.ghost = true;
                }
                if (!near) { ud.yieldT = 0; ud.barked = false; }
                if (d < 0.05) {
                    s.position.copy(ud.walkTo);
                    ud.walkTo = ud.path && ud.path.length ? ud.path.shift() : null;
                    if (!ud.walkTo) {
                        ud.home.copy(s.position);
                        const done = ud.onArrive;
                        ud.onArrive = null;
                        done && done();
                    }
                } else {
                    s.position.add(to.multiplyScalar(Math.min(1, (delta * (ud.walkSpeed || 2.4)) / d)));
                }
                continue;
            }
            // idle: breathe between frames 4 and 5 (faster when working)
            const rate = ud.anim === "work" ? 3.5 : 1.3;
            setFrame(s, Math.floor(this.time * rate + ud.phase) % 2 ? 5 : 4);
        }

        // The folded washing rides in the Chan boy's arms.
        if (this.fabricState === "bundle") {
            const son = this.npcs.son;
            this.refs.bundle.position.set(son.position.x, son.position.y + 0.62, son.position.z)
                .addScaledVector(back, 0.18);
        }

        // Pigeons bob
        for (const pg of this.pigeons) {
            pg.sprite.position.y = pg.base.y + Math.max(0, Math.sin(this.time * 3 + pg.phase)) * 0.04;
            setFrame(pg.sprite, Math.sin(this.time * 2.2 + pg.phase) > 0.6 ? 1 : 0);
        }

        // Plane
        if (this.planeState) {
            this.planeState.t += delta;
            const pl = this.refs.plane;
            pl.position.x += delta * 42;
            pl.position.y -= delta * 0.9;
            if (pl.position.x > 140) { pl.visible = false; this.planeState = null; }
        }
    }
}
