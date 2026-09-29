import * as THREE from "three";
import { GameState, on, lockReasons } from "./gameState.js";
import { CameraController } from "./camera.js";
import { World } from "./world.js";
import { Player } from "./player.js";
import { InteractionSystem } from "./interaction.js";
import { DialogueManager } from "./dialogue.js";
import { PhotographySystem } from "./photography.js";
import { ScrapbookManager } from "./scrapbook.js";
import { QuestManager } from "./quests.js";
import { AudioSystem } from "./audio.js";
import { DebugOverlay } from "./debug.js";
import { UI, wait } from "./ui.js";
import { PostFX } from "./postfx.js";

// ---------------------------------------------------------------- setup

UI.init();

// Wait (briefly) for the Chinese display font so the neon signs are painted with it.
try {
    await Promise.race([
        document.fonts.load('700 48px "Noto Serif TC"'),
        new Promise(r => setTimeout(r, 2500))
    ]);
} catch (e) { /* fall back to system fonts */ }

const container = document.getElementById("game-container");
const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: false, powerPreference: "high-performance" });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.25;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFShadowMap;
renderer.outputColorSpace = THREE.SRGBColorSpace;
container.appendChild(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x201c1a);
scene.fog = new THREE.Fog(0x201c1a, 27, 52);

const input = { keys: {} };
const cam = new CameraController(window.innerWidth / window.innerHeight);
const post = new PostFX(renderer, scene, cam.camera);
try { if (localStorage.getItem("kowloon-quality") === "low") post.setQuality("low"); } catch (e) { /* storage unavailable */ }
const world = new World(scene);
const player = new Player(scene, input, cam);
player.teleport(-8.5, 0, 2);

const audio = new AudioSystem();
const dialogue = new DialogueManager(audio);
const interaction = new InteractionSystem(player);
const photography = new PhotographySystem({ cam, scene, player, audio, input });
const scrapbook = new ScrapbookManager(photography);
const quests = new QuestManager({ world, player, cam, dialogue, interaction, photography, scrapbook, audio });
const debug = new DebugOverlay({ player, cam, interaction, quests });

on("dialogueEvent", e => {
    if (e === "receiveCamera") GameState.flags.receivedCamera = true;
    if (e === "planeApproaches") { world.playPlane(); audio.plane(); }
});

// ---------------------------------------------------------------- input

const title = document.getElementById("title");
let started = false;

async function begin() {
    if (started) return;
    started = true;
    audio.start();
    title.classList.add("gone");
    GameState.startTime = performance.now();
    await UI.fadeIn(1400);
    await wait(500);
    quests.startIntro();
}
const beginBtn = document.getElementById("begin");
beginBtn.addEventListener("click", begin);
beginBtn.disabled = false;
beginBtn.textContent = "Begin";

window.addEventListener("keydown", e => {
    const code = e.code;
    if (["Tab", "Space", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "F1", "F2", "F3"].includes(code)) {
        e.preventDefault();
    }
    if (!started) {
        if (code === "Enter" || code === "Space") begin();
        return;
    }
    if (code === "F1" || code === "Backquote") return debug.toggle();
    if (debug.handleKey(code)) return;

    if (GameState.stage === 12 && code === "KeyR") return location.reload();

    input.keys[code] = true;
    if (e.repeat) return;

    switch (code) {
        case "Space":
        case "Enter":
            if (dialogue.isOpen) dialogue.advance();
            else if (photography.showingPhoto) photography.dismiss();
            else if (photography.active) photography.capture();
            break;
        case "KeyF":
            if (dialogue.isOpen) dialogue.advance();
            else if (photography.showingPhoto) photography.dismiss();
            else interaction.trigger();
            break;
        case "KeyQ":
            if (!GameState.controlsLocked) cam.rotate(-1);
            break;
        case "KeyE":
            if (!GameState.controlsLocked) cam.rotate(1);
            break;
        case "KeyC":
            if (photography.active) photography.exit();
            else photography.enter();
            break;
        case "Tab":
            scrapbook.toggle();
            break;
        case "Escape":
            if (scrapbook.open) scrapbook.toggle(false);
            else if (photography.active) photography.exit();
            break;
        case "KeyG": {
            const q = post.quality === "high" ? "low" : "high";
            post.setQuality(q);
            try { localStorage.setItem("kowloon-quality", q); } catch (e) { /* ignore */ }
            UI.notice(q === "high" ? "Graphics: full (shadows, bloom, depth of field)" : "Graphics: fast", 2200);
            break;
        }
    }
});

window.addEventListener("keyup", e => { input.keys[e.code] = false; });
window.addEventListener("blur", () => Object.keys(input.keys).forEach(k => (input.keys[k] = false)));

window.addEventListener("resize", () => {
    post.setSize(window.innerWidth, window.innerHeight);
    cam.resize(window.innerWidth / window.innerHeight);
});

// ---------------------------------------------------------------- loop

let last = performance.now();

function animate() {
    requestAnimationFrame(animate);
    const now = performance.now();
    const delta = Math.min((now - last) / 1000, window.__kowloonMaxDelta || 0.05);
    last = now;

    player.update(delta);
    cam.follow(player.position);
    cam.zoomTarget = player.band === 2 ? 0.72 : 1;
    cam.update(delta);
    const paused = dialogue.isOpen || photography.showingPhoto || scrapbook.open;
    world.update(delta, player, cam, paused);

    if (!photography.active) interaction.update();
    else UI.showPrompt(null);
    photography.update(delta);
    dialogue.update(delta);
    if (started) quests.update(delta, paused);
    audio.update(delta, player.position, world.roofMix, GameState.stage === 12);
    debug.update(delta);

    post.update(now / 1000, world.roofMix);
    post.render();
}
animate();

// Exposed for playtesting from the browser console.
window.kowloon = { lockReasons, GameState, player, cam, world, quests, photography, scrapbook, dialogue };
