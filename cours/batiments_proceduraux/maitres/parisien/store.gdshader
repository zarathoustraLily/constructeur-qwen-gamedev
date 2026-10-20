// Toile de store : des rayures et un léger tissage.
// {STATUS}
//
// Le plus court des shaders du projet, et le même principe que les autres : une position,
// une grille, un bruit. Les rayures suivent l'axe X de l'immeuble, c'est-à-dire la longueur
// de la façade : elles descendent donc le long de la pente du store. Aucune UV n'est requise.
// La toile est vue des deux côtés (« cull_disabled ») : elle n'a pas d'épaisseur.
shader_type spatial;
render_mode cull_disabled;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

uniform vec3 fabric_color : source_color = vec3(0.50, 0.08, 0.07);
uniform vec3 stripe_color : source_color = vec3(0.90, 0.87, 0.78);
/** Largeur d'une rayure. 0 : toile unie. */
uniform float stripe_width : hint_range(0.0, 0.5, 0.005) = 0.12;
/** Décoloration par le soleil. */
uniform float fading : hint_range(0.0, 1.0, 0.01) = 0.25;

varying vec3 v_pos;

void vertex() {
	v_pos = VERTEX;
}

void fragment() {
	float fw = fwidth(v_pos.x);
	vec3 col = pc_color_in(fabric_color);
	if (stripe_width > 0.0) {
		// Onde triangulaire : une rayure sur deux.
		float wave = abs(fract(0.5 * v_pos.x / stripe_width) - 0.5) * 2.0;
		float stripe = pc_step(0.5, wave, fw / stripe_width);
		col = mix(col, pc_color_in(stripe_color), stripe);
	}
	float weave = pc_fbm2(v_pos.xz * 260.0, 2, 260.0 * max(fw, fwidth(v_pos.z)));
	float sun = pc_fbm2(v_pos.xz * 1.7 + 4.0, 3, 1.7 * fw);
	col = mix(col, vec3(pc_luma(col)) * 1.1, fading * (0.3 + 0.5 * sun));
	col *= 0.94 + 0.12 * weave;
	ALBEDO = pc_color_out(col);
	ROUGHNESS = 0.9;
	SPECULAR = 0.3;
}
