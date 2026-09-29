import * as THREE from "three";
import { GameState } from "./gameState.js";
import { UI } from "./ui.js";

// Interaction detection (sections 30-31).
// Priority: 0 NPC dialogue, 1 quest object, 2 environmental description, 3 decorative.
// Only one prompt is shown at a time.

export const Priority = { NPC: 0, QUEST: 1, ENV: 2, DECOR: 3 };

export class InteractionSystem {
    constructor(player) {
        this.player = player;
        this.list = [];
        this.current = null;
        this.enabled = true;
    }

    add(def) {
        const item = {
            radius: 1.5,
            priority: Priority.ENV,
            canInteract: () => true,
            verb: "Look",
            ...def
        };
        this.list.push(item);
        return item;
    }

    positionOf(item) {
        return typeof item.position === "function" ? item.position() : item.position;
    }

    update() {
        this.current = null;
        if (!this.enabled || GameState.controlsLocked) {
            UI.showPrompt(null);
            return;
        }
        const p = this.player.position;
        let best = null, bestPri = Infinity, bestDist = Infinity;

        for (const it of this.list) {
            if (!it.canInteract()) continue;
            const pos = this.positionOf(it);
            if (!pos) continue;
            if (Math.abs(pos.y - p.y) > 1.5) continue;
            const d = Math.hypot(pos.x - p.x, pos.z - p.z);
            if (d > it.radius) continue;
            if (it.priority < bestPri || (it.priority === bestPri && d < bestDist)) {
                best = it; bestPri = it.priority; bestDist = d;
            }
        }

        this.current = best;
        if (best) {
            const verb = typeof best.verb === "function" ? best.verb() : best.verb;
            UI.showPrompt(`[F] ${verb}`);
        } else {
            UI.showPrompt(null);
        }
    }

    trigger() {
        if (this.current && !GameState.controlsLocked) {
            const it = this.current;
            this.current = null;
            UI.showPrompt(null);
            it.interact();
        }
    }
}

export const v3 = (x, y, z) => new THREE.Vector3(x, y, z);
