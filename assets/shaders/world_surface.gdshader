// Opaque world surface. See world_surface.gdshaderinc.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://assets/shaders/world_surface.gdshaderinc"

void fragment() {
	vec3 a; vec3 n; float r; vec3 e;
	surface_fragment(a, n, r, e, VIEW_MATRIX);
	ALBEDO = a;
	NORMAL = n;
	ROUGHNESS = r;
	SPECULAR = 0.35;
	EMISSION = e;
}
