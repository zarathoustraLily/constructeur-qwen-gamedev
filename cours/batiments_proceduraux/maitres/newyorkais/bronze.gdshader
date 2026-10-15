// Bronze : le métal des portes tambour, de l'entrée et de la marquise de la tour de brique.
// {STATUS}
//
// Le bronze à l'air libre brunit, puis verdit par endroits : une patine sombre, en taches. Là
// où les mains le touchent chaque jour, il ne prend pas de patine : il reste poli et doré. Le
// shader le sait par la hauteur : entre 0,85 m et 1,35 m du sol, sur les portes, le métal est
// usé. La même règle sert au cuivre d'une main courante, au laiton d'une poignée.
//
// Comme la brique, ce shader part de la position du pixel dans la tour, en mètres : aucune UV.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms colours;
/** La patine brune, la couleur du métal poli, et le vert-de-gris des taches. */
uniform vec3 patina_color : source_color = vec3(0.24, 0.17, 0.10);
uniform vec3 polished_color : source_color = vec3(0.80, 0.60, 0.33);
uniform vec3 verdigris_color : source_color = vec3(0.30, 0.42, 0.34);
/** Part de vert-de-gris. */
uniform float verdigris : hint_range(0.0, 1.0, 0.01) = 0.3;

group_uniforms wear_settings;
/** Hauteurs, au-dessus du sol, entre lesquelles les mains touchent le métal. */
uniform vec2 hand_height = vec2(0.85, 1.35);
/** Usure du métal à hauteur de main, de 0 (aucune) à 1 (poli comme neuf). */
uniform float wear : hint_range(0.0, 1.0, 0.01) = 0.85;

varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

void fragment() {
	// Coordonnées de face, en mètres, comme pour la brique.
	vec3 n = normalize(v_nrm);
	vec3 t;
	vec3 b;
	pc_face_frame(n, t, b);
	vec2 p = vec2(dot(v_pos, t), dot(v_pos, b));
	float fw = max(fwidth(p.x), fwidth(p.y));

	// La patine : des taches plus claires ou plus sombres, et du vert-de-gris par plaques.
	float blotch = pc_fbm2(p * 3.0, 4, fw * 3.0);
	vec3 col = pc_color_in(patina_color) * (0.8 + 0.6 * blotch);
	float green = smoothstep(0.62, 0.8, pc_fbm2(p * 1.3 + 7.0, 3, fw * 1.3)) * verdigris;
	col = mix(col, pc_color_in(verdigris_color), green);

	// L'usure : une bande à hauteur de main, frangée par un bruit fin. v_pos.y est la hauteur
	// au-dessus du sol de la tour.
	float hands = smoothstep(hand_height.x - 0.1, hand_height.x, v_pos.y) * (1.0 - smoothstep(hand_height.y, hand_height.y + 0.15, v_pos.y));
	hands *= wear * (0.6 + 0.4 * pc_noise2(p * 8.0));
	col = mix(col, pc_color_in(polished_color), hands);

	ALBEDO = pc_color_out(col);
	// Le métal poli brille ; la patine est mate.
	METALLIC = mix(0.55, 0.95, hands) * (1.0 - 0.6 * green);
	ROUGHNESS = mix(0.6, 0.18, hands);
}
