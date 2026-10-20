// Enseigne : un simple rectangle devient un caisson lumineux, un panneau peint ou la façade
// d'un distributeur de boissons.
// {STATUS}
//
// Ce que le shader dessine :
//   - le fond, de la teinte que le script a donnée à l'instance, dans un cadre de métal ;
//   - la nuit, la lumière : un caisson s'éclaire de l'intérieur, par l'émission ;
//   - une fausse écriture : des rangées de petits caractères inventés. De loin, on lit « du
//     texte » ; de près, le script pose de vraies lettres par-dessus (un Label3D) et demande
//     au shader de ne rien écrire ;
//   - la vitrine d'un distributeur : des rangées de canettes sur un fond éclairé.
//
// Le script règle tout cela par deux données attachées à chaque rectangle :
//   - la couleur de l'instance : la teinte du fond ;
//   - la donnée libre (INSTANCE_CUSTOM) : x, le nombre de caractères (0 : aucun) ; y, 1 si
//     l'écriture est verticale ; z, la graine des caractères ; w, la sorte d'enseigne.
// Un seul matériau sert ainsi à toutes les enseignes d'un immeuble, et un seul appel de
// dessin les trace toutes. Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

// Les sortes d'enseigne, telles que le script les écrit dans la donnée de l'instance.
const int KIND_LIGHT_BOX = 0;
const int KIND_PAINTED = 1;
const int KIND_VENDING = 2;

group_uniforms lighting;
/** 0 : jour. 1 : nuit. */
uniform float night : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Force de la lumière d'un caisson, la nuit. Au-dessus de 1, il éblouit et fait un halo. */
uniform float glow : hint_range(0.0, 6.0, 0.05) = 1.5;

group_uniforms frame;
/** Largeur du cadre de métal. */
uniform float border : hint_range(0.0, 0.08, 0.002) = 0.018;
uniform vec3 border_color : source_color = vec3(0.10, 0.10, 0.11);

varying flat vec2 v_size;
varying flat vec3 v_tint;
varying flat vec4 v_custom;

void vertex() {
	// Taille du panneau en mètres : l'échelle de son instance.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
	v_tint = COLOR.rgb;
	v_custom = INSTANCE_CUSTOM;
}

// Masque d'un rectangle centré sur « center », de demi-taille « half_size », à bords adoucis.
float rect(vec2 p, vec2 center, vec2 half_size, float soft) {
	vec2 q = abs(p - center) - half_size;
	return 1.0 - smoothstep(-soft, soft, max(q.x, q.y));
}

// Un faux caractère, dessiné dans un carré de côté 1 : trois traits horizontaux et trois
// verticaux, dont la place et la longueur sont tirées d'après le numéro du caractère.
// Cela ne veut rien dire, mais cela a la densité d'un idéogramme.
float glyph(vec2 g, float id, float soft) {
	float mask = 0.0;
	for (int k = 0; k < 3; k++) {
		float h1 = pc_hash2(vec2(id, float(k) * 3.0 + 1.0));
		float h2 = pc_rehash(h1, 1.0);
		float h3 = pc_rehash(h1, 2.0);
		// Les traits se répartissent en trois bandes, pour ne pas se superposer.
		float band = (float(k) + 0.2 + 0.6 * h1) / 3.0;
		float from = 0.05 + 0.3 * h2;
		float to = 0.95 - 0.3 * h3;
		mask = max(mask, rect(g, vec2(0.5 * (from + to), band), vec2(0.5 * (to - from), 0.05), soft));
		float column = (float(k) + 0.2 + 0.6 * h2) / 3.0;
		float low = 0.05 + 0.35 * h3;
		float high = 0.95 - 0.35 * h1;
		mask = max(mask, rect(g, vec2(column, 0.5 * (low + high)), vec2(0.05, 0.5 * (high - low)), soft));
	}
	return mask;
}

