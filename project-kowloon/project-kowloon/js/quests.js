import * as THREE from "three";
import { GameState, QuestStage as S, lock, unlock, markTiming } from "./gameState.js";
import { Objectives, flagsForStage, scrapbookForStage } from "./data/questData.js";
import { Priority } from "./interaction.js";
import { UI, wait } from "./ui.js";
import { LEVEL } from "./world.js";

// Quest progression (sections 43-58). Linear narrative, spatial freedom.

export class QuestManager {
    constructor(sys) {
        Object.assign(this, sys); // world, player, cam, dialogue, interaction, photography, scrapbook, audio
        this.pigeonAnim = null;
        this.errand = null;          // the Chan boy's trip with the washing
        this.tasks = [];             // game-time scheduler (pauses with menus)
        this.seen = {};              // one-time "it lines up" lines
        this.hints = { move: true, rotate: false, camera: false, scrapbook: false };
        this.movedDistance = 0;
        this.lastPos = new THREE.Vector3();

        this.photography.onCapture = id => this.onPhotoTaken(id);
        this.world.onNPCBlocked = id => {
            if (id === "son") UI.notice("Chan's son: \u201CExcuse me, Mei, coming through!\u201D", 2400);
        };

        this.registerInteractions();
        this.registerPhotoTargets();
    }

    // ------------------------------------------------------------------ stage

    setStage(stage) {
        GameState.stage = stage;
        Object.assign(GameState.flags, flagsForStage(stage));
        const o = Objectives[stage] || { objective: "", hint: "" };
        GameState.objective = o.objective;
        GameState.hint = o.hint;
        UI.setObjective(o.objective, o.hint);
        this.syncWorld();
    }

    // Used by debug stage jumps so the world always matches the stage.
    forceStage(stage) {
        stage = Math.max(0, Math.min(S.COMPLETE, stage));
        GameState.scrapbook = scrapbookForStage(stage);
        this.resetErrand(stage >= S.FABRIC_MOVED);
        const door = this.world.refs.serviceDoor;
        if (stage >= S.REACHED_LAU) { door.discovered = true; this.world.openDoor(door); }
        if (stage >= S.FOUND_SON) this.world.holds.forEach(h => { h.discovered = true; });
        if (stage >= S.HELPED_NG) {
            GameState.flags.pigeonFound = true;
            if (!this.sheetDown) { this.sheetDown = true; this.world.sheetObstacle.active = () => false; this.sheetAnim = { t: 1 }; }
        }
        this.setStage(stage);
    }

    syncWorld() {
        const st = GameState.stage;
        const w = this.world;

        GameState.flags.fabricMoved = w.fabricState !== "catwalk";
        // The stair door opens only once the Chan boy has actually opened it.
        if (st >= S.FABRIC_MOVED) GameState.flags.roofDoorOpen = !!(this.errand && this.errand.doorOpen);

        if (st >= S.HELPED_NG && !this.pigeonAnim) {
            w.refs.lostPigeon.position.copy(w.pigeonPath[w.pigeonPath.length - 1]);
        } else if (st < S.HELPED_NG && !this.pigeonAnim) {
            w.refs.lostPigeon.position.copy(w.pigeonPath[0]);
        }
    }

    // ------------------------------------------------------------------ helpers

    say(id, then) {
        this.dialogue.start(id, then);
    }

    // Play a line the first time only; afterwards just do the action.
    once(id, then) {
        if (this.seen[id]) return then();
        this.seen[id] = true;
        this.say(id, then);
    }

    async transition(pos, { steps = 8, onArrive } = {}) {
        lock("transition");
        this.audio.footsteps(steps, 0.14);
        await UI.fadeOut(380);
        this.player.teleport(pos.x, pos.y, pos.z);
        this.syncWorld();
        await wait(250);
        UI.fadeIn(450);
        unlock("transition");
        onArrive && onArrive();
    }

