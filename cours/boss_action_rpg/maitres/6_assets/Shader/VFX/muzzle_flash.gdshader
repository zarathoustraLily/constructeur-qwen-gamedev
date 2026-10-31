// Un éclair de bouche, repris de Binbun (Muzzle Flash VFX, CC0) : une forme dessinée (texture dont seul le rouge compte)
// sur un plan, le long du canon. L'alpha de la particule porte son âge (courbe `alpha_curve` du matériau de particules) :
// en vieillissant, l'éclair se ronge depuis sa base, comme s'il s'envolait, et pâlit. Le cœur de la forme est blanc-jaune,
// ses bords orangés. Mélange additif : il ajoute de la lumière, sans rien cacher et sans écrire de profondeur.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La forme de l'éclair, sa base à gauche de l'image.
uniform sampler2D shape : repeat_disable;
// Un bruit qui défile le long de l'éclair : il le déchire.
uniform sampler2D noise : repeat_enable;
// La vitesse du défilement.
uniform vec2 noise_scroll = vec2(0.0, 1.0);
// La part de l'éclair que le bruit retire.
uniform float noise_strength : hint_range(0.0, 1.0) = 0.5;
// La couleur du cœur de la forme.
uniform vec3 hot_color : source_color = vec3(1.0, 0.85, 0.55);
// La couleur de ses bords.
uniform vec3 edge_color : source_color = vec3(1.0, 0.38, 0.05);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 4.0;
// Combien l'âge ronge l'éclair depuis sa base.
uniform float base_erosion : hint_range(0.0, 1.0) = 1.0;
// Combien l'âge le pâlit partout.
uniform float age_fade : hint_range(0.0, 1.0) = 0.12;
// Le seuil sous lequel la forme passe de sa couleur de bord à celle du cœur.
uniform float color_softness : hint_range(0.01, 1.0) = 0.6;
// Le seuil sous lequel elle devient transparente.
uniform float edge_softness : hint_range(0.01, 1.0) = 0.4;

void fragment() {
	float age = COLOR.a;
	float value = texture(shape, vec2(1.0 - UV.y, UV.x)).r;
	// UV.y vaut 1 à la base de l'éclair.
	value = clamp(value - clamp(UV.y - 1.0 + age * base_erosion * 1.3, 0.0, 1.0), 0.0, 1.0);
	value = mix(value, value * (1.0 - age), age_fade);
	value *= 1.0 - (1.0 - texture(noise, UV + TIME * noise_scroll).r) * noise_strength;
	ALBEDO = mix(edge_color, hot_color, smoothstep(0.0, color_softness, value)) * intensity;
	ALPHA = smoothstep(0.0, edge_softness, value);
}
