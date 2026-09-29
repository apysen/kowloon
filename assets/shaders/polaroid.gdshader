// The instant photo developing: it starts as a pale, milky sepia ghost and
// resolves over a few seconds, finished with a warm cast, soft vignette and
// film grain so the in-game shot reads as a 1992 instant print.
shader_type canvas_item;

uniform float develop : hint_range(0.0, 1.0) = 1.0;
uniform vec4 cast_color : source_color = vec4(1.0, 0.86, 0.66, 1.0);
uniform float cast_amount = 0.18;
uniform float seed = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// instant-film response: lifted blacks, soft highlights, warm cast
	vec3 film = mix(c, c * cast_color.rgb, cast_amount);
	film = film * 0.92 + 0.05;
	film = mix(vec3(l), film, 0.85);
	vec2 q = UV - 0.5;
	film *= 1.0 - 0.35 * smoothstep(0.3, 0.75, length(q));
	film += (hash(UV * 900.0 + seed) - 0.5) * 0.05;
	// undeveloped: bright, low contrast, sepia, desaturated
	vec3 ghost = vec3(0.86, 0.82, 0.72) + (film - 0.5) * 0.12;
	vec3 outc = mix(ghost, film, smoothstep(0.0, 1.0, develop));
	COLOR = vec4(outc, 1.0);
}
