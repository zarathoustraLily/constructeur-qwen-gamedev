// Un éclair : un ruban dont UV.x traverse la largeur et UV.y suit la longueur, un fil blanc dans un halo bleu violet. La
// couleur des sommets porte son niveau (alpha 1 : à l'instant, 0 : éteint). Repris du cours du kart. Mélange additif : il
// ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur du fil.
uniform vec3 core_color : source_color = vec3(1.0, 1.0, 1.0);
// La couleur du halo.
uniform vec3 halo_color : source_color = vec3(0.25, 0.4, 1.0);
// La part de la largeur occupée par le fil.
uniform float core_width : hint_range(0.01, 1.0) = 0.12;
// Plus c'est grand, plus le halo est serré.
uniform float halo_falloff : hint_range(0.1, 8.0) = 2.2;
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 5.0;

void fragment() {
	float across = abs(UV.x * 2.0 - 1.0);
	float core = 1.0 - smoothstep(core_width * 0.5, core_width, across);
	float halo = pow(1.0 - across, halo_falloff);
	ALBEDO = (core_color * core + halo_color * halo) * intensity;
	ALPHA = clamp((core + halo) * COLOR.a, 0.0, 1.0);
}
