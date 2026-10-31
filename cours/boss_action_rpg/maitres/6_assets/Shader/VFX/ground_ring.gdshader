// La marque d'un éclair au sol : un cercle fixe, à la limite de la zone de coup, et un second cercle qui se referme vers
// le centre à mesure que le coup approche ; le fond se remplit de lumière. `progress` va de 0 (l'annonce) à 1 (le coup).
// Le plan est posé juste au-dessus du sol. Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur de la marque.
uniform vec3 ring_color : source_color = vec3(0.45, 0.6, 1.0);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 20.0) = 3.0;
// L'avancée de l'annonce, de 0 à 1.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// L'épaisseur des cercles, en part du rayon.
uniform float thickness : hint_range(0.005, 0.3) = 0.05;

void fragment() {
	float radius = length(UV * 2.0 - 1.0);
	float rim = 1.0 - smoothstep(0.0, thickness, abs(radius - (1.0 - thickness)));
	float closing = 1.0 - smoothstep(0.0, thickness, abs(radius - (1.0 - progress) * (1.0 - thickness)));
	float fill = (1.0 - smoothstep(0.7, 1.0, radius)) * 0.14 * progress;
	float light = rim * (0.5 + 0.5 * progress) + closing + fill;
	ALBEDO = ring_color * intensity;
	ALPHA = clamp(light, 0.0, 1.0);
}
