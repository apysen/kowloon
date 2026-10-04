// Mei's silhouette through whatever hides her.
//
// Drawn after the opaque pass with depth testing off. Where the depth buffer
// holds something nearer the camera than Mei's anchor, a warm silhouette is
// drawn; where she is visible (the buffer holds her own anchor depth) it
// discards, so the silhouette never tints her.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

#include "res://assets/shaders/pixel_sprite.gdshaderinc"

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec4 silhouette_color : source_color = vec4(1.0, 0.69, 0.44, 0.45);

void vertex() {
	v_anchor_depth = anchor_depth(MODEL_MATRIX, VIEW_MATRIX, INV_VIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	vec4 c = texture(sheet, frame_uv(UV));
	float scene = texture(depth_texture, SCREEN_UV).r;
	// reverse-Z: larger depth values are nearer the camera
	if (c.a < 0.5 || room_fade < 0.001 || scene <= v_anchor_depth + 0.00002) {
		discard;
	}
	ALBEDO = silhouette_color.rgb;
	ALPHA = silhouette_color.a * fade * room_fade;
}