    onEnterRoof() {
        if (GameState.flags.rooftopVisited) return;
        GameState.flags.rooftopVisited = true;
        markTiming("rooftopReached");
        // Section 47: a few quiet seconds with no dialogue and no UI.
        UI.setQuiet(true);
        this.later(() => {
            this.world.playPlane();
            this.audio.plane();
        }, 2.6);
        this.later(() => { if (!this.photography.active) UI.setQuiet(false); }, 8.5);
    }

    // ------------------------------------------------------------------ interactions

    registerInteractions() {
        const I = this.interaction;
        const w = this.world;
        const npc = w.npcs;
        const dir = () => this.cam.direction;

        const talk = (id, radius, fn, extra = {}) => I.add({
            id,
            position: () => npc[id].position,
            radius,
            priority: Priority.NPC,
            verb: "Talk",
            canInteract: () => npc[id].visible && !npc[id].userData.gone && !npc[id].userData.walkTo,
            interact: fn,
            ...extra
        });

        // Main residents
        talk("grandfather", 1.5, () => {
            const st = GameState.stage;
            if (st === S.START) this.say("grandfather_intro", () => this.setStage(S.MEDICINE_RECEIVED));
            else if (st >= S.RETURNED_HOME) this.say("grandfather_end");
            else if (st >= S.CATWALK_BLOCKED) this.say("grandfather_late");
            else this.say("grandfather_idle");
        });

        talk("lau", 2.0, () => {
            const st = GameState.stage;
            if (st <= S.MEDICINE_RECEIVED) this.lauIntro();
            else if (st === S.REACHED_LAU) this.say("lau_waiting");
            else if (st >= S.MEDICINE_DELIVERED) this.say("lau_return");
            else this.say("lau_idle");
        });

        talk("chan", 1.9, () => {
            const st = GameState.stage;
            if (st < S.CATWALK_BLOCKED) this.say("chan_early");
            else if (st === S.CATWALK_BLOCKED) {
                markTiming("chanReached");
                this.say("chan_quest", () => {
                    this.setStage(S.MET_CHAN);
                    this.setStage(S.SEARCHING_FOR_SON);
                });
            } else if (st < S.FOUND_SON) this.say("chan_waiting");
            else if (st < S.FABRIC_MOVED) this.say("chan_told");
            else if (w.fabricState === "catwalk") this.say("chan_coming");
            else this.say("chan_after");
        });

        talk("son", 1.6, () => {
            const st = GameState.stage;
            const step = this.errand && this.errand.step;
            if (step === "waiting" || step === "unpinning") this.say("son_catwalk");
            else if (st >= S.FABRIC_MOVED) this.say("son_after");
            else if (st === S.HELPED_NG) this.say("son_photo");
            else if (st === S.FOUND_SON) this.say("son_waiting");
            else if (st === S.CATWALK_BLOCKED) this.say("son_found_nochan", () => this.setStage(S.FOUND_SON));
            else if (st >= S.MET_CHAN) this.say("son_found", () => this.setStage(S.FOUND_SON));
            else this.say("son_shh");
        });

        talk("ng", 1.9, () => {
            const st = GameState.stage;
            if (st < S.MET_CHAN) this.say("ng_stranger");
            else if (st < S.FOUND_SON) this.say("ng_early");
            else if (st === S.FOUND_SON) {
                if (this.ngBriefed) this.say("ng_waiting");
                else this.say("ng_quest", () => { this.ngBriefed = true; });
            } else if (st === S.HELPED_NG) this.say("ng_waiting_photo");
            else this.say("ng_after");
        });

        talk("wong", 1.9, () => {
            const st = GameState.stage;
            if (st >= S.MEDICINE_DELIVERED) return this.say("wong_after");
            markTiming("wongReached");
            this.say("wong_deliver", () => this.setStage(S.MEDICINE_DELIVERED));
        });

        // Ambient residents
        const ambient = [
            ["chopper", "chopper", 1.8], ["mahjong2", "mahjong", 1.9], ["fanman", "fanman", 1.3],
            ["shopkeeper", "shopkeeper", 2.2], ["worker", "worker", 1.5], ["child", "child", 1.5]
        ];
        ambient.forEach(([id, line, r]) => talk(id, r, () => this.say(line)));

        // Stairs A <-> B
        I.add({
            id: "stairsUp", position: w.refs.stairsUpA, radius: 1.3, priority: Priority.QUEST,
            verb: "Go upstairs",
            interact: () => {
                if (GameState.stage < S.LAU_PHOTO) return this.say("stairs_blocked");
                this.transition(new THREE.Vector3(9.2, LEVEL.B, -12.4));
            }
        });
        I.add({
            id: "stairsDown", position: w.refs.stairsDownB, radius: 1.0, priority: Priority.QUEST,
            verb: "Go downstairs",
            interact: () => this.transition(new THREE.Vector3(9.3, LEVEL.A, -12.6))
        });

        // Roof door (opened by the Chan boy after the pigeon scene)
        I.add({
            id: "roofDoorB", position: w.refs.roofDoorB, radius: 1.0, priority: Priority.QUEST,
            verb: "Roof door",
            interact: () => {
                if (!GameState.flags.roofDoorOpen) return this.say("roofdoor_latched");
                this.transition(new THREE.Vector3(10.4, LEVEL.ROOF, -11.2), { steps: 14, onArrive: () => this.onEnterRoof() });
            }
        });
        I.add({
            id: "roofDoorTop", position: w.refs.roofDoorTop, radius: 1.1, priority: Priority.QUEST,
            verb: "Stairwell door",
            interact: () => {
                if (!GameState.flags.roofDoorOpen) return this.say("roofdoor_top_stuck");
                this.transition(new THREE.Vector3(10.6, LEVEL.B, -13.2), { steps: 14 });
            }
        });

        // Wet fabric
        I.add({
            id: "fabric", position: w.refs.fabricPos, radius: 1.4, priority: Priority.QUEST,
            verb: "Look",
            canInteract: () => w.fabricState === "catwalk" && !(this.errand && ["waiting", "unpinning"].includes(this.errand.step)),
            interact: () => {
                if (GameState.stage === S.LAU_PHOTO) {
                    this.say("fabric_first", () => this.setStage(S.CATWALK_BLOCKED));
                } else this.say("fabric_again");
            }
        });

        // The service door at the end of the hall. No prompt, and it won't
        // open, until Mei has actually seen it.
        const door = w.refs.serviceDoor;
        I.add({
            id: "serviceDoor", radius: 1.3, priority: Priority.QUEST, verb: "Door",
            position: () => {
                const side = Math.sign(this.player.position.clone().sub(door.pos).dot(door.normal)) || 1;
                return door.pos.clone().addScaledVector(door.normal, side * 0.7);
            },
            canInteract: () => door.discovered && !door.open,
            interact: () => {
                this.audio.creak();
                w.openDoor(door);
            }
        });

        // Airshaft climb (sections 45-46). Mei can only climb using handholds
        // she has seen, and each one is on a different wall.
        const shaftRoute = () => ["ladder", "sign", "platform"].every(id => w.holds.find(h => h.id === id).discovered);
        I.add({
            id: "shaftBase", position: w.refs.shaftBase, radius: 1.8, priority: Priority.QUEST,
            verb: "Look up",
            interact: () => {
                if (!shaftRoute()) return this.say(this.shaftLines());
                this.once("shaft_route", () => {
                    this.audio.creak();
                    this.player.traverse(w.climbNodes, { speed: 2.3, onDone: () => this.onEnterRoof() });
                });
            }
        });
        I.add({
            id: "shaftTop", position: w.refs.shaftTop, radius: 1.2, priority: Priority.QUEST,
            verb: "Look down",
            interact: () => {
                if (!shaftRoute()) return this.say("shaft_down_unknown");
                this.audio.creak();
                const nodes = w.climbNodes.slice().reverse();
                nodes.push(new THREE.Vector3(-5, LEVEL.B, -17.4));
                this.player.traverse(nodes, { speed: 2.6, onDone: () => this.syncWorld() });
            }
        });

        // Lost pigeon (section 50): first find her (she's behind the tank from
        // most sides), then work out why she won't come down.
        I.add({
            id: "sheet", position: w.refs.sheetSpot, radius: 1.6, priority: Priority.QUEST,
            verb: "Look",
            canInteract: () => !this.sheetDown,
            interact: () => {
                if (GameState.stage === S.FOUND_SON && GameState.flags.pigeonFound) {
                    this.once("sheet_unpin", () => this.unpinSheet());
                } else this.say("sheet_plain");
            }
        });

        // Packing boxes: only worth a look once Mei is home again (section 56).
        I.add({
            id: "boxes", position: w.refs.boxesPos, radius: 1.3, priority: Priority.QUEST,
            verb: "Look",
            canInteract: () => GameState.stage === S.RETURNED_HOME,
            interact: () => this.say("boxes_end", () => this.ending())
        });

        // Environmental descriptions
        const env = (id, pos, text, radius = 1.3, pri = Priority.ENV) => I.add({
            id, position: pos, radius, priority: pri, verb: "Look",
            interact: () => this.say([{ speaker: null, text }])
        });
        env("radio", new THREE.Vector3(-13.2, 0, -1.3), "Grandfather's radio. Something cheerful, half lost in static.", 1.2);
        env("chair", new THREE.Vector3(4.9, 0, -11.0), "The old dental chair. The vinyl is patched with tape in three places.", 1.1);
        env("sign", new THREE.Vector3(3, 0, -8.2), "劉牙科. Lau Dental. The paint on the sign is older than you are.", 1.0, Priority.DECOR);
        env("coop", new THREE.Vector3(3, LEVEL.ROOF, -21), "Mr. Ng's coop. Every bird has a name written on a strip of tape.", 1.4, Priority.DECOR);
        env("dead-end", new THREE.Vector3(1.2, 0, -0.5), "The blue pipe runs straight into the wall.", 1.0, Priority.DECOR);
        env("well", new THREE.Vector3(18, LEVEL.B, -12), "Far below, the alley is full of other people's rubbish.", 1.0, Priority.DECOR);
    }

