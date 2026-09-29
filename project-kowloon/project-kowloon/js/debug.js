import { GameState, StageNames, DirectionNames, lockReasons } from "./gameState.js";
import { TeleportPoints } from "./data/questData.js";

// Debug overlay and developer shortcuts (sections 70-72).
// F1 (or the ` key) toggles the overlay. While it is open:
//   1-6 teleport, F2 / ] advance quest stage, F3 / [ rewind.

export class DebugOverlay {
    constructor(sys) {
        Object.assign(this, sys); // player, cam, interaction, quests
        this.el = document.getElementById("debug");
        this.frames = 0;
        this.acc = 0;
        this.fps = 0;
    }

    toggle() {
        GameState.debug = !GameState.debug;
        this.el.classList.toggle("hidden", !GameState.debug);
    }

    handleKey(code) {
        if (!GameState.debug) return false;
        const n = { Digit1: 1, Digit2: 2, Digit3: 3, Digit4: 4, Digit5: 5, Digit6: 6 }[code];
        if (n) {
            const tp = TeleportPoints[n];
            this.player.teleport(...tp.pos);
            if (tp.pos[1] > 12) this.quests.onEnterRoof();
            return true;
        }
        if (code === "F2" || code === "BracketRight") {
            this.quests.forceStage(GameState.stage + 1);
            return true;
        }
        if (code === "F3" || code === "BracketLeft") {
            this.quests.forceStage(GameState.stage - 1);
            return true;
        }
        return false;
    }

    update(delta) {
        this.frames++;
        this.acc += delta;
        if (this.acc >= 0.5) {
            this.fps = Math.round(this.frames / this.acc);
            this.frames = 0;
            this.acc = 0;
        }
        if (!GameState.debug) return;
        const p = this.player.position;
        const cur = this.interaction.current;
        const t = Object.entries(GameState.timings)
            .map(([k, v]) => `${k.padEnd(15)} ${Math.floor(v / 60)}:${String(Math.floor(v % 60)).padStart(2, "0")}`)
            .join("\n");
        this.el.textContent =
`X: ${p.x.toFixed(1)}
Y: ${p.y.toFixed(1)}
Z: ${p.z.toFixed(1)}

Camera: ${DirectionNames[this.cam.direction]}
Quest: ${StageNames[GameState.stage]}
Objective: ${GameState.objective || "-"}
Interactable: ${cur ? cur.id : "none"}
Locks: ${lockReasons().join(", ") || "none"}
FPS: ${this.fps}

1-6 teleport · F2/] next · F3/[ back
${t ? "\nTimings\n" + t : ""}`;
    }
}
