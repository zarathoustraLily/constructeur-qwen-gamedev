// Pierre de taille parisienne (calcaire blond), entièrement calculée : aucune image.
// {STATUS}
//
// Ce que le shader dessine :
//   - des assises (rangs de pierres) et des blocs, séparés par des joints fins ;
//@ 3+ quiet
//   - une teinte, un grain et des piqûres propres à chaque bloc ;
//   - des salissures : voile de suie, coulures, rejaillissement en pied de mur ;
//   - le relief des joints, sans carte de normales ;
//@ 6+ quiet
//   - des refends : les rainures horizontales d'un soubassement ;
//@ 13+ quiet
//
// Trois finesses de calcul (« quality »), pour les petites machines : chaque bruit en moins,
// c'est du temps gagné sur chaque pixel de pierre, et la pierre couvre presque tout l'écran.
//@ all
//
// Le motif part de la position du pixel dans l'immeuble, en mètres. Le maillage n'a donc
// besoin d'aucune coordonnée UV, et un bloc mesure la même taille sur tous les murs.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms blocks;
/** Hauteur d'une assise : un rang de pierres. */
uniform float course_height : hint_range(0.15, 1.0, 0.01) = 0.38;
/** Longueur moyenne d'un bloc. */
uniform float block_length : hint_range(0.3, 3.0, 0.01) = 0.95;
//@ 3+
/** Irrégularité des longueurs. 0 : blocs tous pareils. */
uniform float length_variation : hint_range(0.0, 0.8, 0.01) = 0.4;
//@ all
/** Largeur du joint. */
uniform float joint_width : hint_range(0.001, 0.03, 0.001) = 0.006;
//@ 3+
/** Retrait du joint par rapport au nu de la pierre. */
uniform float joint_recess : hint_range(0.0, 0.02, 0.0005) = 0.003;
/** Largeur du chanfrein au bord du joint. */
uniform float bevel : hint_range(0.001, 0.05, 0.001) = 0.008;
//@ 6+

group_uniforms refends;
/** 0 : parement lisse. 1 : refends marqués (rainures horizontales d'un soubassement). */
uniform float refend_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Largeur de la rainure. */
uniform float refend_width : hint_range(0.01, 0.12, 0.001) = 0.04;
/** Profondeur de la rainure. */
uniform float refend_depth : hint_range(0.0, 0.08, 0.001) = 0.015;
//@ all

group_uniforms colour;
uniform vec3 stone_color : source_color = vec3(0.85, 0.76, 0.62);
//@ 3+
/** Seconde teinte : chaque bloc tire la sienne entre les deux. */
uniform vec3 stone_color_2 : source_color = vec3(0.77, 0.66, 0.51);
//@ all
uniform vec3 joint_color : source_color = vec3(0.62, 0.57, 0.49);
//@ 3+
/** Écart de teinte d'un bloc à l'autre. */
uniform float block_variation : hint_range(0.0, 1.0, 0.01) = 0.45;
/** Grain et piqûres de la pierre. */
uniform float grain : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms weathering;
/** Voile de suie, par grandes plages. */
uniform float soot : hint_range(0.0, 1.0, 0.01) = 0.25;
/** Coulures verticales. */
uniform float streaks : hint_range(0.0, 1.0, 0.01) = 0.2;
/** Salissure de rejaillissement en pied de mur. */
uniform float ground_dirt : hint_range(0.0, 1.0, 0.01) = 0.4;
//@ 11+
/** Décalage du motif, en mètres : deux immeubles voisins n'ont pas les mêmes pierres. */
uniform vec2 pattern_offset = vec2(0.0, 0.0);
//@ 13+

group_uniforms performance;
/** Finesse du calcul. Basse : blocs, joints, grandes plages de teinte et de suie. Moyenne : en plus, grain et coulures. Haute : tout. */
uniform int quality : hint_enum("Basse", "Moyenne", "Haute") = 2;
//@ all

// Ce que vertex() calcule à chaque sommet arrive à fragment(), fondu d'un sommet à l'autre.
varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	// Position et normale dans le repère de l'objet, en mètres. Le motif est calculé à partir
	// d'elles : il suit l'immeuble quand on le déplace, et un bloc mesure la même taille sur
	// tous les murs, sans aucune coordonnée UV.
	v_pos = VERTEX;
	v_nrm = NORMAL;
}
//@ 3+

