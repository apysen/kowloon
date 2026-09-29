import * as THREE from "three";
import { GameState, lock, unlock, emit, markTiming } from "./gameState.js";

// Orthographic camera locked to four orientations (sections 22-25).
// Direction 0 looks north (camera sits south of the player).

// Lower than the guide's 25-35°: walls hide more, so looking from
// another side actually shows you something new.
const PITCH = THREE.MathUtils.degToRad(18);
const DISTANCE = 30;
const ROTATION_TIME = 0.38; // seconds, inside the 300-450 ms target

export const VIEW_SIZE = 7;   // close in, like an HD-2D diorama

export class CameraController {
    constructor(aspect) {
        this.camera = new THREE.OrthographicCamera(
            -VIEW_SIZE * aspect, VIEW_SIZE * aspect,
            VIEW_SIZE, -VIEW_SIZE,
            0.1, 200
        );

        this.direction = 0;
        this.currentYaw = 0;
        this.fromYaw = 0;
        this.targetYaw = 0;
        this.rotT = 1;
        this.rotating = false;

        this.target = new THREE.Vector3();
        this.focus = new THREE.Vector3();   // smoothed follow point
        this.panOffset = new THREE.Vector3(); // used by photo mode
        this.zoomTarget = 1;
        this.snapNext = true;
    }

    resize(aspect) {
        this.camera.left = -VIEW_SIZE * aspect;
        this.camera.right = VIEW_SIZE * aspect;
        this.camera.top = VIEW_SIZE;
        this.camera.bottom = -VIEW_SIZE;
        this.camera.updateProjectionMatrix();
    }

    rotate(step) {
        if (this.rotating) return false;
        this.rotating = true;
        lock("rotation");

        this.direction = (this.direction + step + 4) % 4;
        GameState.cameraDirection = this.direction;

        this.fromYaw = this.currentYaw;
        this.targetYaw = this.currentYaw + step * Math.PI / 2;
        this.rotT = 0;

        if (!GameState.hasRotated) {
            GameState.hasRotated = true;
            markTiming("firstRotation");
        }
        emit("rotateStart", this.direction);
        return true;
    }

    // Unit vector pointing from the focus toward the camera (horizontal).
    backVector(out = new THREE.Vector3()) {
        return out.set(Math.sin(this.currentYaw), 0, Math.cos(this.currentYaw));
    }

    rightVector(out = new THREE.Vector3()) {
        return out.set(Math.cos(this.currentYaw), 0, -Math.sin(this.currentYaw));
    }

    // Yaw of the settled orientation (used for camera-relative input).
    get settledYaw() {
        return this.direction * Math.PI / 2;
    }

    follow(position) {
        this.target.copy(position);
    }

    update(delta) {
        if (this.rotating) {
            this.rotT = Math.min(1, this.rotT + delta / ROTATION_TIME);
            const t = this.rotT;
            const eased = t < 0.5
                ? 4 * t * t * t
                : 1 - Math.pow(-2 * t + 2, 3) / 2;
            this.currentYaw = THREE.MathUtils.lerp(this.fromYaw, this.targetYaw, eased);

            if (this.rotT >= 1) {
                this.currentYaw = this.targetYaw;
                this.rotating = false;
                unlock("rotation");
                emit("rotateEnd", this.direction);
            }
        }

        const goal = this.target.clone().add(this.panOffset);
        goal.y += 1.2;
        // Look a little past Mei so she sits below centre and the room behind
        // her fills the frame (the foreground is mostly blurred rooftops).
        goal.addScaledVector(this.backVector(new THREE.Vector3()), -2.4);
        if (this.snapNext) {
            this.focus.copy(goal);
            this.snapNext = false;
        } else {
            this.focus.lerp(goal, 1 - Math.pow(0.001, delta));
        }

        const cam = this.camera;
        const horiz = Math.cos(PITCH) * DISTANCE;
        cam.position.set(
            this.focus.x + Math.sin(this.currentYaw) * horiz,
            this.focus.y + Math.sin(PITCH) * DISTANCE,
            this.focus.z + Math.cos(this.currentYaw) * horiz
        );
        cam.lookAt(this.focus);

        const z = THREE.MathUtils.lerp(cam.zoom, this.zoomTarget, 1 - Math.pow(0.2, delta));
        if (Math.abs(z - cam.zoom) > 1e-4) {
            cam.zoom = z;
            cam.updateProjectionMatrix();
        }
    }
}

export const CAMERA_DISTANCE = DISTANCE;
