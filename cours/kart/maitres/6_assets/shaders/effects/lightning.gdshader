shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Éclair et étincelles : ruban dont UV.x traverse la largeur (0..1) et UV.y suit la longueur.
// Cœur blanc très fin + halo coloré, en additif. Au-dessus de 1, le glow de l'environnement fait briller.
// COLOR.a = intensité (scintillement, ramifications plus faibles, fondu des étincelles).
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.15, 0.4, 1.0, 1.0);
// Largeur du cœur blanc (fraction de la largeur du ruban)
uniform float core_width : hint_range(0.01, 1.0) = 0.12;
uniform float glow_falloff = 1.8;
uniform float intensity = 4.0;
// Effiler les deux extrémités (étincelles)
uniform bool taper_ends = false;

void fragment() {
	float x = abs(UV.x * 2.0 - 1.0);
	float core = 1.0 - smoothstep(core_width * 0.5, core_width, x);
	float glow = pow(1.0 - x, glow_falloff);
	float along = taper_ends ? sin(UV.y * PI) : 1.0;
	float strength = COLOR.a * along;
	ALBEDO = (core_color.rgb * core + glow_color.rgb * glow) * intensity;
	ALPHA = clamp((core + glow) * strength, 0.0, 1.0);
}
