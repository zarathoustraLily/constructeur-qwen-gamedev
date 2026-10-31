// L'étoile d'un impact, reprise de Binbun (Hit FX, CC0) : un anneau de pointes qui s'ouvre du centre vers le bord, tracé
// par le calcul, sans texture. L'alpha de la particule porte son âge (courbe `alpha_curve` du matériau de particules) ;
// la couleur de la particule teinte l'étoile. Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur du cœur.
uniform vec3 hot_color : source_color = vec3(1.0);
// La couleur des bords.
uniform vec3 edge_color : source_color = vec3(1.0, 0.65, 0.3);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 6.0;
// Le nombre de pointes.
uniform float points : hint_range(1.0, 24.0, 1.0) = 9.0;
// La dureté du bord : 0, un dégradé ; 1, un trait net.
uniform float edge_hardness : hint_range(0.0, 1.0) = 0.5;
// La valeur où tombe le bord.
uniform float edge_position : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float radius = length(centered);
	float angle = atan(centered.x, centered.y);
	float front = COLOR.a * 4.0 - 1.0;
	radius += abs(sin(angle * points * 0.5 + TIME)) * radius * 0.5;
	float value = 1.0 - abs(radius * 2.0 - front);
	value *= pow(max(1.0 - radius, 0.0), 0.1);
	value = smoothstep(mix(0.0, edge_position, edge_hardness), mix(1.0, edge_position + 0.01, edge_hardness), value);
	ALBEDO = mix(edge_color, hot_color, value) * COLOR.rgb * intensity;
	ALPHA = value;
}
