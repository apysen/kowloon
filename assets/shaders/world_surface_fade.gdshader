// A world surface that is fading out because it stands between Mei and the
// camera. The world swaps a piece onto this variant only while it is fading,
// so everything else stays in the cheaper opaque pass. Lit windows fade with
// the square of the opacity so they never float in mid-air.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://assets/shaders/world_surface.gdshaderinc"

void fragment() {
	vec3 a; vec3 n; float r; vec3 e;
	surface_fragment(a, n, r, e, VIEW_MATRIX);
	ALBEDO = a;
	NORMAL = n;
	ROUGHNESS = r;
	SPECULAR = 0.35;
	EMISSION = e * fade * fade;
	ALPHA = fade;
}
