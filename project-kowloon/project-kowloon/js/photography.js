import * as THREE from "three";
import { GameState, lock, unlock } from "./gameState.js";
import { Residents } from "./data/residents.js";
import { UI, wait } from "./ui.js";

// Camera mode (sections 38-40).
// Movement locks, the HUD fades, a viewfinder appears. WASD pans the frame.
// A ray from screen center finds the subject. The result is a predetermined
// Polaroid rather than a live screenshot.

const MAX_PAN = 6;

export class PhotographySystem {
    constructor({ cam, scene, player, audio, input }) {
        this.cam = cam;
        this.scene = scene;
        this.player = player;
        this.audio = audio;
        this.input = input;
        this.active = false;
        this.targets = [];
        this.subject = null;
        this.raycaster = new THREE.Raycaster();
        this.overlay = document.getElementById("photo-overlay");
        this.status = document.getElementById("viewfinder-status");
        this.polaroid = document.getElementById("polaroid");
        this.polaroidImg = document.getElementById("polaroid-img");
        this.polaroidCaption = document.getElementById("polaroid-caption");
        this.polaroidPrompt = document.getElementById("polaroid-prompt");
        this.showingPhoto = false;
        this.canDismiss = false;
        this.onCapture = null;
        this.photoCache = {};
    }

    addTarget(id, sprite, valid) {
        const hit = new THREE.Mesh(
            new THREE.BoxGeometry(1.6, 2.2, 1.6),
            new THREE.MeshBasicMaterial({ visible: false })
        );
        this.scene.add(hit);
        this.targets.push({ id, sprite, valid, hit });
        hit.userData.targetId = id;
    }

    enter() {
        if (this.active || GameState.controlsLocked) return false;
        if (!GameState.flags.receivedCamera) return false;
        this.active = true;
        lock("camera");
        this.overlay.classList.remove("hidden");
        UI.setQuiet(true);
        this.cam.panOffset.set(0, 0, 0);
        this.player.hidden = true;
        return true;
    }

    exit() {
        if (!this.active) return;
        this.active = false;
        unlock("camera");
        this.overlay.classList.add("hidden");
        UI.setQuiet(false);
        this.cam.panOffset.set(0, 0, 0);
        this.player.hidden = false;
    }

    update(delta) {
        for (const t of this.targets) {
            t.hit.position.copy(t.sprite.position);
            t.hit.position.y += 1.0;
            t.hit.visible = false;
        }
        if (!this.active) return;

        const k = this.input.keys;
        const move = new THREE.Vector3();
        if (k.KeyW || k.ArrowUp) move.z -= 1;
        if (k.KeyS || k.ArrowDown) move.z += 1;
        if (k.KeyA || k.ArrowLeft) move.x -= 1;
        if (k.KeyD || k.ArrowRight) move.x += 1;
        if (move.lengthSq()) {
            move.normalize().multiplyScalar(6 * delta);
            move.applyAxisAngle(new THREE.Vector3(0, 1, 0), this.cam.settledYaw);
            this.cam.panOffset.add(move);
            if (this.cam.panOffset.length() > MAX_PAN) this.cam.panOffset.setLength(MAX_PAN);
        }

        this.raycaster.setFromCamera(new THREE.Vector2(0, 0), this.cam.camera);
        const visibleTargets = this.targets.filter(t => t.sprite.visible);
        const hits = this.raycaster.intersectObjects(visibleTargets.map(t => t.hit), false);
        const hitTarget = hits.length
            ? this.targets.find(t => t.hit === hits[0].object)
            : null;

        this.subject = hitTarget && hitTarget.valid() ? hitTarget : null;
        this.overlay.classList.toggle("locked-on", !!this.subject);

        if (this.subject) this.status.innerHTML = "<kbd>SPACE</kbd> Take photo";
        else if (hitTarget) this.status.textContent = "Not now.";
        else this.status.innerHTML = "<kbd>WASD</kbd> frame &nbsp; <kbd>C</kbd> lower camera";
    }

    async capture() {
        if (!this.active || this.showingPhoto) return;
        if (!this.subject) {
            UI.notice("Film is precious. Frame someone who matters.");
            return;
        }
        const id = this.subject.id;
        this.showingPhoto = true;
        this.canDismiss = false;
        this.audio.shutter();
        UI.flash();
        await wait(420);
        this.exit();
        lock("polaroid");

        const src = await this.photoFor(id);
        this.polaroidImg.src = src;
        this.polaroidCaption.textContent = Residents[id].name;
        this.polaroidPrompt.classList.remove("visible");
        this.polaroid.classList.remove("hidden", "developed");
        void this.polaroid.offsetWidth;
        this.polaroid.classList.add("developing");
        this.canDismiss = false;
        setTimeout(() => this.polaroid.classList.add("developed"), 80);
        await wait(3000);
        this.canDismiss = true;
        this.polaroidPrompt.classList.add("visible");
        this.pendingId = id;
    }