    registerPhotoTargets() {
        const npc = this.world.npcs;
        this.photography.addTarget("lau", npc.lau, () => GameState.stage === S.REACHED_LAU && !GameState.scrapbook.includes("lau"));
        this.photography.addTarget("ng", npc.ng, () => GameState.stage === S.HELPED_NG && !GameState.scrapbook.includes("ng"));
    }

    // ------------------------------------------------------------------ the washing (section 52)
    //
    // After Mr. Ng's photo the Chan boy opens the stuck stair door and goes
    // down to the catwalk. He waits there until Mei arrives, takes the washing
    // down in front of her, carries it back upstairs and hangs it on the roof
    // line. The catwalk is on the only route to Mrs. Wong, so every player sees
    // the washing move. Timing runs on game time and pauses while menus are open.

    // Run fn after `secs` of game time, optionally only once cond() is true.
    later(fn, secs = 0, cond = null) {
        this.tasks.push({ t: secs, fn, cond });
    }

    runTasks(delta, paused) {
        if (paused) return;
        const due = [];
        this.tasks = this.tasks.filter(task => {
            task.t -= delta;
            if (task.t <= 0 && (!task.cond || task.cond())) { due.push(task.fn); return false; }
            return true;
        });
        due.forEach(fn => fn());
    }