void fragment() {
	// p : position du pixel sur le panneau, en mètres, origine en bas à gauche.
	vec2 size = v_size;
	vec2 p = vec2(UV.x * size.x, (1.0 - UV.y) * size.y);
	float fw = max(fwidth(p.x), fwidth(p.y));
	int kind = int(v_custom.w + 0.5);

	// La couleur d'une instance arrive telle que le script l'a écrite, sans conversion.
	vec3 back = v_tint;
	// Encre claire sur fond sombre, sombre sur fond clair : le texte reste toujours lisible.
	vec3 ink = pc_luma(back) < 0.42 ? vec3(0.95, 0.94, 0.90) : vec3(0.08, 0.07, 0.07);
	vec3 col = back;
	// Part de la surface qui éclaire, la nuit.
	float lit = kind == KIND_PAINTED ? 0.0 : 1.0;

	// --- Fausse écriture -----------------------------------------------------------
	float glyph_count = floor(v_custom.x + 0.5);
	if (glyph_count > 0.5) {
		// L'écriture court le long du panneau : de gauche à droite, ou de haut en bas.
		bool vertical = v_custom.y > 0.5;
		float along = vertical ? size.y - p.y : p.x;
		float across = vertical ? p.x : p.y;
		float run = vertical ? size.y : size.x;
		float breadth = vertical ? size.x : size.y;
//@ 10-12
		float margin = 0.14 * breadth;
		// floor() donne le numéro du caractère, comme il donnait le numéro du carreau.
		float cell = (run - 2.0 * margin) / glyph_count;
		float side = min(cell * 0.86, breadth - 2.0 * margin);
		float index = floor((along - margin) / cell);
		vec2 g = vec2((along - margin - (index + 0.5) * cell) / side + 0.5, (across - 0.5 * breadth) / side + 0.5);
//@ 13+
		// La même mise en page que le vrai texte (le Label3D de enseignes.gd) : des caractères
		// serrés, au milieu du panneau, aussi grands que la place le permet. Quand l'enseigne
		// passe du vrai texte à la fausse écriture, les caractères restent à leur place.
		float side = min(0.62 * breadth, 0.9 * run / (glyph_count * (vertical ? 1.08 : 1.0)));
		float pitch = vertical ? 1.08 * side : side;
		float start = 0.5 * (run - pitch * glyph_count);
		// floor() donne le numéro du caractère, comme il donnait le numéro du carreau.
		float index = floor((along - start) / pitch);
		// L'encre d'un caractère occupe neuf dixièmes de sa case, comme dans une police.
		float ink_size = 0.9 * side;
		vec2 g = vec2((along - start - (index + 0.5) * pitch) / ink_size + 0.5, (across - 0.5 * breadth) / ink_size + 0.5);
//@ all
		if (index >= 0.0 && index < glyph_count && g.x > 0.0 && g.x < 1.0 && g.y > 0.0 && g.y < 1.0) {
//@ 10-12
			float soft = fw / side;
//@ 13+
			float soft = fw / ink_size;
//@ all
			// De loin, les traits d'un caractère sont plus fins que le pixel : il devient un
			// pavé gris, de la même densité.
			float detail = 1.0 - smoothstep(0.08, 0.3, soft);
			float mask = mix(0.4 * rect(g, vec2(0.5), vec2(0.45), soft), glyph(g, index + v_custom.z * 17.0, soft), detail);
			col = mix(col, ink, mask);
		}
	}

	// --- Distributeur de boissons ------------------------------------------------------
	if (kind == KIND_VENDING) {
		// En haut, la vitrine : trois rangées de canettes sur un fond blanc éclairé.
		float display_low = 0.45 * size.y;
		float display = rect(p, vec2(0.5 * size.x, 0.5 * (display_low + size.y) - 0.03), vec2(0.5 * size.x - 0.06, 0.5 * (size.y - display_low) - 0.06), fw);
		float row_height = (size.y - display_low - 0.12) / 3.0;
		float row = floor((p.y - display_low - 0.03) / row_height);
		float in_row = fract((p.y - display_low - 0.03) / row_height);
		float can = floor(p.x / 0.075);
		float in_can = fract(p.x / 0.075);
		float can_hash = pc_hash2(vec2(can, row + v_custom.z * 31.0));
		vec3 can_col = mix(vec3(0.80, 0.12, 0.10), vec3(0.15, 0.35, 0.75), step(0.3, can_hash));
		can_col = mix(can_col, vec3(0.20, 0.55, 0.25), step(0.55, can_hash));
		can_col = mix(can_col, vec3(0.90, 0.75, 0.15), step(0.75, can_hash));
		can_col = mix(can_col, vec3(0.30, 0.20, 0.12), step(0.9, can_hash));
		float can_mask = step(0.15, in_can) * step(in_can, 0.85) * step(0.12, in_row) * step(in_row, 0.78);
		// De loin, les canettes se fondent en une vitrine claire.
		can_mask *= 1.0 - smoothstep(0.01, 0.04, fw);
		col = mix(col, mix(vec3(0.92, 0.93, 0.92), can_col, can_mask), display);
		// En bas, la trappe où tombe la boisson.
		col = mix(col, vec3(0.04), rect(p, vec2(0.5 * size.x, 0.17 * size.y), vec2(0.3 * size.x, 0.045 * size.y), fw));
		// Seule la vitrine éclaire franchement ; la carrosserie luit à peine.
		lit = mix(0.12, 1.0, display);
	}

	// --- Cadre -------------------------------------------------------------------------
	float edge = min(min(p.x, size.x - p.x), min(p.y, size.y - p.y));
	float frame = 1.0 - pc_step(border, edge, fw);
	col = mix(col, pc_color_in(border_color), frame);
	lit *= 1.0 - frame;

	// --- Sorties -----------------------------------------------------------------------
	// Un caisson lumineux est une boîte de plastique translucide devant des tubes : la nuit,
	// sa couleur ne dépend plus de l'éclairage de la rue. On la sort donc par EMISSION.
	ALBEDO = pc_color_out(col * (1.0 - 0.6 * night * lit));
	EMISSION = pc_color_out(col) * night * lit * glow;
	ROUGHNESS = 0.35;
	SPECULAR = 0.5;
}
