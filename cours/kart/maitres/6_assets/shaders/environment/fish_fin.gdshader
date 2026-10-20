shader_type spatial;
render_mode cull_disabled;

// Nageoires (voir procedural_fish.gd) : UV.y = 0 à la base, 1 au bord.
// Opaques : sous l'eau, seuls les objets opaques apparaissent à travers la surface (screen_texture).

uniform vec4 fin_color : source_color = vec4(1.0, 0.18, 0.05, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_outline_color : source_color = vec4(0.05, 0.02, 0.02, 1.0);
// Début du liseré blanc (0..1 de la base au bord)
uniform float rim_start : hint_range(0.0, 1.0) = 0.72;
uniform float glow : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	// Rayons de la nageoire
	float rays = 0.85 + 0.15 * sin(UV.x * 70.0);
	vec3 color = fin_color.rgb * rays;
	color = mix(color, rim_outline_color.rgb, smoothstep(rim_start - 0.07, rim_start - 0.04, UV.y));
	color = mix(color, rim_color.rgb, smoothstep(rim_start - 0.01, rim_start + 0.02, UV.y));
	ALBEDO = color;
	EMISSION = color * glow;
	ROUGHNESS = 0.45;
	// Les nageoires sont fines : un peu de lumière les traverse
	BACKLIGHT = color * 0.5;
}
