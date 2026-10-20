shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Ruban de traînée (voir wheel_trail.gd) : COLOR.r = âge (0..1), COLOR.a = opacité, UV.x = travers du ruban.
uniform vec4 trail_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D noise_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
// Taille du motif de bruit (fixé dans le monde : l'écume ne glisse pas avec le kart)
uniform float noise_scale = 0.4;
// Largeur du fondu sur les bords du ruban
uniform float edge_softness : hint_range(0.01, 1.0) = 0.45;
// À quel point le bruit « ronge » la traînée en vieillissant
uniform float breakup : hint_range(0.0, 1.0) = 0.65;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.7;
uniform float specular_value : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float age = COLOR.r;
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float edge = smoothstep(0.0, edge_softness, across);
	float n = 0.5 * (texture(noise_texture, world_position.xz * noise_scale).r
		+ texture(noise_texture, world_position.xz * noise_scale * 2.3 + vec2(0.37, 0.71)).r);
	float threshold = breakup * age;
	float mask = smoothstep(threshold, threshold + 0.3, n * edge + 0.15 * (1.0 - age));

	ALBEDO = trail_color.rgb;
	ALPHA = clamp(trail_color.a * COLOR.a * mask, 0.0, 1.0);
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
}
