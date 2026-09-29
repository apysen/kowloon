// HD-2D character card: pixel art lit by the scene's lamps, sorted as one object.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled, depth_draw_opaque;

#include "res://assets/shaders/pixel_sprite.gdshaderinc"

// A little self-light keeps faces readable in dim rooms, as in the slice.
uniform float self_light = 0.3;
// Soft rim from behind, so figures separate from busy backgrounds.
uniform float rim_amount = 0.25;

void vertex() {
	v_anchor_depth = anchor_depth(MODEL_MATRIX, VIEW_MATRIX, INV_VIEW_MATRIX, PROJECTION_MATRIX);
	// cards always face the camera: light them as if they did
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec4 c = texture(sheet, frame_uv(UV));
	if (c.a < 0.5 || (fade < 0.999 && bayer4(FRAGCOORD.xy) > fade)) {
		discard;
	}
	ALBEDO = c.rgb * tint.rgb;
	EMISSION = c.rgb * tint.rgb * self_light;
	ROUGHNESS = 1.0;
	RIM = rim_amount;
	RIM_TINT = 0.6;
	BACKLIGHT = vec3(0.35);
	DEPTH = v_anchor_depth;
}