    // Is Mei close to a point on the same level?
    meiNear(x, y, z, r) {
        const p = this.player.position;
        return Math.abs(p.y - y) < 1 && Math.hypot(p.x - x, p.z - z) < r;
    }

    startSonErrand() {
        const w = this.world, R = LEVEL.ROOF, B = LEVEL.B;
        const son = w.npcs.son;
        this.errand = { step: "toDoor", doorOpen: false };

        // Across the roof to the stair hut, around the crates.
        w.walkNPC("son", [[7.5, R, -11.3], [10.4, R, -11.6]], () => {
            this.audio.creak();
            this.errand.doorOpen = true;
            this.errand.step = "downstairs";
            w.fadeNPC("son", "out");

            // Comes out on the landing, but never right on top of Mei.
            this.later(() => {
                w.placeAt("son", 10.4, B, -14.1);
                w.fadeNPC("son", "in");
                this.errand.step = "toCatwalk";
                w.walkNPC("son", [[11.6, B, -12.3], [15.0, B, -11.55]], () => {
                    this.errand.step = "waiting";

                    // Waits by the washing until Mei is close enough to see.
                    this.later(() => {
                        this.errand.step = "unpinning";
                        son.userData.anim = "work";
                        UI.notice("Chan's son: \u201CHold on, they're still wet!\u201D", 3200);

                        this.later(() => {
                            w.setFabricState("bundle");
                            son.userData.anim = "idle";
                            this.errand.step = "carrying";
                            w.walkNPC("son", [[11.6, B, -12.3], [10.4, B, -14.1]], () => {
                                this.audio.creak();
                                this.errand.step = "upstairs";
                                w.fadeNPC("son", "out");

                                this.later(() => {
                                    w.placeAt("son", 10.4, R, -11.6);
                                    w.fadeNPC("son", "in");
                                    this.errand.step = "toLine";
                                    // Along the roof, clear of the pots and line poles.
                                    w.walkNPC("son", [[4, R, -11], [-3, R, -11], [-5.4, R, -9.6]], () => {
                                        w.setFabricState("roof");
                                        this.errand.step = "done";
                                    });
                                }, 2.5, () => !this.meiNear(10.4, R, -11.6, 1.2));
                            });
                        }, 3.5);
                    }, 0, () => this.meiNear(15.0, B, -12, 5.5));
                });
            }, 2.5, () => !this.meiNear(10.4, B, -14.1, 1.2));
        });
    }

