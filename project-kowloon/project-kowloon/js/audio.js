// Procedural ambience (sections 65-66). No audio files needed:
// everything is synthesized with WebAudio so the prototype runs anywhere.
// Important places are audible before they are visible:
//   Grandfather's radio -> home, dental drill -> Lau, wind + pigeons -> roof.

export class AudioSystem {
    constructor() {
        this.ctx = null;
        this.emitters = [];
        this.started = false;
        this.roofMix = 0;
    }

    start() {
        if (this.started) return;
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return;
        this.ctx = new AC();
        this.started = true;
        const ctx = this.ctx;

        this.master = ctx.createGain();
        this.master.gain.value = 0.8;
        const comp = ctx.createDynamicsCompressor();
        this.master.connect(comp).connect(ctx.destination);

        // shared noise buffer
        const len = ctx.sampleRate * 2;
        this.noise = ctx.createBuffer(1, len, ctx.sampleRate);
        const d = this.noise.getChannelData(0);
        let last = 0;
        this.brown = ctx.createBuffer(1, len, ctx.sampleRate);
        const b = this.brown.getChannelData(0);
        for (let i = 0; i < len; i++) {
            d[i] = Math.random() * 2 - 1;
            last = (last + 0.02 * d[i]) / 1.02;
            b[i] = last * 3.5;
        }

        this.buildBeds();
        this.buildEmitters();
    }

    loopNoise(buffer = this.noise) {
        const src = this.ctx.createBufferSource();
        src.buffer = buffer;
        src.loop = true;
        src.start();
        return src;
    }

    gain(v = 0) {
        const g = this.ctx.createGain();
        g.gain.value = v;
        return g;
    }

    filter(type, freq, q = 1) {
        const f = this.ctx.createBiquadFilter();
        f.type = type; f.frequency.value = freq; f.Q.value = q;
        return f;
    }

    buildBeds() {
        const ctx = this.ctx;
        // Interior: building hum, fans, pipes
        this.interior = this.gain(0);
        this.interior.connect(this.master);
        this.loopNoise(this.brown).connect(this.filter("lowpass", 260)).connect(this.gain(0.35)).connect(this.interior);
        const hum = ctx.createOscillator();
        hum.frequency.value = 50; hum.type = "sine"; hum.start();
        hum.connect(this.gain(0.035)).connect(this.interior);
        const hum2 = ctx.createOscillator();
        hum2.frequency.value = 100; hum2.type = "triangle"; hum2.start();
        hum2.connect(this.gain(0.012)).connect(this.interior);

        // Roof: wind with slow gusts + distant traffic
        this.roof = this.gain(0);
        this.roof.connect(this.master);
        const windF = this.filter("bandpass", 600, 0.6);
        const windG = this.gain(0.35);
        this.loopNoise().connect(windF).connect(windG).connect(this.roof);
        const lfo = ctx.createOscillator();
        lfo.frequency.value = 0.12;
        const lfoG = this.gain(0.2);
        lfo.connect(lfoG).connect(windG.gain);
        lfo.start();
        const lfo2 = ctx.createOscillator();
        lfo2.frequency.value = 0.07;
        const lfo2G = this.gain(250);
        lfo2.connect(lfo2G).connect(windF.frequency);
        lfo2.start();
        this.loopNoise(this.brown).connect(this.filter("lowpass", 180)).connect(this.gain(0.3)).connect(this.roof);
    }

    emitter(name, pos, radius, level) {
        const g = this.gain(0);
        g.connect(this.master);
        const e = { name, pos, radius, level, out: g, timer: Math.random(), vol: 0 };
        this.emitters.push(e);
        return e;
    }

