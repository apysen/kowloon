// Shadow caster for a character card. Rendered only into shadow maps (the
// node sets cast_shadow = SHADOWS_ONLY) and turned toward the sun, so the
// shadow is a full silhouette instead of a sliver when the camera turns.
shader_type spatial;
render_mode cull_disabled, unshaded;

#include "res://assets/shaders/pixel_sprite.gdshaderinc"

void fragment() {
	vec4 c = texture(sheet, frame_uv(UV));
	float combined_fade = fade * room_fade;
	if (c.a < 0.5 || (combined_fade < 0.999 && bayer4(FRAGCOORD.xy) > combined_fade)) {
		discard;
	}
	ALBEDO = vec3(0.0);
}
