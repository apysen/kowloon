// Shared body of the world surface shaders (opaque and fading variants).
//
// Surfaces are mapped triplanar in world space, so a texel is the same size
// on every wall, floor and building no matter how the level was built: the
// HD-2D rule that detail density never changes across the diorama. Side
// faces use the side maps; upward faces can use a second set (tar on roofs,
// floors under walls). Every piece is tinted per instance, the way the
// Three.js slice tinted its canvas textures by object colour, so one material
// per surface covers the whole city.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D emission_tex : source_color, hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_emission = false;
uniform float emission_energy = 1.6;

uniform bool has_top = false;
uniform sampler2D top_albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D top_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D top_rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 top_tint : source_color = vec4(1.0);
uniform float top_tile = 2.0;

uniform vec2 tile_size = vec2(2.0, 2.0);   // metres per repeat (horizontal, vertical)
uniform float normal_strength = 1.0;
uniform float roughness_scale = 1.0;
uniform float blend_sharpness = 6.0;

// Contact darkening toward the foot of a wall: dust, scuffs and bounce shadow.
uniform float foot_grime = 0.18;

instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform vec2 uv_offset = vec2(0.0);
instance uniform float fade = 1.0;
instance uniform float emission_scale = 1.0;
instance uniform float base_y = -1000.0;   // world y of the floor this piece stands on

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 unpack_normal(vec4 t) {
	vec3 n = t.xyz * 2.0 - 1.0;
	n.xy *= normal_strength;
	return n;
}

void surface_fragment(out vec3 o_albedo, out vec3 o_normal_view, out float o_rough, out vec3 o_emission, mat4 view_matrix) {
	vec3 n = normalize(w_nrm);
	vec3 w = pow(abs(n), vec3(blend_sharpness));
	w /= (w.x + w.y + w.z);

	vec2 off = uv_offset;
	// side projections: u along the wall, v down the wall (image rows run downward)
	vec2 uv_x = vec2(w_pos.z * sign(n.x), -w_pos.y) / tile_size + off;
	vec2 uv_z = vec2(-w_pos.x * sign(n.z), -w_pos.y) / tile_size + off;
	vec2 uv_y = w_pos.xz / (has_top ? vec2(top_tile) : tile_size.xx) + off;

	vec3 ax = texture(albedo_tex, uv_x).rgb;
	vec3 az = texture(albedo_tex, uv_z).rgb;
	vec3 ay;
	float ry;
	vec3 ny;
	if (has_top) {
		ay = texture(top_albedo_tex, uv_y).rgb * top_tint.rgb;
		ry = texture(top_rough_tex, uv_y).r;
		ny = unpack_normal(texture(top_normal_tex, uv_y));
	} else {
		ay = texture(albedo_tex, uv_y).rgb;
		ry = texture(rough_tex, uv_y).r;
		ny = unpack_normal(texture(normal_tex, uv_y));
	}
	vec3 side_tint = tint.rgb;
	vec3 albedo = (ax * w.x + az * w.z) * side_tint + ay * w.y * (has_top ? vec3(1.0) : side_tint);

	float rough = texture(rough_tex, uv_x).r * w.x + texture(rough_tex, uv_z).r * w.z + ry * w.y;

	// whiteout-blended triplanar normals (tangent y is world up on side faces)
	vec3 nx = unpack_normal(texture(normal_tex, uv_x));
	vec3 nz = unpack_normal(texture(normal_tex, uv_z));
	nx = vec3(nx.x * sign(n.x), nx.y, nx.z);
	nz = vec3(nz.x * -sign(n.z), nz.y, nz.z);
	vec3 wx = vec3(abs(nx.z) * n.x, nx.y + n.y, nx.x + n.z);
	vec3 wy = vec3(ny.x + n.x, abs(ny.z) * n.y, -ny.y + n.z);
	vec3 wz = vec3(nz.x + n.x, nz.y + n.y, abs(nz.z) * n.z);
	vec3 wn = normalize(wx * w.x + wy * w.y + wz * w.z);

	if (base_y > -999.0) {
		float h = w_pos.y - base_y;
		float g = (1.0 - smoothstep(0.0, 0.55, h)) * (1.0 - w.y);
		albedo *= 1.0 - foot_grime * g;
	}

	vec3 emission = vec3(0.0);
	if (has_emission) {
		vec3 ex = texture(emission_tex, uv_x).rgb;
		vec3 ez = texture(emission_tex, uv_z).rgb;
		emission = (ex * w.x + ez * w.z) * emission_energy * emission_scale;
	}

	o_albedo = albedo;
	o_normal_view = normalize((view_matrix * vec4(wn, 0.0)).xyz);
	o_rough = clamp(rough * roughness_scale, 0.04, 1.0);
	o_emission = emission;
}
