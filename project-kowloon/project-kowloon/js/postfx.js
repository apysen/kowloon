import * as THREE from "three";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { ShaderPass } from "three/addons/postprocessing/ShaderPass.js";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";

// The HD-2D "diorama" look: tilt-shift depth of field (the top and bottom
// of the screen go soft, like a miniature), bloom on lamps, neon and lit
// windows, then a film grade: warm highlights, cool shadows, vignette, grain.

const TiltShift = {
    uniforms: {
        tDiffuse: { value: null },
        dir: { value: new THREE.Vector2(1, 0) },
        focus: { value: 0.47 },
        range: { value: 0.15 },
        amount: { value: 3.2 }
    },
    vertexShader: /* glsl */`
        varying vec2 vUv;
        void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: /* glsl */`
        uniform sampler2D tDiffuse;
        uniform vec2 dir;
        uniform float focus, range, amount;
        varying vec2 vUv;
        void main() {
            float d = abs(vUv.y - focus);
            float b = smoothstep(range, range + 0.32, d) * amount;
            vec4 sum = vec4(0.0);
            float wsum = 0.0;
            for (int i = -5; i <= 5; i++) {
                float w = exp(-float(i * i) / 10.0);
                sum += texture2D(tDiffuse, vUv + dir * float(i) * b) * w;
                wsum += w;
            }
            gl_FragColor = sum / wsum;
        }`
};

const Grade = {
    uniforms: {
        tDiffuse: { value: null },
        time: { value: 0 },
        vignette: { value: 0.42 },
        grain: { value: 0.045 },
        warmth: { value: 1.0 },
        resolution: { value: new THREE.Vector2(1, 1) }
    },
    vertexShader: TiltShift.vertexShader,
    fragmentShader: /* glsl */`
        uniform sampler2D tDiffuse;
        uniform float time, vignette, grain, warmth;
        uniform vec2 resolution;
        varying vec2 vUv;
        float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
        void main() {
            vec3 c = texture2D(tDiffuse, vUv).rgb;
            float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
            // split tone: teal in the shadows, amber in the highlights
            vec3 shadowTint = vec3(0.90, 1.00, 1.06);
            vec3 highTint = mix(vec3(1.0), vec3(1.07, 1.01, 0.90), warmth);
            c *= mix(shadowTint, highTint, smoothstep(0.15, 0.75, l));
            // gentle S-curve and a touch more saturation
            c = mix(c, c * c * (3.0 - 2.0 * c), 0.35);
            c = mix(vec3(l), c, 1.12);
            // vignette
            vec2 q = vUv - 0.5;
            q.x *= resolution.x / resolution.y;
            c *= 1.0 - vignette * smoothstep(0.35, 1.05, length(q));
            // film grain
            c += (hash(vUv * resolution + time) - 0.5) * grain;
            gl_FragColor = vec4(c, 1.0);
        }`
};

export class PostFX {
    constructor(renderer, scene, camera) {
        this.renderer = renderer;
        this.composer = new EffectComposer(renderer);
        this.renderPass = new RenderPass(scene, camera);
        this.composer.addPass(this.renderPass);

        this.bloom = new UnrealBloomPass(new THREE.Vector2(256, 256), 0.55, 0.55, 0.86);
        this.composer.addPass(this.bloom);

        this.tiltH = new ShaderPass(TiltShift);
        this.tiltV = new ShaderPass(TiltShift);
        this.composer.addPass(this.tiltH);
        this.composer.addPass(this.tiltV);

        this.composer.addPass(new OutputPass());
        this.grade = new ShaderPass(Grade);
        this.composer.addPass(this.grade);

        this.setQuality("high");
        this.setSize(window.innerWidth, window.innerHeight);
    }

    setQuality(q) {
        this.quality = q;
        const high = q === "high";
        this.bloom.enabled = high;
        this.tiltH.enabled = this.tiltV.enabled = high;
        this.renderer.shadowMap.enabled = high;
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, high ? 1.5 : 1));
        this.setSize(window.innerWidth, window.innerHeight);
    }

    setSize(w, h) {
        this.renderer.setSize(w, h);
        this.composer.setPixelRatio(this.renderer.getPixelRatio());
        this.composer.setSize(w, h);
        const pr = this.renderer.getPixelRatio();
        this.tiltH.uniforms.dir.value.set(1 / (w * pr), 0);
        this.tiltV.uniforms.dir.value.set(0, 1 / (h * pr));
        this.grade.uniforms.resolution.value.set(w * pr, h * pr);
    }

    // roofMix 0 = interior (warmer, heavier vignette), 1 = rooftop daylight
    update(time, roofMix) {
        this.grade.uniforms.time.value = time % 100;
        this.grade.uniforms.vignette.value = 0.48 - 0.16 * roofMix;
        this.grade.uniforms.warmth.value = 1.0 - 0.4 * roofMix;
        this.bloom.strength = 0.6 - 0.25 * roofMix;
        this.tiltH.uniforms.range.value = this.tiltV.uniforms.range.value = 0.15 + 0.05 * roofMix;
    }

    render() {
        this.composer.render();
    }
}