// Position de la limite de bloc tirée dans la cellule k de l'assise row. Sans hasard, la
// limite serait au milieu de la cellule ; le hachage la pousse à gauche ou à droite.
float block_edge(float k, float row) {
	return k + 0.5 + (pc_hash2(vec2(k, row)) - 0.5) * length_variation;
}
//@ all

void fragment() {
	// --- 1. Coordonnées de face ----------------------------------------------
	// u court le long du mur, v monte. Les deux sont en mètres.
	vec3 n = normalize(v_nrm);
	vec3 t;
	vec3 b;
	pc_face_frame(n, t, b);
//@ 2-10
	float u = dot(v_pos, t);
	float v = dot(v_pos, b);
//@ 11+
	// Le décalage fait glisser tout le motif : c'est le script qui le tire, d'après la graine.
	float u = dot(v_pos, t) + pattern_offset.x;
	float v = dot(v_pos, b) + pattern_offset.y;
//@ all
	// Empreinte du pixel : de combien u et v changent d'un pixel au suivant.
	float fu = fwidth(u);
	float fv = fwidth(v);
//@ 3+
	float fw = max(fu, fv);
	vec2 p = vec2(u, v);
//@ 13+
	// Finesse du calcul. « medium » et « high » ouvrent ou ferment des morceaux entiers du
	// shader : un bruit qu'on ne calcule pas est le seul bruit vraiment gratuit. Le test porte
	// sur un uniforme, pas sur le pixel : tous les pixels prennent la même branche.
	bool medium = quality >= 1;
	bool high = quality >= 2;
//@ all

	// --- 2. Assises ------------------------------------------------------------
	// floor() donne le numéro du rang ; ce qui reste est la position dans le rang.
	float row = floor(v / course_height);
	float vl = v - row * course_height;
	// Distance au joint horizontal le plus proche, celui du dessous ou celui du dessus.
	float dy = min(vl, course_height - vl);
//@ 3+
	// De quel côté est ce joint : en dessous (1) ou au-dessus (-1). Sert au relief.
	float sign_v = vl < 0.5 * course_height ? 1.0 : -1.0;
//@ all

	// --- 3. Blocs --------------------------------------------------------------
//@ 2
	// Une assise sur deux est décalée d'un demi-bloc : les joints verticaux ne s'alignent pas.
	float shift = mod(row, 2.0) < 0.5 ? 0.0 : 0.5;
	float uu = u / block_length + shift;
	float ul = fract(uu) * block_length;
	// Distance au joint vertical le plus proche.
	float dx = min(ul, block_length - ul);
//@ 3+
	// Une assise sur deux est décalée d'un demi-bloc, plus un petit écart tiré par assise.
	float row_shift = (mod(row, 2.0) < 0.5 ? 0.0 : 0.5) + (pc_hash1(row * 7.0 + 3.0) - 0.5) * 0.3;
	float uu = u / block_length + row_shift;
	// Les limites de bloc ne sont plus régulières : chaque cellule tire la sienne. Le pixel
	// est à gauche ou à droite de la limite de sa cellule, ce qui dit dans quel bloc il est.
	float k = floor(uu);
	float edge_k = block_edge(k, row);
	float left;
	float right;
	float block_x;
	if (uu < edge_k) {
		left = block_edge(k - 1.0, row);
		right = edge_k;
		block_x = k - 1.0;
	} else {
		left = edge_k;
		right = block_edge(k + 1.0, row);
		block_x = k;
	}
	// Distance au joint vertical le plus proche, et de quel côté il se trouve.
	float dx = min(uu - left, right - uu) * block_length;
	float sign_u = (uu - left) < (right - uu) ? 1.0 : -1.0;
	float d = min(dx, dy);

	// Le numéro du bloc (colonne, assise) donne ses tirages : toujours les mêmes pour ce bloc.
	float hb = pc_hash2(vec2(block_x, row) + vec2(31.0, 57.0));
	float hb2 = pc_rehash(hb, 1.0);
	float hb3 = pc_rehash(hb, 2.0);
//@ all

	// --- 4. Joints -------------------------------------------------------------
//@ 2
	float half_joint = 0.5 * joint_width;
//@ 3+
	// Arêtes épaufrées : la largeur du joint varie un peu le long du joint. De loin, ce détail
	// est plus fin que le pixel : il n'est même pas calculé.
	float chip = 0.0;
//@ 3-12
	float chip_fade = 1.0 - smoothstep(0.3, 1.0, fw * 38.0);
//@ 13+
	// En finesse haute seulement.
	float chip_fade = high ? 1.0 - smoothstep(0.3, 1.0, fw * 38.0) : 0.0;
//@ 3+
	if (chip_fade > 0.0) {
		chip = pc_noise2(p * 38.0) * chip_fade;
	}
	float half_joint = 0.5 * joint_width * (0.75 + 0.9 * chip * chip);
//@ all
	// pc_band() vaut 1 dans le joint et 0 dehors, avec un bord large d'un pixel : de loin,
	// le joint s'estompe au lieu de scintiller.
	float joint_mask = max(pc_band(dx, half_joint, fu), pc_band(dy, half_joint, fv));
//@ 3+

	// --- 5. Relief des joints ----------------------------------------------------
	// Pas de carte de normales : on calcule la pente de la surface et on penche la normale.
	// Au bord d'un joint, la pierre descend de « joint_recess » sur la largeur du chanfrein.
	// Les rampes font au moins deux pixels : en dessous, le relief scintille.
	float slope_u = 0.0;
	float slope_v = 0.0;
	float ramp_slope;
	if (dx < dy) {
		pc_ramp_d(half_joint, half_joint + bevel, dx, 2.0 * fu, ramp_slope);
		slope_u += joint_recess * ramp_slope * sign_u;
	} else {
		pc_ramp_d(half_joint, half_joint + bevel, dy, 2.0 * fv, ramp_slope);
		slope_v += joint_recess * ramp_slope * sign_v;
	}
//@ 6+

	// --- Refends -----------------------------------------------------------------
	// Une rainure plus large et plus profonde sur chaque joint horizontal. Même recette que
	// le joint : une rampe, sa pente, et la normale qui penche.
	float half_groove = 0.5 * refend_width;
	float chamfer = min(0.45 * refend_width, 0.02);
	float groove_ramp = 1.0 - pc_ramp_d(half_groove - chamfer, half_groove, dy, 2.0 * fv, ramp_slope);
	slope_v += refend_amount * refend_depth * ramp_slope * sign_v;
	float groove = refend_amount * groove_ramp;
	// Ombre du bord supérieur dans la rainure : le soleil vient d'en haut.
	float joint_row = floor(v / course_height + 0.5);
	float across = (v - joint_row * course_height) / half_groove;
	float groove_shadow = refend_amount * groove_ramp * smoothstep(-0.5, 0.4, across);
//@ 3+

	// --- 6. Grain ------------------------------------------------------------------
	// Un bruit fin, propre à chaque bloc. Les coordonnées repartent de zéro dans chaque bloc,
	// décalées par ses tirages : deux blocs voisins n'ont pas le même grain, et les nombres
	// restent petits, donc précis.
	vec2 in_block = vec2((uu - left) * block_length, vl) + vec2(hb, hb2) * 37.0;
//@ 3-12
	float fine = pc_fbm2(in_block * 85.0, 3, fw * 85.0);
//@ 13+
	// Finesse basse : pas de grain. Moyenne : deux octaves. Haute : trois.
	float fine = 0.5;
	if (medium) {
		fine = pc_fbm2(in_block * 85.0, high ? 3 : 2, fw * 85.0);
	}
//@ 3+
	// Piqûres : de petits trous de coquille. Trop fins pour un relief propre, ils ne sont
	// rendus que par la couleur, et seulement de près.
	float pits = 0.0;
//@ 3-12
	float pit_fade = 1.0 - smoothstep(0.2, 0.7, fw * 260.0);
//@ 13+
	float pit_fade = high ? 1.0 - smoothstep(0.2, 0.7, fw * 260.0) : 0.0;
//@ 3+
	if (pit_fade > 0.0) {
		pits = smoothstep(0.80, 0.94, pc_noise2(in_block * vec2(190.0, 260.0))) * pit_fade;
	}
	float soft_height = (fine - 0.5) * 0.0007 * grain;

	// La normale est en espace vue ; les axes de la face sont en espace objet : on les y amène.
	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	vec3 normal_soft = pc_bump(normalize(NORMAL), VERTEX, soft_height);
	NORMAL = pc_slope_normal(normal_soft, normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);
//@ all

	// --- Couleur de la pierre --------------------------------------------------------
//@ 2
	// pc_color_in() amène la teinte dans l'espace où le shader fait ses mélanges.
	vec3 col = pc_color_in(stone_color);
//@ 3+
	// Chaque bloc tire sa teinte entre les deux couleurs de pierre, puis sa clarté.
	vec3 stone = pc_color_in(stone_color);
	vec3 stone_2 = pc_color_in(stone_color_2);
	vec3 col = mix(stone, stone_2, clamp(hb * block_variation * 1.4, 0.0, 1.0));
	col *= 1.0 + (hb2 - 0.5) * 0.16 * block_variation;
	// Un bloc sur vingt a été remplacé lors d'un ravalement : plus clair, plus propre.
	float renewed = step(0.95, hb3) * block_variation;
	col = mix(col, stone * 1.06, renewed * 0.6);

//@ 3-12
	// Grandes plages plus claires ou plus sombres, qui enjambent les blocs.
	float broad = pc_fbm2(p * 0.45, 4, fw * 0.45);
	col *= 0.9 + 0.2 * broad;
	// Dérive de teinte : plus chaude ici, plus grise là.
	float tone = pc_fbm2(p * 0.8 + vec2(9.0, 61.0), 3, fw * 0.8);
	col = mix(col, col * vec3(1.04, 1.0, 0.93), smoothstep(0.4, 0.75, tone) * 0.6);
	col = mix(col, vec3(pc_luma(col)), smoothstep(0.45, 0.2, tone) * 0.18);
	// Nuages doux propres à chaque bloc, puis le grain et les piqûres.
	float mottle = pc_fbm2(vec2(u * 0.9 + hb * 53.0, v * 3.0 + hb2 * 19.0), 3, fw * 3.0);
	col *= 1.0 + (mottle - 0.5) * 0.07 * grain;
	col *= 1.0 + (fine - 0.5) * 0.11 * grain;
	col *= 1.0 - 0.3 * pits * grain;
//@ 13+
	// Grandes plages plus claires ou plus sombres, qui enjambent les blocs. C'est le bruit
	// qui se voit de plus loin : on le garde à toutes les finesses, avec moins d'octaves
	// (2 en finesse basse, 3 en moyenne, 4 en haute).
	float broad = pc_fbm2(p * 0.45, 2 + quality, fw * 0.45);
	col *= 0.9 + 0.2 * broad;
	if (high) {
		// Dérive de teinte : plus chaude ici, plus grise là.
		float tone = pc_fbm2(p * 0.8 + vec2(9.0, 61.0), 3, fw * 0.8);
		col = mix(col, col * vec3(1.04, 1.0, 0.93), smoothstep(0.4, 0.75, tone) * 0.6);
		col = mix(col, vec3(pc_luma(col)), smoothstep(0.45, 0.2, tone) * 0.18);
		// Nuages doux propres à chaque bloc.
		float mottle = pc_fbm2(vec2(u * 0.9 + hb * 53.0, v * 3.0 + hb2 * 19.0), 3, fw * 3.0);
		col *= 1.0 + (mottle - 0.5) * 0.07 * grain;
	}
	// Le grain et les piqûres.
	col *= 1.0 + (fine - 0.5) * 0.11 * grain;
	col *= 1.0 - 0.3 * pits * grain;
//@ 3+

	// --- Salissures ------------------------------------------------------------------
	// Voile de suie : un bruit très large, seuillé pour faire des plages. Un bloc remplacé
	// est resté propre.
//@ 3-12
	float veil = smoothstep(0.38, 0.72, pc_fbm2(p * 0.23 + vec2(40.0, 13.0), 4, fw * 0.23));
	float film = soot * (0.15 + 0.6 * veil) * (1.0 - 0.7 * renewed);
	// Coulures : un bruit très étiré vers le bas (serré en u, lâche en v), par grandes zones.
	float runs = 0.0;
	if (streaks > 0.0) {
		float run = pc_fbm2(vec2(u * 9.0, v * 0.55), 4, max(fu * 9.0, fv * 0.55));
		float run_fine = pc_fbm2(vec2(u * 31.0, v * 0.9) + 5.0, 3, max(fu * 31.0, fv * 0.9));
		float run_zone = smoothstep(0.35, 0.7, pc_fbm2(p * vec2(0.6, 0.45) + 71.0, 3, fw * 0.6));
		runs = streaks * smoothstep(0.46, 0.86, run) * (0.4 + 0.6 * run_fine) * run_zone;
	}
//@ 13+
	float veil = smoothstep(0.38, 0.72, pc_fbm2(p * 0.23 + vec2(40.0, 13.0), 2 + quality, fw * 0.23));
	float film = soot * (0.15 + 0.6 * veil) * (1.0 - 0.7 * renewed);
	// Coulures : un bruit très étiré vers le bas (serré en u, lâche en v), par grandes zones.
	// Finesse basse : pas de coulures. Moyenne : sans leur détail fin, et avec moins d'octaves.
	float runs = 0.0;
	if (streaks > 0.0 && medium) {
		float run = pc_fbm2(vec2(u * 9.0, v * 0.55), 2 + quality, max(fu * 9.0, fv * 0.55));
		float run_fine = high ? pc_fbm2(vec2(u * 31.0, v * 0.9) + 5.0, 3, max(fu * 31.0, fv * 0.9)) : 0.5;
		float run_zone = smoothstep(0.35, 0.7, pc_fbm2(p * vec2(0.6, 0.45) + 71.0, 1 + quality, fw * 0.6));
		runs = streaks * smoothstep(0.46, 0.86, run) * (0.4 + 0.6 * run_fine) * run_zone;
	}
//@ 3+
	// La saleté s'accroche au bord des joints.
	float edge_dirt = exp(-d / 0.02) * (0.08 + 0.22 * soot);
	float dirt = clamp(film + runs + edge_dirt, 0.0, 1.0);
	col = mix(col, col * vec3(0.50, 0.48, 0.45), clamp(film + edge_dirt, 0.0, 1.0));
	col = mix(col, col * vec3(0.60, 0.57, 0.53), clamp(runs, 0.0, 1.0));
	// Rejaillissement : la pluie salit le pied du mur. v_pos.y est la hauteur au-dessus du sol.
	float above_ground = max(v_pos.y, 0.0);
//@ 3-12
	float splash = exp(-above_ground / 0.42) * (0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2)));
