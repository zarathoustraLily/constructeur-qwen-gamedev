shader_type spatial;
render_mode cull_back;

// Corps du poisson (voir procedural_fish.gd) : UV.x = museau (0) -> queue (1), UV.y = tour du corps
// (0 = flanc droit, 0.25 = dos, 0.5 = flanc gauche, 0.75 = ventre).

uniform vec4 body_color : source_color = vec4(1.0, 0.08, 0.03, 1.0);
uniform vec4 back_color : source_color = vec4(0.8, 0.03, 0.02, 1.0);
uniform vec4 belly_color : source_color = vec4(1.0, 0.45, 0.3, 1.0);
uniform vec4 stripe_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.05, 0.02, 0.02, 1.0);
// Rayures blanches : position le long du corps et demi-largeur
uniform vec3 stripe_positions = vec3(0.22, 0.56, 0.9);
uniform vec3 stripe_half_widths = vec3(0.045, 0.06, 0.025);
uniform float outline_width = 0.012;
// Yeux (sur les flancs, au niveau de la première vertèbre)
uniform vec2 eye_right = vec2(0.108, 0.07);
uniform vec2 eye_left = vec2(0.108, 0.43);
uniform vec2 eye_radius = vec2(0.02, 0.032);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.3;
// Légère auto-illumination : garde le rouge lisible à travers l'eau, qui absorbe le rouge en premier
uniform float glow : hint_range(0.0, 1.0) = 0.7;

// 0 = corps, 1 = liseré noir, 2 = rayure blanche
float stripe(float u, float center, float half_width) {
	float d = abs(u - center);
	return d < half_width ? 2.0 : (d < half_width + outline_width ? 1.0 : 0.0);
}

void fragment() {
	float up = sin(UV.y * TAU);
	vec3 color = mix(belly_color.rgb, body_color.rgb, smoothstep(-0.8, 0.0, up));
	color = mix(color, back_color.rgb, smoothstep(0.3, 1.0, up) * 0.6);

	float s = max(max(stripe(UV.x, stripe_positions.x, stripe_half_widths.x),
		stripe(UV.x, stripe_positions.y, stripe_half_widths.y)),
		stripe(UV.x, stripe_positions.z, stripe_half_widths.z));
	if (s > 1.5) {
		color = stripe_color.rgb;
	} else if (s > 0.5) {
		color = outline_color.rgb;
	}

	// Yeux : blanc, pupille noire, petit reflet
	float eye = min(length((UV - eye_right) / eye_radius), length((UV - eye_left) / eye_radius));
	if (eye < 1.0) {
		color = eye < 0.55 ? vec3(0.02) : vec3(0.95);
	}

	ALBEDO = color;
	EMISSION = color * glow;
	ROUGHNESS = eye < 1.0 ? 0.1 : roughness_value;
	SPECULAR = 0.6;
}
