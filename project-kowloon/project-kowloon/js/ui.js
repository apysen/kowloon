// HUD helpers: objective, interaction prompt, tutorial hints, fades (sections 33, 35).

const $ = id => document.getElementById(id);

export const UI = {
    objectiveEl: null,
    promptEl: null,
    fadeEl: null,
    hintEl: null,
    quiet: false,

    init() {
        this.objectiveEl = $("objective");
        this.promptEl = $("interaction-prompt");
        this.fadeEl = $("fade-screen");
        this.hintEl = $("tutorial-hint");
        this.noticeEl = $("notice");
    },

    setObjective(objective, hint) {
        const el = this.objectiveEl;
        el.classList.add("changing");
        setTimeout(() => {
            el.innerHTML = objective
                ? `<div class="obj-main">${objective}</div>${hint ? `<div class="obj-hint">${hint}</div>` : ""}`
                : "";
            el.classList.remove("changing");
        }, 250);
    },

    setQuiet(quiet) {
        this.quiet = quiet;
        document.getElementById("hud").classList.toggle("quiet", quiet);
    },

    showPrompt(text) {
        if (!text) { this.promptEl.classList.remove("visible"); return; }
        if (this.promptEl.dataset.text !== text) {
            this.promptEl.dataset.text = text;
            this.promptEl.innerHTML = text.replace(/\[(.+?)\]/g, '<kbd>$1</kbd>');
        }
        this.promptEl.classList.add("visible");
    },

    // Short tutorial hints that disappear for good once used.
    showHint(text) {
        if (!text) { this.hintEl.classList.remove("visible"); return; }
        if (this.hintEl.dataset.text !== text) {
            this.hintEl.dataset.text = text;
            this.hintEl.innerHTML = text.replace(/\[(.+?)\]/g, '<kbd>$1</kbd>');
        }
        this.hintEl.classList.add("visible");
    },

    notice(text, ms = 2600) {
        const el = this.noticeEl;
        el.textContent = text;
        el.classList.add("visible");
        clearTimeout(this._noticeT);
        this._noticeT = setTimeout(() => el.classList.remove("visible"), ms);
    },

    fadeOut(ms = 500) {
        this.fadeEl.style.transitionDuration = ms + "ms";
        this.fadeEl.classList.add("black");
        return new Promise(r => setTimeout(r, ms));
    },

    fadeIn(ms = 500) {
        this.fadeEl.style.transitionDuration = ms + "ms";
        this.fadeEl.classList.remove("black");
        return new Promise(r => setTimeout(r, ms));
    },

    flash() {
        const f = $("flash");
        f.classList.remove("go");
        void f.offsetWidth;
        f.classList.add("go");
    }
};

export const wait = ms => new Promise(r => setTimeout(r, ms));