    // Debug stage jumps: either finish the errand instantly or undo it.
    resetErrand(finished) {
        this.tasks = [];
        const w = this.world, son = w.npcs.son;
        son.userData.gone = false;
        son.userData.fade = null;
        son.material.opacity = 1;
        son.userData.anim = "idle";
        if (finished) {
            this.errand = { step: "done", doorOpen: true };
            w.setFabricState("roof");
            w.placeAt("son", -5.4, LEVEL.ROOF, -9.6);
        } else {
            this.errand = null;
            w.setFabricState("catwalk");
            w.placeAt("son", 0.2, LEVEL.ROOF, -19.4);
        }
    }

    // ------------------------------------------------------------------ discovery
    //
    // Nothing appears or disappears when the view turns. Turning only changes
    // what Mei can see, and she can only use what she has seen.

    discover(delta) {
        if (this.cam.rotating || GameState.controlsLocked && !this.player.path) return;
        const w = this.world, p = this.player.position;
        const back = this.cam.backVector(new THREE.Vector3());

        // Doors: the camera must look at the door face-on (not edge-on).
        for (const d of w.doors) {
            if (d.discovered || Math.abs(p.y - d.pos.y) > 1.5) continue;
            if (Math.hypot(p.x - d.pos.x, p.z - d.pos.z) > 9) continue;
            // (from either side: with the near walls cut away you can see a
            // door from behind too, and what's on screen should count)
            const facing = d.normal.dot(back);
            if (Math.abs(facing) > 0.6) {
                d.discovered = true;
                this.audio.chime();
                markTiming("found:" + d.id);
            }
        }

        // Handholds: Mei in the shaft (or at its top) and the hold's face toward the camera.
        const inShaft = (p.y > 4 && p.y < 12.5 && p.x > -7.2 && p.x < -2.8 && p.z < -15.6 && p.z > -21.2) ||
            (p.y > 12 && Math.hypot(p.x + 5, p.z + 15.4) < 2.5);
        if (inShaft) {
            for (const h of w.holds) {
                if (h.discovered) continue;
                if (h.normal && h.normal.dot(back) < 0.5) continue;
                h.discovered = true;
                if (h.normal) { this.audio.chime(); UI.notice(h.name, 3200); }
            }
        }

        // The pigeon: really occluded by the tank, checked with a ray.
        if (!GameState.flags.pigeonFound && p.y > 12 && GameState.stage < S.HELPED_NG) {
            const bird = w.refs.lostPigeon.position.clone(); bird.y += 0.2;
            if (bird.distanceTo(p) < 16 && this.onScreen(bird) && !this.occluded(bird, [w.refs.tank])) {
                GameState.flags.pigeonFound = true;
                this.audio.chime();
                UI.notice(GameState.stage >= S.FOUND_SON
                    ? "There she is, tucked in behind the water tank."
                    : "A pigeon, tucked in behind the water tank.", 3600);
            }
        }
    }

