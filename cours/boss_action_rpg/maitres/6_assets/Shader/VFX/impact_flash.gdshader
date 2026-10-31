// Les flammèches d'un impact, reprises de Binbun (Hit FX, CC0) : des plans lancés depuis le point touché, alignés sur leur
// vitesse, où une vague déchirée par un bruit court de la pointe à la base. L'alpha de la particule porte son âge
// (courbe `alpha_curve` du matériau de particules) ; sa couleur les teinte. Le numéro d'instance décale le bruit : aucune
// flammèche n'est pareille. Mélange additif : elles ajoutent de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur du cœur.
uniform vec3 hot_color : source_color = vec3(1.0);
// La couleur des bords.
uniform vec3 edge_color : source_color = vec3(1.0, 0.6, 0.2);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 3.0;
// Combien la flammèche s'affine vers sa pointe.
uniform float pinch : hint_range(0.0, 1.0) = 0.4;
// Le bruit qui la déchire.
uniform sampler2D noise : repeat_enable;
// L'échelle du bruit.
uniform vec2 noise_scale = vec2(0.8, 0.2);
// La dureté du bord : 0, un dégradé ; 1, un trait net.
uniform float edge_hardness : hint_range(0.0, 1.0) = 0.5;

varying flat int flame;

void vertex() {
	flame = INSTANCE_ID;
}

void fragment() {
	float age = COLOR.a;
	vec2 scaled = (vec2(1.0) - UV - vec2(0.5, 0.0)) * vec2(2.0, 1.0);
	float gradient = pow(1.0 - UV.y, 0.5) * 2.0;
	float r = length(scaled) / ((1.0 - pinch) + gradient * pinch);
	float n = texture(noise, (UV + vec2(0.0, age) + float(flame) / 3.14159) * noise_scale).r;
	float form = (r - n * 0.5) * 2.0;
	float value = 1.0 - abs(form * 2.0 - (age * 4.0 - 1.0));
	value *= clamp(1.0 - form * form * form, 0.0, 1.0) * gradient;
	value *= pow(max(age, 0.0), 0.1) * min(UV.y * 8.0, 1.0);
	value = smoothstep(mix(0.0, 0.19, edge_hardness), mix(1.0, 0.2, edge_hardness), value);
	ALBEDO = mix(edge_color, hot_color, value) * COLOR.rgb * intensity;
	ALPHA = value;
}
