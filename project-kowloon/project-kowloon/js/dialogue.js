import { GameState, lock, unlock, emit } from "./gameState.js";
import { DialogueData } from "./data/dialogueData.js";

// Dialogue presentation (sections 32-33):
// lock controls, show speaker + text, advance on Space/click, fire callbacks, unlock.

const CHARS_PER_SEC = 55;

export class DialogueManager {
    constructor(audio) {
        this.audio = audio;
        this.box = document.getElementById("dialogue-box");
        this.nameEl = document.getElementById("speaker-name");
        this.textEl = document.getElementById("dialogue-text");
        this.active = null;
        this.box.addEventListener("click", () => this.advance());
    }

    get isOpen() {
        return !!this.active;
    }

    start(idOrLines, onComplete) {
        const lines = typeof idOrLines === "string" ? DialogueData[idOrLines] : idOrLines;
        if (!lines) {
            console.warn("Missing dialogue", idOrLines);
            onComplete && onComplete();
            return;
        }
        lock("dialogue");
        this.active = { lines, index: -1, onComplete, id: idOrLines };
        this.box.classList.remove("hidden");
        this.next();
    }

    next() {
        const a = this.active;
        a.index++;
        if (a.index >= a.lines.length) return this.end();

        const line = a.lines[a.index];
        this.nameEl.textContent = line.speaker ? line.speaker.toUpperCase() : "";
        this.box.classList.toggle("narration", !line.speaker);
        this.full = line.text;
        this.shown = 0;
        this.typing = true;
        this.textEl.textContent = "";
        GameState.dialogueHistory.push({ speaker: line.speaker, text: line.text });
        if (line.event) emit("dialogueEvent", line.event);
        if (line.speaker && this.audio) this.audio.blip(line.speaker);
    }

    update(delta) {
        if (!this.active || !this.typing) return;
        this.shown = Math.min(this.full.length, this.shown + delta * CHARS_PER_SEC);
        this.textEl.textContent = this.full.slice(0, Math.floor(this.shown));
        if (this.shown >= this.full.length) this.typing = false;
    }

    advance() {
        if (!this.active) return;
        if (this.typing) {
            this.shown = this.full.length;
            this.textEl.textContent = this.full;
            this.typing = false;
            return;
        }
        this.next();
    }

    end() {
        const done = this.active.onComplete;
        this.active = null;
        this.box.classList.add("hidden");
        // Release on the next tick so the advancing key press can't also
        // trigger an interaction.
        setTimeout(() => {
            unlock("dialogue");
            done && done();
        }, 60);
    }
}