//@ 13+
	// Loin du sol, cette salissure est nulle : inutile de calculer son bruit.
	float splash = exp(-above_ground / 0.42);
	if (splash > 0.004 && medium) {
		splash *= 0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2));
	}
//@ 3+
	col = mix(col, col * vec3(0.50, 0.47, 0.41), ground_dirt * splash);
//@ all

	// --- Joints et sorties -------------------------------------------------------------
//@ 2
	col = mix(col, pc_color_in(joint_color), joint_mask);
//@ 3+
	// Un joint encrassé est plus sombre qu'un joint propre.
	col = mix(col, pc_color_in(joint_color) * (1.0 - 0.45 * dirt), joint_mask);
//@ 6+
	col *= 1.0 - 0.1 * groove - 0.32 * groove_shadow;
//@ all
	// pc_color_out() rend la couleur dans l'espace que le moteur de rendu attend.
	ALBEDO = pc_color_out(col);
//@ 2
	// La pierre est mate partout.
	ROUGHNESS = 0.9;
//@ 3+
	ROUGHNESS = mix(0.84, 0.96, clamp(fine * 0.6 + dirt * 0.6 + joint_mask, 0.0, 1.0));
//@ all
	SPECULAR = 0.35;
//@ 3-5
	// Un peu d'ombre dans les creux.
	AO = 1.0 - 0.3 * joint_mask;
	AO_LIGHT_AFFECT = 0.35;
//@ 6+
	// Un peu d'ombre dans les creux.
	AO = 1.0 - 0.2 * groove - 0.3 * joint_mask;
	AO_LIGHT_AFFECT = 0.35;
//@ all
}
