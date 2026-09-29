// Two skies in one. Inside the City there is no sky, only a warm, sooty dark
// (the corridor's background). On the roof it opens into late afternoon over
// Kowloon: the painted panorama, golden toward the sun. `roof_mix` blends
// between them as Mei climbs out.
shader_type sky;

uniform sampler2D panorama : source_color, filter_linear_mipmap;
uniform vec4 interior_color : source_color = vec4(0.125, 0.11, 0.1, 1.0);
uniform float roof_mix : hint_range(0.0, 1.0) = 0.0;
uniform float exposure = 1.0;

void sky() {
	vec3 d = EYEDIR;
	vec2 uv = vec2(atan(d.x, -d.z) / (2.0 * PI) + 0.5, acos(clamp(d.y, -1.0, 1.0)) / PI);
	vec3 pano = texture(panorama, uv).rgb * exposure;
	COLOR = mix(interior_color.rgb, pano, roof_mix);
}