    dismiss() {
        if (!this.showingPhoto || !this.canDismiss) return false;
        this.polaroid.classList.add("hidden");
        this.polaroid.classList.remove("developing", "developed");
        this.showingPhoto = false;
        unlock("polaroid");
        const id = this.pendingId;
        this.pendingId = null;
        this.onCapture && this.onCapture(id);
        return true;
    }

    // Uses assets/photos/<id>-placeholder.png if it exists, otherwise paints one.
    photoFor(id) {
        if (this.photoCache[id]) return Promise.resolve(this.photoCache[id]);
        return new Promise(resolve => {
            const img = new Image();
            img.onload = () => { this.photoCache[id] = img.src; resolve(img.src); };
            img.onerror = () => {
                const url = paintPhoto(id);
                this.photoCache[id] = url;
                resolve(url);
            };
            img.src = Residents[id].photo;
        });
    }
}

// ---------------------------------------------------------------------------
// Procedural Polaroid placeholders
// ---------------------------------------------------------------------------

function figure(ctx, x, y, s, body, hair, extra) {
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(s, s);
    ctx.fillStyle = "#2b2622";
    ctx.fillRect(-9, 40, 7, 40); ctx.fillRect(2, 40, 7, 40);
    ctx.fillStyle = body;
    ctx.beginPath(); ctx.roundRect(-18, -12, 36, 58, 9); ctx.fill();
    if (extra === "apron") { ctx.fillStyle = "#e9efe6"; ctx.fillRect(-11, 2, 22, 40); }
    ctx.fillStyle = "#d9b08c";
    ctx.beginPath(); ctx.arc(0, -26, 14, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = hair;
    ctx.beginPath(); ctx.arc(0, -29, 14.5, Math.PI, 0); ctx.fill();
    if (extra === "cap") { ctx.fillRect(-2, -34, 22, 5); }
    ctx.fillStyle = "#1a1a1a";
    ctx.fillRect(-6, -27, 3, 3); ctx.fillRect(4, -27, 3, 3);
    ctx.strokeStyle = "#1a1a1a"; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.arc(0, -21, 4, 0.2, Math.PI - 0.2); ctx.stroke();
    if (extra === "apron") {
        ctx.strokeRect(-9, -30, 7, 5); ctx.strokeRect(2, -30, 7, 5);
    }
    ctx.restore();
}

function pigeon(ctx, x, y, s, flying) {
    ctx.save();
    ctx.translate(x, y); ctx.scale(s, s);
    ctx.fillStyle = "#6f737a";
    if (flying) {
        ctx.beginPath();
        ctx.moveTo(-12, -2); ctx.quadraticCurveTo(-5, -10, 0, 0);
        ctx.quadraticCurveTo(5, -10, 12, -2);
        ctx.quadraticCurveTo(4, -2, 0, 3); ctx.quadraticCurveTo(-4, -2, -12, -2);
        ctx.fill();
    } else {
        ctx.beginPath(); ctx.ellipse(0, 0, 8, 5, 0, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.arc(7, -5, 3.5, 0, Math.PI * 2); ctx.fill();
    }
    ctx.restore();
}

function filmFinish(ctx, w, h, tint) {
    // warm/cool cast, vignette and grain for an instant-film feel
    ctx.fillStyle = tint;
    ctx.globalCompositeOperation = "soft-light";
    ctx.fillRect(0, 0, w, h);
    ctx.globalCompositeOperation = "source-over";
    const g = ctx.createRadialGradient(w / 2, h / 2, w * 0.3, w / 2, h / 2, w * 0.75);
    g.addColorStop(0, "rgba(0,0,0,0)");
    g.addColorStop(1, "rgba(20,10,0,0.45)");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);
    const img = ctx.getImageData(0, 0, w, h);
    for (let i = 0; i < img.data.length; i += 4) {
        const n = (Math.random() - 0.5) * 22;
        img.data[i] += n; img.data[i + 1] += n; img.data[i + 2] += n;
    }
    ctx.putImageData(img, 0, 0);
}

export function paintPhoto(id) {
    const w = 320, h = 320;
    const c = document.createElement("canvas");
    c.width = w; c.height = h;
    const ctx = c.getContext("2d");

    if (id === "lau") {
        ctx.fillStyle = "#9cc0ad";
        ctx.fillRect(0, 0, w, h);
        ctx.strokeStyle = "rgba(255,255,255,0.35)";
        for (let x = 0; x < w; x += 20) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, 200); ctx.stroke(); }
        for (let y = 0; y < 200; y += 20) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke(); }
        ctx.fillStyle = "#8f9a8e"; ctx.fillRect(0, 200, w, 120);
        // certificate + calendar
        ctx.fillStyle = "#6a4a2a"; ctx.fillRect(40, 50, 60, 46);
        ctx.fillStyle = "#f2ecd8"; ctx.fillRect(45, 55, 50, 36);
        ctx.fillStyle = "#b03a2e"; ctx.fillRect(250, 40, 40, 56);
        ctx.fillStyle = "#f2ecd8"; ctx.fillRect(254, 56, 32, 36);
        // lamp
        ctx.strokeStyle = "#777"; ctx.lineWidth = 5;
        ctx.beginPath(); ctx.moveTo(230, 300); ctx.lineTo(230, 90); ctx.lineTo(170, 90); ctx.stroke();
        ctx.fillStyle = "#fff6c8"; ctx.beginPath(); ctx.ellipse(170, 100, 18, 10, 0, 0, Math.PI * 2); ctx.fill();
        // chair
        ctx.fillStyle = "#3f7a78";
        ctx.beginPath(); ctx.roundRect(70, 150, 40, 110, 10); ctx.fill();
        ctx.beginPath(); ctx.roundRect(90, 220, 110, 36, 10); ctx.fill();
        ctx.fillStyle = "#d8d6cc"; ctx.fillRect(110, 256, 60, 44);
        figure(ctx, 210, 185, 1.25, "#5f9a62", "#222", "apron");
        // boxes
        ctx.fillStyle = "#a8834f"; ctx.fillRect(10, 250, 70, 60);
        ctx.fillStyle = "#d8cfa8"; ctx.fillRect(10, 272, 70, 6);
        ctx.fillStyle = "#9c7a48"; ctx.fillRect(250, 262, 70, 58);
        filmFinish(ctx, w, h, "rgba(255,200,120,0.35)");
    } else {
        const sky = ctx.createLinearGradient(0, 0, 0, 220);
        sky.addColorStop(0, "#6fa6d6"); sky.addColorStop(1, "#cfe3ef");
        ctx.fillStyle = sky; ctx.fillRect(0, 0, w, h);
        // plane overhead
        ctx.fillStyle = "#eeeeea";
        ctx.beginPath(); ctx.ellipse(170, 38, 110, 14, -0.05, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.moveTo(150, 38); ctx.lineTo(110, 0); ctx.lineTo(135, 0); ctx.lineTo(200, 38); ctx.fill();
        ctx.fillStyle = "#a8453a"; ctx.fillRect(80, 36, 150, 4);
        ctx.fillStyle = "#a8453a"; ctx.beginPath(); ctx.moveTo(60, 38); ctx.lineTo(48, 8); ctx.lineTo(70, 8); ctx.lineTo(85, 36); ctx.fill();
        // skyline + antennas
        ctx.fillStyle = "#8a96a0";
        for (let x = 0; x < w; x += 26) {
            const bh = 30 + ((x * 37) % 50);
            ctx.fillRect(x, 200 - bh, 24, bh + 10);
        }
        ctx.strokeStyle = "#444"; ctx.lineWidth = 2;
        for (let x = 12; x < w; x += 44) {
            ctx.beginPath(); ctx.moveTo(x, 200); ctx.lineTo(x, 130); ctx.moveTo(x - 12, 140); ctx.lineTo(x + 12, 140); ctx.stroke();
        }
        ctx.fillStyle = "#8f8b80"; ctx.fillRect(0, 200, w, 120);
        // coop
        ctx.strokeStyle = "#555"; ctx.lineWidth = 1;
        ctx.fillStyle = "#6b4a30"; ctx.fillRect(10, 175, 120, 8);
        for (let x = 12; x < 130; x += 8) { ctx.beginPath(); ctx.moveTo(x, 183); ctx.lineTo(x, 260); ctx.stroke(); }
        for (let y = 183; y < 260; y += 8) { ctx.beginPath(); ctx.moveTo(10, y); ctx.lineTo(130, y); ctx.stroke(); }
        for (let i = 0; i < 4; i++) pigeon(ctx, 30 + i * 26, 250, 1.4, false);
        figure(ctx, 200, 205, 1.3, "#7a5a3c", "#555", "cap");
        [[240, 90], [270, 120], [215, 70], [290, 80], [60, 110], [100, 95], [150, 120]].forEach(([x, y], i) =>
            pigeon(ctx, x, y, 1 + (i % 3) * 0.3, true));
        pigeon(ctx, 243, 150, 1.4, false); // one on his hand
        filmFinish(ctx, w, h, "rgba(120,190,255,0.25)");
    }
    return c.toDataURL("image/png");
}