    buildEmitters() {
        const ctx = this.ctx;

        // Grandfather's radio: a tinny pentatonic tune through a band-pass.
        const radio = this.emitter("radio", { x: -13.7, y: 0, z: -1.3 }, 16, 0);
        radio.bus = this.filter("bandpass", 1300, 0.9);
        radio.bus.connect(this.gain(1.2)).connect(radio.out);
        this.loopNoise().connect(this.filter("highpass", 3000)).connect(this.gain(0.02)).connect(radio.out);
        radio.notes = [392, 440, 523, 587, 659, 587, 523, 440, 392, 330, 392, 440];
        radio.step = 0;
        radio.every = 0.42;
        radio.play = () => {
            const f = radio.notes[radio.step++ % radio.notes.length];
            this.tone(f, 0.38, "triangle", 0.18, radio.bus);
            if (radio.step % 3 === 0) this.tone(f / 2, 0.6, "sine", 0.1, radio.bus);
        };

        // Lau's dental drill: bursts of a whining sawtooth.
        const drill = this.emitter("drill", { x: 5, y: 0, z: -12.5 }, 17, 0);
        const osc = ctx.createOscillator();
        osc.type = "sawtooth"; osc.frequency.value = 2100; osc.start();
        const vib = ctx.createOscillator();
        vib.frequency.value = 23; vib.start();
        vib.connect(this.gain(40)).connect(osc.frequency);
        drill.gate = this.gain(0);
        osc.connect(this.filter("bandpass", 2600, 2)).connect(drill.gate).connect(this.gain(0.16)).connect(drill.out);
        drill.every = 2.5;
        drill.play = () => {
            const t = ctx.currentTime;
            const dur = 0.4 + Math.random() * 1.4;
            drill.gate.gain.cancelScheduledValues(t);
            drill.gate.gain.setTargetAtTime(1, t, 0.03);
            drill.gate.gain.setTargetAtTime(0, t + dur, 0.05);
            drill.every = dur + 0.8 + Math.random() * 3;
        };

        // Mahjong tiles clacking
        const mj = this.emitter("mahjong", { x: -2, y: 0, z: 2.7 }, 10, 0);
        mj.every = 0.5;
        mj.play = () => {
            const n = 1 + Math.floor(Math.random() * 4);
            for (let i = 0; i < n; i++) this.click(mj.out, 2800 + Math.random() * 1500, 0.35, i * 0.07);
            mj.every = 0.3 + Math.random() * 1.6;
        };

        // Chopping vegetables
        const chop = this.emitter("chop", { x: -3.4, y: 0, z: 2.1 }, 9, 0);
        chop.every = 0.28;
        chop.play = () => {
            this.click(chop.out, 900, 0.5, 0, 0.03);
            chop.every = Math.random() < 0.15 ? 1.6 : 0.24;
        };

        // Water dripping in the airshaft and off the wet fabric
        const drip = this.emitter("drip", { x: -5, y: 5, z: -18.5 }, 8, 5);
        drip.every = 0.8;
        drip.play = () => { this.tone(1400 + Math.random() * 600, 0.08, "sine", 0.2, drip.out, 0.6); drip.every = 0.5 + Math.random() * 1.8; };
        const fdrip = this.emitter("fabricDrip", { x: 16, y: 5, z: -12 }, 7, 5);
        fdrip.every = 0.7;
        fdrip.enabled = () => !this.fabricMoved;
        fdrip.play = () => { this.tone(1700 + Math.random() * 500, 0.06, "sine", 0.18, fdrip.out, 0.5); fdrip.every = 0.3 + Math.random() * 1.0; };

        // Neighbours' TV through the wall (level B corridor)
        const tv = this.emitter("tv", { x: 3, y: 5, z: -12 }, 9, 5);
        tv.bus = this.filter("bandpass", 700, 1.5);
        tv.bus.connect(tv.out);
        tv.every = 0.2;
        tv.play = () => { this.tone(180 + Math.random() * 220, 0.18, "square", 0.05, tv.bus); tv.every = 0.12 + Math.random() * 0.3; };

        // Pigeons on the roof
        const coo = this.emitter("pigeons", { x: 3, y: 13, z: -22 }, 22, 13);
        coo.every = 1.2;
        coo.play = () => { this.coo(coo.out); coo.every = 0.8 + Math.random() * 2.2; };

        // Children somewhere below the roof
        const kids = this.emitter("kids", { x: -8, y: 13, z: -8 }, 30, 13);
        kids.every = 4;
        kids.play = () => {
            const base = 700 + Math.random() * 300;
            for (let i = 0; i < 3; i++) this.tone(base + i * 60, 0.12, "triangle", 0.03, kids.out, 0, i * 0.14);
            kids.every = 3 + Math.random() * 6;
        };
    }

    // ------------------------------------------------------------ primitives

    tone(freq, dur, type, vol, dest, glide = 0, delay = 0) {
        const ctx = this.ctx;
        const t = ctx.currentTime + delay;
        const o = ctx.createOscillator();
        o.type = type;
        o.frequency.setValueAtTime(freq, t);
        if (glide) o.frequency.exponentialRampToValueAtTime(freq * (1 - glide * 0.5), t + dur);
        const g = ctx.createGain();
        g.gain.setValueAtTime(0.0001, t);
        g.gain.exponentialRampToValueAtTime(vol, t + 0.01);
        g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
        o.connect(g).connect(dest);
        o.start(t);
        o.stop(t + dur + 0.05);
    }

    click(dest, freq, vol, delay = 0, dur = 0.02) {
        const ctx = this.ctx;
        const t = ctx.currentTime + delay;
        const src = ctx.createBufferSource();
        src.buffer = this.noise;
        const f = this.filter("bandpass", freq, 3);
        const g = ctx.createGain();
        g.gain.setValueAtTime(vol, t);
        g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
        src.connect(f).connect(g).connect(dest);
        src.start(t, Math.random());
        src.stop(t + dur + 0.02);
    }