    onScreen(v) {
        const q = v.clone().project(this.cam.camera);
        return Math.abs(q.x) < 0.95 && Math.abs(q.y) < 0.95;
    }

    occluded(target, meshes) {
        const dir = new THREE.Vector3();
        this.cam.camera.getWorldDirection(dir);
        const origin = target.clone().addScaledVector(dir, -40);
        this.ray = this.ray || new THREE.Raycaster();
        this.ray.set(origin, dir);
        const hits = this.ray.intersectObjects(meshes, true);
        return hits.length > 0 && hits[0].distance < 39.7;
    }

    shaftLines() {
        const seen = this.world.holds.filter(h => h.discovered && h.normal);
        const lines = [{ speaker: null, text: "An airshaft. Old junk bolted to the walls all the way up." }];
        seen.forEach(h => lines.push({ speaker: null, text: h.name }));
        lines.push({ speaker: null, text: seen.length
            ? "Not enough to make a way up. Not that you can see from here."
            : "From here you can't make out a way up." });
        return lines;
    }

    unpinSheet() {
        this.sheetDown = true;
        const w = this.world;
        w.sheetObstacle.active = () => false;
        this.sheetAnim = { t: 0 };
        this.later(() => this.guidePigeon(), 0.6);
    }

    // ------------------------------------------------------------------ story beats

    startIntro() {
        this.say("grandfather_intro", () => {
            this.setStage(S.MEDICINE_RECEIVED);
            UI.showHint("[WASD] Move &nbsp; [F] Interact");
        });
    }

    lauIntro() {
        markTiming("lauReached");
        this.say("lau_intro", () => {
            this.setStage(S.REACHED_LAU);
            this.hints.camera = true;
            UI.showHint("[C] Raise the camera");
        });
    }

    guidePigeon() {
        lock("pigeon");
        this.audio.flutter();
        const pts = this.world.pigeonPath;
        const curve = new THREE.CatmullRomCurve3(pts);
        this.pigeonAnim = { t: 0, curve, duration: 3.2 };
    }

    onPigeonHome() {
        this.pigeonAnim = null;
        unlock("pigeon");
        this.audio.coo(this.audio.master, 0.3);
        this.say("ng_helped", () => {
            this.setStage(S.HELPED_NG);
            UI.showHint("[C] Raise the camera");
            this.hints.camera = true;
        });
    }

    onPhotoTaken(id) {
        this.scrapbook.unlock(id);
        if (id === "lau") {
            this.say("lau_after_photo", () => {
                this.setStage(S.LAU_PHOTO);
                this.hints.scrapbook = true;
                UI.showHint("[TAB] Scrapbook");
                setTimeout(() => { if (this.hints.scrapbook) { this.hints.scrapbook = false; UI.showHint(null); } }, 9000);
            });
        } else if (id === "ng") {
            this.say("son_leaves", () => {
                this.startSonErrand();
                this.setStage(S.FABRIC_MOVED);
            });
        }
    }

