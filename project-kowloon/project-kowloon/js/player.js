import * as THREE from "three";
import { GameState, lock, unlock } from "./gameState.js";
import { resolveMove } from "./collision.js";
import { makeCharacter, Looks, setFrame } from "./sprites.js";

const SPEED = 4.2;
const RADIUS = 0.32;

export class Player {
    constructor(scene, input, cameraController) {
        this.input = input;
        this.cam = cameraController;
        this.position = new THREE.Vector3(-9, 0, 2);

        this.sprite = makeCharacter("mei", Looks.mei, 1.55);
        this.sprite.userData.noFade = true;
        this.sprite.renderOrder = 3;
        scene.add(this.sprite);

        // Silhouette drawn through walls, so Mei is never lost behind a building.
        // The normal sprite draws over it wherever she's actually visible.
        this.ghost = makeCharacter("mei", Looks.mei, 1.55);
        this.ghost.material = new THREE.MeshBasicMaterial({
            map: this.sprite.material.map, transparent: true, opacity: 0.4, alphaTest: 0.5,
            depthTest: false, depthWrite: false, color: 0xffb070, side: THREE.DoubleSide
        });
        this.ghost.castShadow = false;
        this.ghost.renderOrder = 2;
        scene.add(this.ghost);

        // Soft contact shadow so Mei reads against busy floors.
        const shadow = new THREE.Mesh(
            new THREE.CircleGeometry(0.34, 16),
            new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.22, depthWrite: false })
        );
        shadow.rotation.x = -Math.PI / 2;
        scene.add(shadow);
        this.shadow = shadow;

        this.walkTime = 0;
        this.facing = 1;
        this.path = null;
        this.hidden = false;
    }

    get band() {
        const y = this.position.y;
        return y < 4 ? 0 : y < 12 ? 1 : 2;
    }

    teleport(x, y, z) {
        this.position.set(x, y, z);
        this.path = null;
        this.cam.snapNext = true;
    }

    // Walk/climb along authored points with controls locked (sections 29, 46).
    traverse(points, { speed = 2.6, onDone } = {}) {
        this.path = {
            points: points.map(p => p.clone ? p.clone() : new THREE.Vector3(p[0], p[1], p[2])),
            index: 0,
            speed,
            onDone
        };
        lock("traverse");
    }

    update(delta) {
        let moving = false;

        if (this.path) {
            const target = this.path.points[this.path.index];
            const to = target.clone().sub(this.position);
            const dist = to.length();
            const step = this.path.speed * delta;
            if (dist <= step) {
                this.position.copy(target);
                this.path.index++;
                if (this.path.index >= this.path.points.length) {
                    const done = this.path.onDone;
                    this.path = null;
                    unlock("traverse");
                    done && done();
                }
            } else {
                this.position.add(to.multiplyScalar(step / dist));
            }
            moving = true;
        } else if (!GameState.controlsLocked) {
            const k = this.input.keys;
            const move = new THREE.Vector3();
            if (k.KeyW || k.ArrowUp) move.z -= 1;
            if (k.KeyS || k.ArrowDown) move.z += 1;
            if (k.KeyA || k.ArrowLeft) move.x -= 1;
            if (k.KeyD || k.ArrowRight) move.x += 1;

            if (move.lengthSq() > 0) {
                if (move.x !== 0) this.facing = Math.sign(move.x);
                move.normalize().multiplyScalar(SPEED * delta);
                // Camera-relative: W always means "deeper into the screen".
                move.applyAxisAngle(new THREE.Vector3(0, 1, 0), this.cam.settledYaw);
                // Sub-step so a slow frame can never carry Mei through a thin door.
                const steps = Math.max(1, Math.ceil(move.length() / 0.12));
                for (let i = 0; i < steps; i++) {
                    if (resolveMove(this.position, move.x / steps, move.z / steps, RADIUS)) moving = true;
                }
            }
        }

        if (moving) this.walkTime += delta; else this.walkTime = 0;

        // walk cycle while moving, breathing when still (the bob is in the pixel frames)
        this.idleTime = (this.idleTime || 0) + delta;
        setFrame(this.sprite, moving ? Math.floor(this.walkTime * 9) % 4 : (Math.floor(this.idleTime * 1.4) % 2 ? 5 : 4));
        this.sprite.position.set(this.position.x, this.position.y, this.position.z);
        this.sprite.scale.x = Math.abs(this.sprite.scale.x) * this.facing;
        this.sprite.visible = !this.hidden;
        this.ghost.position.copy(this.sprite.position);
        this.ghost.scale.copy(this.sprite.scale);
        this.ghost.visible = !this.hidden;
        this.shadow.position.set(this.position.x, this.position.y + 0.02, this.position.z);
        this.shadow.visible = !this.hidden;
    }
}

export const PLAYER_RADIUS = RADIUS;
