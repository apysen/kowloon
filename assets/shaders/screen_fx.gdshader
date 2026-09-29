// The diorama finish, drawn over the 3D view before the interface:
// tilt-shift (the top and bottom of the frame go soft, like a miniature),
// then a film grade: amber highlights, teal shadows, a gentle S-curve, a
// vignette and grain. Bloom comes from the environment's glow beforehand.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform bool tilt_shift = true;
uniform float focus = 0.52;        // screen height (0 top .. 1 bottom) that stays sharp
uniform float range = 0.2;        // half-height of the sharp band
uniform float amount = 2.6;        // blur radius in mip levels at the edges
uniform float vignette = 0.46;
uniform float grain = 0.04;
uniform float warmth = 1.0;
uniform float saturation = 1.1;
uniform float time = 0.0;
uniform float fade_black = 0.0;    // not used for fades (the interface has its own); kept for stills

const vec2 POISSON[12] = vec2[](
	vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457), vec2(-0.203, 0.621),
	vec2(0.962, -0.195), vec2(0.473, -0.480), vec2(0.519, 0.767), vec2(0.185, -0.893),
	vec2(0.507, 0.064), vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598));

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	if (tilt_shift) {
		// the blur starts faint just outside the sharp band and builds gradually
		// toward the top and bottom edges, like a real tilt-shift lens
		float d = abs(uv.y - focus);
		float b = pow(smoothstep(range, 0.55, d), 1.8);
		if (b > 0.001) {
			float lod = b * amount;
			vec2 px = SCREEN_PIXEL_SIZE * exp2(lod) * 1.4;
			vec3 sum = textureLod(screen_tex, uv, lod).rgb;
			for (int i = 0; i < 12; i++) {
				sum += textureLod(screen_tex, uv + POISSON[i] * px, lod).rgb;
			}
			c = mix(c, sum / 13.0, smoothstep(0.0, 0.6, b));
		}
	}
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 shadow_tint = vec3(0.92, 1.0, 1.05);
	vec3 high_tint = mix(vec3(1.0), vec3(1.06, 1.01, 0.91), warmth);
	c *= mix(shadow_tint, high_tint, smoothstep(0.12, 0.75, l));
	c = mix(c, c * c * (3.0 - 2.0 * c), 0.3);
	c = mix(vec3(l), c, saturation);
	vec2 q = uv - 0.5;
	q.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	c *= 1.0 - vignette * smoothstep(0.35, 1.05, length(q));
	c += (hash(uv / SCREEN_PIXEL_SIZE + fract(time) * 91.7) - 0.5) * grain;
	c = mix(c, vec3(0.0), fade_black);
	COLOR = vec4(c, 1.0);
}