    async homecoming() {
        markTiming("homeReached");
        lock("homecoming");
        await wait(400);
        unlock("homecoming");
        // The day ends only when the player chooses to look at the boxes.
        this.say("grandfather_return", () => this.setStage(S.RETURNED_HOME));
    }

    async ending() {
        if (GameState.stage === S.COMPLETE) return;
        this.setStage(S.COMPLETE);
        markTiming("ending");
        lock("ending");
        UI.setQuiet(true);
        this.audio.silence(3200);
        await UI.fadeOut(3000);
        const end = document.getElementById("ending");
        end.classList.remove("hidden");
        const lines = end.querySelectorAll(".end-line");
        for (const [i, el] of lines.entries()) {
            await wait(i === 0 ? 800 : 2600);
            el.classList.add("visible");
        }
    }

    // ------------------------------------------------------------------ per frame

    update(delta, paused = false) {
        const p = this.player.position;
        const st = GameState.stage;

        this.runTasks(delta, paused);
        this.discover(delta);
        if (this.sheetAnim) {
            this.sheetAnim.t = Math.min(1, this.sheetAnim.t + delta * 2);
            this.world.refs.sheet.rotation.x = -this.sheetAnim.t * 1.2;   // one corner unpinned, swung aside
        }

        this.syncWorld();

        // Pigeon flight
        if (this.pigeonAnim) {
            const a = this.pigeonAnim;
            a.t += delta / a.duration;
            const t = Math.min(1, a.t);
            this.world.refs.lostPigeon.position.copy(a.curve.getPoint(t));
            if (t >= 1) this.onPigeonHome();
        }

        // Movement hint disappears after a few steps
        if (this.hints.move && st >= S.MEDICINE_RECEIVED) {
            this.movedDistance += p.distanceTo(this.lastPos);
            if (this.movedDistance > 6) {
                this.hints.move = false;
                if (!this.hints.camera && !this.hints.scrapbook) UI.showHint(null);
            }
        }
        this.lastPos.copy(p);

        // Leaving the apartment
        if (st >= S.MEDICINE_RECEIVED && p.x > -5.8 && p.y < 1) markTiming("apartmentExit");

        // Section 36: at the dead end, remind the player the view turns
        // (the control, not the answer), until the door has been seen.
        const door = this.world.refs.serviceDoor;
        const atDeadEnd = st >= S.MEDICINE_RECEIVED && p.y < 1 && p.x > 0 && p.x < 2 && Math.abs(p.z) < 1.2;
        this.deadEndT = atDeadEnd && !door.discovered ? (this.deadEndT || 0) + delta : 0;
        if (this.deadEndT > 2.5 && !this.hints.rotate) {
            this.hints.rotate = true;
            UI.showHint("[Q] [E] Turn the view");
        } else if (this.hints.rotate && (door.discovered || !atDeadEnd)) {
            this.hints.rotate = false;
            UI.showHint(null);
        }

        // Camera hint clears once used
        if (this.hints.camera && this.photography.active) {
            this.hints.camera = false;
            UI.showHint(null);
        }
        if (this.hints.scrapbook && this.scrapbook.open) {
            this.hints.scrapbook = false;
            UI.showHint(null);
        }

        // Entering Lau's clinic
        if (st === S.MEDICINE_RECEIVED && p.y < 1 && p.x > 0 && p.x < 8 && p.z < -9.4 && p.z > -15 && !GameState.controlsLocked) {
            this.lauIntro();
        }

        // Coming home
        if (st === S.MEDICINE_DELIVERED && p.y < 1 && p.x < -6.6 && !GameState.controlsLocked) {
            this.homecoming();
        }
    }
}
