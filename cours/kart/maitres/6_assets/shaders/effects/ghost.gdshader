shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

// Image fantôme (GhostTrail) : contour lumineux (fresnel) et cœur presque transparent.
// Couleur et opacité propres à chaque fantôme, sans dupliquer le matériau.
instance uniform vec4 ghost_color : source_color = vec4(1.0, 0.3, 0.9, 1.0);
instance uniform float ghost_fade = 1.0;

uniform float fresnel_power = 2.2;
uniform float core_opacity : hint_range(0.0, 1.0) = 0.1;
uniform float edge_opacity : hint_range(0.0, 1.0) = 0.7;
// Au-dessus de 1, le halo (glow) de l'environnement fait briller le contour
uniform float edge_brightness = 2.5;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), fresnel_power);
	ALBEDO = ghost_color.rgb * mix(1.0, edge_brightness, fresnel);
	ALPHA = clamp(mix(core_opacity, edge_opacity, fresnel) * ghost_fade, 0.0, 1.0);
}
