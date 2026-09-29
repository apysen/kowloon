import { GameState, lock, unlock } from "./gameState.js";
import { Residents } from "./data/residents.js";

// Scrapbook (sections 41-42). No completion percentages, no empty slots:
// only the people Mei has actually photographed.

export class ScrapbookManager {
    constructor(photography) {
        this.photography = photography;
        this.el = document.getElementById("scrapbook");
        this.open = false;
        this.el.addEventListener("click", e => {
            if (e.target.closest("[data-close]")) this.toggle(false);
        });
    }

    unlock(id) {
        if (!GameState.scrapbook.includes(id)) GameState.scrapbook.push(id);
    }

    async render() {
        const entries = await Promise.all(GameState.scrapbook.map(async (id, i) => {
            const r = Residents[id];
            const src = await this.photography.photoFor(id);
            const tilt = i % 2 ? 2.2 : -1.8;
            return `
            <article class="entry" style="--tilt:${tilt}deg">
                <div class="entry-photo">
                    <span class="tape"></span>
                    <img src="${src}" alt="Photograph of ${r.name}">
                </div>
                <div class="entry-text">
                    <h3>${r.name}</h3>
                    <p class="entry-meta">${r.occupation}<br>${r.location}</p>
                    <p class="entry-note">${r.note}</p>
                    <p class="entry-context">${r.context}</p>
                </div>
            </article>`;
        }));

        this.el.innerHTML = `
            <div class="scrapbook-page">
                <header class="scrapbook-head">
                    <span class="scrapbook-title">Project Kowloon</span>
                    <button class="scrapbook-close" data-close aria-label="Close scrapbook"><kbd>TAB</kbd> close</button>
                </header>
                ${entries.length
                    ? `<div class="entries">${entries.join("")}</div>`
                    : `<p class="scrapbook-empty">Empty pages. Grandfather's camera is still full of film.</p>`}
            </div>`;
    }

    async toggle(force) {
        const next = force ?? !this.open;
        if (next === this.open) return;
        if (next && GameState.controlsLocked) return;
        this.open = next;
        if (next) {
            lock("scrapbook");
            await this.render();
            this.el.classList.remove("hidden");
        } else {
            this.el.classList.add("hidden");
            unlock("scrapbook");
        }
    }
}
