// Shared pieces of the pixel sprite shaders: frame lookup and the anchor depth.
//
// The anchor depth is what keeps sprites from clipping into the world. A
// billboard is a flat card; left to the depth buffer, any wall or table that
// crosses the card cuts a slice out of the character. Instead every fragment
// of the card writes the depth of a single anchor point (mid-body, nudged a
// little toward the camera), so the whole character sorts as one object:
// fully in front of a wall, or fully behind it, never through it.

uniform sampler2D sheet : source_color, filter_nearest, repeat_disable;
uniform vec2 sheet_grid = vec2(6.0, 18.0);        // columns, rows
uniform float anchor_height = 0.8;                // metres above the feet
uniform float anchor_toward_camera = 0.35;        // metres

instance uniform vec2 frame = vec2(0.0);          // column, row
instance uniform float flip = 0.0;                // 1 = mirror horizontally
instance uniform float fade = 1.0;                // dithered fade (doorways)
instance uniform float room_fade = 1.0;           // synchronized with the room shell
instance uniform vec4 tint : source_color = vec4(1.0);

varying float v_anchor_depth;

vec2 frame_uv(vec2 uv) {
	vec2 u = uv;
	if (flip > 0.5) u.x = 1.0 - u.x;
	// half-texel inset stops neighbouring frames bleeding in at the card edge
	vec2 texel = 1.0 / vec2(textureSize(sheet, 0));
	vec2 cell = 1.0 / sheet_grid;
	vec2 base = frame * cell;
	return base + clamp(u * cell, texel * 0.5, cell - texel * 0.5);
}

float anchor_depth(mat4 model, mat4 view, mat4 inv_view, mat4 proj) {
	vec3 anchor = (model * vec4(0.0, anchor_height, 0.0, 1.0)).xyz;
	vec3 back = inv_view[2].xyz;
	vec3 flat_back = normalize(vec3(back.x, 0.0, back.z) + vec3(1e-5));
	anchor += flat_back * anchor_toward_camera;
	vec4 clip = proj * view * vec4(anchor, 1.0);
	return clip.z / clip.w;
}

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int idx = i.x + i.y * 4;
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[idx]) + 0.5) / 16.0;
}