    coo(dest, vol = 0.22) {
        const ctx = this.ctx;
        const t = ctx.currentTime;
        const o = ctx.createOscillator();
        o.type = "sine";
        const base = 260 + Math.random() * 60;
        o.frequency.setValueAtTime(base, t);
        o.frequency.linearRampToValueAtTime(base * 1.25, t + 0.15);
        o.frequency.linearRampToValueAtTime(base * 0.9, t + 0.5);
        const trem = ctx.createOscillator();
        trem.frequency.value = 28;
        const tg = ctx.createGain(); tg.gain.value = 0.5;
        const g = ctx.createGain();
        g.gain.setValueAtTime(0.0001, t);
        g.gain.linearRampToValueAtTime(vol, t + 0.08);
        g.gain.linearRampToValueAtTime(0.0001, t + 0.55);
        const am = ctx.createGain(); am.gain.value = 0.5;
        trem.connect(tg).connect(am.gain);
        o.connect(am).connect(g).connect(dest);
        o.start(t); trem.start(t);
        o.stop(t + 0.6); trem.stop(t + 0.6);
    }

    // ------------------------------------------------------------ one-shots

    shutter() {
        if (!this.ctx) return;
        this.click(this.master, 3000, 0.7, 0, 0.03);
        this.click(this.master, 1800, 0.5, 0.06, 0.05);
        // film motor whirr
        this.tone(160, 0.5, "sawtooth", 0.04, this.master, 0.1, 0.15);
    }

    chime() {
        if (!this.ctx) return;
        this.tone(660, 0.9, "sine", 0.08, this.master);
        this.tone(990, 1.1, "sine", 0.05, this.master, 0, 0.12);
    }

    footsteps(n = 8, interval = 0.16) {
        if (!this.ctx) return;
        for (let i = 0; i < n; i++) this.click(this.master, 350 + Math.random() * 120, 0.5, i * interval, 0.05);
    }

    creak() {
        if (!this.ctx) return;
        this.tone(140, 0.5, "sawtooth", 0.05, this.master, 0.4);
    }

    flutter() {
        if (!this.ctx) return;
        for (let i = 0; i < 14; i++) this.click(this.master, 1200 + Math.random() * 400, 0.25, i * 0.05, 0.03);
        setTimeout(() => this.coo(this.master, 0.3), 900);
    }

    blip(speaker) {
        if (!this.ctx) return;
        const base = { Mei: 620, Grandfather: 300, "Mr. Lau": 420, "Mrs. Chan": 520, "Chan's son": 700, "Mr. Ng": 340, "Mrs. Wong": 480 }[speaker] || 450;
        this.tone(base, 0.06, "sine", 0.04, this.master);
    }

    plane() {
        if (!this.ctx) return;
        const ctx = this.ctx;
        const t = ctx.currentTime;
        const src = this.loopNoise(this.brown);
        const f = this.filter("lowpass", 200);
        const g = this.gain(0.0001);
        src.connect(f).connect(g).connect(this.master);
        g.gain.exponentialRampToValueAtTime(1.3, t + 2.6);
        g.gain.exponentialRampToValueAtTime(0.0001, t + 7);
        f.frequency.linearRampToValueAtTime(700, t + 2.6);
        f.frequency.linearRampToValueAtTime(150, t + 7);
        const whine = ctx.createOscillator();
        whine.type = "sawtooth";
        whine.frequency.setValueAtTime(900, t);
        whine.frequency.linearRampToValueAtTime(760, t + 7);
        const wg = this.gain(0.0001);
        whine.connect(this.filter("bandpass", 900, 4)).connect(wg).connect(this.master);
        wg.gain.exponentialRampToValueAtTime(0.06, t + 2.6);
        wg.gain.exponentialRampToValueAtTime(0.0001, t + 7);
        whine.start(t);
        whine.stop(t + 7.2);
        src.stop(t + 7.2);
    }

    // Ending: everything drains away.
    silence(ms = 2500) {
        if (!this.ctx) return;
        const t = this.ctx.currentTime;
        this.master.gain.cancelScheduledValues(t);
        this.master.gain.setValueAtTime(this.master.gain.value, t);
        this.master.gain.linearRampToValueAtTime(0.0001, t + ms / 1000);
    }

    // ------------------------------------------------------------ per frame

    update(delta, playerPos, roofMix, muted = false) {
        if (!this.ctx) return;
        const t = this.ctx.currentTime;
        this.interior.gain.setTargetAtTime(muted ? 0 : 0.5 * (1 - roofMix), t, 0.3);
        this.roof.gain.setTargetAtTime(muted ? 0 : 0.55 * roofMix, t, 0.5);

        for (const e of this.emitters) {
            const dy = Math.abs(playerPos.y - e.pos.y);
            const levelFactor = dy < 3 ? 1 : dy < 9 ? 0.2 : 0.05;
            const d = Math.hypot(playerPos.x - e.pos.x, playerPos.z - e.pos.z);
            let v = Math.max(0, 1 - d / e.radius);
            v = v * v * levelFactor;
            if (e.enabled && !e.enabled()) v = 0;
            if (muted) v = 0;
            e.vol = v;
            e.out.gain.setTargetAtTime(v, t, 0.15);
            e.timer -= delta;
            if (e.timer <= 0) {
                if (v > 0.005 && e.play) e.play();
                e.timer = e.every;
            }
        }
    }
}
