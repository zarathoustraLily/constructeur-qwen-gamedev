shader_type spatial;
// Mer calme : un plan qui reste plat (la flottaison lit une eau plate, à hauteur 0), dont seules les normales
// ondulent. Trois trains de vagues sinusoïdales, dans trois directions, glissent avec le temps : leur pente
// donne la normale, et le reflet du ciel bouge comme sur de l'eau. De face, on voit le bleu profond ; de
// biais, la couleur du large, plus claire. Au loin, les ondulations s'effacent : elles scintilleraient.

uniform vec3 deep_color : source_color = vec3(0.04, 0.22, 0.42);
uniform vec3 far_color : source_color = vec3(0.16, 0.48, 0.62);
// Nombre de vagues par mètre.
uniform float ripple_frequency = 0.35;
// Vitesse des vagues (radians de phase par seconde).
uniform float ripple_speed = 1.2;
// Pente maximale d'une vague.
uniform float ripple_strength = 0.12;
// Distance (m) où les ondulations commencent à s'effacer, puis où elles ont disparu.
uniform vec2 ripple_fade = vec2(40.0, 160.0);
// Plus il est grand, plus la couleur du large reste près de l'horizon.
uniform float fresnel_power = 3.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Pente (d/dx, d/dz), en `p` (m) au temps `t`, de la vague sin(k · p − t) / |k| de direction `direction` :
// sa pente maximale vaut 1.
vec2 wave_slope(vec2 p, vec2 direction, float t) {
	vec2 k = normalize(direction) * ripple_frequency * TAU;
	return normalize(direction) * cos(dot(k, p) - t);
}

void fragment() {
	float t = TIME * ripple_speed;
	vec2 p = world_position.xz;
	vec2 slope = wave_slope(p, vec2(1.0, 0.3), t)
		+ wave_slope(p * 1.7, vec2(-0.5, 1.0), t * 1.3)
		+ wave_slope(p * 2.9, vec2(0.8, -0.6), t * 1.9);
	float fade = 1.0 - smoothstep(ripple_fade.x, ripple_fade.y, distance(world_position, CAMERA_POSITION_WORLD));
	slope *= ripple_strength * fade / 3.0;
	vec3 world_normal = normalize(vec3(-slope.x, 1.0, -slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	ALBEDO = mix(deep_color, far_color, fresnel);
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
}
