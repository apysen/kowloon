// One leaf of Mei's scrapbook turning about the spine: the cover opening and
// closing, and every page flip. The leaf is a rigid board hinged at the spine,
// seen in perspective from above, drawn into a rect centred on the spine that
// is larger than the spread (a lifted leaf looms toward the eye).
//
// angle 0: lying flat on the right. PI: lying flat on the left.
// The front face is what lies up on the right; the back face is what lies up
// once it has turned over onto the left.
shader_type canvas_item;

uniform sampler2D front_tex : filter_linear, repeat_disable;
uniform sampler2D back_tex : filter_linear, repeat_disable;
uniform float angle = 0.0;
uniform vec2 leaf_px = vec2(400.0, 540.0);   // the leaf's size on screen when flat
uniform vec2 rect_px = vec2(1200.0, 864.0);  // this rect's size (centred on the spine)
uniform float eye = 3.4;                     // eye height above the book, in leaf widths
uniform float shadow_strength = 0.38;

void fragment() {
	// this pixel, in leaf widths from the spine at mid-height
	vec2 p = (UV - 0.5) * rect_px / leaf_px.x;
	float aspect = leaf_px.y / leaf_px.x;
	float s = sin(angle);
	float c = cos(angle);
	// inverse perspective: which point u across the leaf lands here
	float den = eye * c + p.x * s;
	float u = abs(den) > 1e-4 ? p.x * eye / den : -1.0;
	float k = eye / max(eye - u * s, 0.05);
	float v = p.y / k / aspect + 0.5;
	vec4 col = vec4(0.0);
	if (u >= 0.0 && u <= 1.0 && v >= 0.0 && v <= 1.0) {
		bool front = c >= 0.0;
		vec3 rgb = front ? texture(front_tex, vec2(u, v)).rgb : texture(back_tex, vec2(1.0 - u, v)).rgb;
		// the leaf's face turns away from the light as it stands up; the lifted
		// edge catches a little light, the hinge side stays in its own shade
		float facing = abs(c);
		float light = mix(0.74, 1.0, facing);
		light *= mix(0.86, 1.0, smoothstep(0.0, 0.14, u));
		light += (1.0 - facing) * 0.06 * smoothstep(0.7, 1.0, u);
		col = vec4(rgb * light, 1.0);
	} else if (abs(p.y) <= aspect * 0.5 && s > 0.001) {
		// the lifted leaf's shadow on the page it is leaving or arriving at
		float reach = abs(c) * eye / max(eye - s, 0.05) + 0.35 * s;
		float side = c >= 0.0 ? 1.0 : -1.0;
		float d = p.x * side;
		if (d >= -0.01 && d <= reach) {
			float a = shadow_strength * s * (1.0 - smoothstep(0.0, reach, d));
			col = vec4(0.0, 0.0, 0.0, a);
		}
	}
	COLOR = col;
}
