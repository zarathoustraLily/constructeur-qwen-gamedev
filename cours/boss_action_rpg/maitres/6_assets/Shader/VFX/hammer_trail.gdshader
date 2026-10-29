// La traînée du marteau : une bande lumineuse entre le bout du marteau et un point vers son manche, faite des positions
// des dernières images. La couleur des sommets porte l'âge (alpha 1 : à l'instant, 0 : effacé) ; UV.y va du manche (0)
// au bout (1) : la bande s'efface vers ses deux bords. Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur de la traînée.
uniform vec4 trail_color : source_color = vec4(1.0, 0.8, 0.55, 1.0);
// Son éclat.
uniform float intensity : hint_range(0.0, 8.0) = 1.4;

void fragment() {
	float edge = sin(clamp(UV.y, 0.0, 1.0) * 3.14159) * (0.4 + 0.6 * UV.y);
	float glow = COLOR.a * COLOR.a * edge;
	ALBEDO = trail_color.rgb * intensity * glow;
	ALPHA = clamp(glow, 0.0, 1.0);
}
