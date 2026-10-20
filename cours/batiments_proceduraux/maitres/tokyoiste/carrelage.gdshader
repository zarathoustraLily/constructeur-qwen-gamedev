// Carrelage de façade tokyoïte (petits carreaux émaillés), entièrement calculé : aucune image.
// {STATUS}
//
// Ce que le shader dessine :
//   - des rangs de carreaux, séparés par des joints de ciment ;
//@ 3+ quiet
//   - une teinte et un faux aplomb propres à chaque carreau : la façade scintille quand on bouge ;
//   - des salissures : voile de crasse, coulures de pluie, rejaillissement en pied de mur ;
//   - le relief des joints, sans carte de normales ;
//@ 13+ quiet
//
// Trois finesses de calcul (« quality »), pour les petites machines : chaque bruit en moins,
// c'est du temps gagné sur chaque pixel de mur, et le mur couvre presque tout l'écran.
//@ all
//
// Le motif part de la position du pixel dans l'immeuble, en mètres. Le maillage n'a donc
// besoin d'aucune coordonnée UV, et un carreau mesure la même taille sur tous les murs.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms tiles;
/** Taille d'un carreau, joint compris : longueur, hauteur. */
uniform vec2 tile_size = vec2(0.235, 0.068);
/** Décalage d'un rang sur deux, en part de carreau. 0.5 : joints croisés. 0 : joints alignés. */
uniform float stagger : hint_range(0.0, 0.5, 0.01) = 0.5;
/** Largeur du joint. */
uniform float joint_width : hint_range(0.001, 0.03, 0.001) = 0.008;
//@ 3+
/** Retrait du joint par rapport à la face du carreau. */
uniform float joint_recess : hint_range(0.0, 0.01, 0.0005) = 0.002;
/** Largeur de l'arrondi au bord du carreau. */
uniform float bevel : hint_range(0.001, 0.02, 0.001) = 0.004;
/** Faux aplomb des carreaux : chacun renvoie le ciel sous un angle un peu différent. */
uniform float tilt : hint_range(0.0, 1.0, 0.01) = 0.3;
//@ all

group_uniforms colour;
uniform vec3 tile_color : source_color = vec3(0.80, 0.78, 0.72);
//@ 3+
/** Seconde teinte : chaque carreau tire la sienne entre les deux (écarts de cuisson). */
uniform vec3 tile_color_2 : source_color = vec3(0.70, 0.67, 0.60);
//@ all
uniform vec3 joint_color : source_color = vec3(0.50, 0.49, 0.46);
//@ 3+
/** Écart de teinte d'un carreau à l'autre. */
uniform float tile_variation : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Brillant de l'émail. 0 : grès mat. 1 : émail très lisse. */
uniform float glaze : hint_range(0.0, 1.0, 0.01) = 0.6;

group_uniforms weathering;
/** Voile de crasse, par grandes plages. */
uniform float grime : hint_range(0.0, 1.0, 0.01) = 0.3;
/** Coulures de pluie. */
uniform float streaks : hint_range(0.0, 1.0, 0.01) = 0.45;
/** Salissure de rejaillissement en pied de mur. */
uniform float ground_dirt : hint_range(0.0, 1.0, 0.01) = 0.4;
//@ 11+
/** Décalage du motif, en mètres : deux immeubles voisins n'ont pas les mêmes carreaux. */
uniform vec2 pattern_offset = vec2(0.0, 0.0);
//@ 13+

group_uniforms performance;
/** Finesse du calcul. Basse : carreaux, joints, grandes plages de teinte et de crasse. Moyenne : en plus, coulures. Haute : tout. */
uniform int quality : hint_enum("Basse", "Moyenne", "Haute") = 2;
//@ all

// Ce que vertex() calcule à chaque sommet arrive à fragment(), fondu d'un sommet à l'autre.
varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	// Position et normale dans le repère de l'objet, en mètres. Le motif est calculé à partir
	// d'elles : il suit l'immeuble quand on le déplace, et un carreau mesure la même taille
	// sur tous les murs, sans aucune coordonnée UV.
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

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
	// Finesse du calcul. « medium » ouvre ou ferme des morceaux entiers du shader : un bruit
	// qu'on ne calcule pas est le seul bruit vraiment gratuit. Le test porte sur un uniforme,
	// pas sur le pixel : tous les pixels prennent la même branche.
	bool medium = quality >= 1;
//@ all

	// --- 2. Rangs --------------------------------------------------------------
	// floor() donne le numéro du rang ; ce qui reste est la position dans le rang.
	float row = floor(v / tile_size.y);
	float vl = v - row * tile_size.y;
	// Distance au joint horizontal le plus proche, celui du dessous ou celui du dessus.
	float dy = min(vl, tile_size.y - vl);
//@ 3+
	// De quel côté est ce joint : en dessous (1) ou au-dessus (-1). Sert au relief.
	float sign_v = vl < 0.5 * tile_size.y ? 1.0 : -1.0;
//@ all

	// --- 3. Carreaux -----------------------------------------------------------
	// Un rang sur deux est décalé : les joints verticaux ne s'alignent pas.
	float shift = mod(row, 2.0) < 0.5 ? 0.0 : stagger;
	float uu = u / tile_size.x + shift;
//@ 2
	float ul = fract(uu) * tile_size.x;
//@ 3+
	// floor() encore : le numéro du carreau dans son rang.
	float column = floor(uu);
	float ul = (uu - column) * tile_size.x;
//@ all
	// Distance au joint vertical le plus proche.
	float dx = min(ul, tile_size.x - ul);
//@ 3+
	float sign_u = ul < 0.5 * tile_size.x ? 1.0 : -1.0;
	float d = min(dx, dy);

	// Le numéro du carreau (colonne, rang) donne ses tirages : toujours les mêmes pour lui.
	float ht = pc_hash2(vec2(column, row) + vec2(13.0, 71.0));
	float ht2 = pc_rehash(ht, 1.0);
	float ht3 = pc_rehash(ht, 2.0);
//@ all

	// --- 4. Joints -------------------------------------------------------------
	// pc_band() vaut 1 dans le joint et 0 dehors, avec un bord large d'un pixel : de loin,
	// le joint s'estompe au lieu de scintiller. Avec des carreaux de 6 cm, c'est
	// indispensable : à 10 m, un joint de 8 mm fait déjà moins d'un pixel.
	float half_joint = 0.5 * joint_width;
	float joint_mask = max(pc_band(dx, half_joint, fu), pc_band(dy, half_joint, fv));
//@ 3+

	// --- 5. Relief -------------------------------------------------------------
	// Pas de carte de normales : on calcule la pente de la surface et on penche la normale.
	// Au bord d'un joint, le carreau descend de « joint_recess » sur la largeur de l'arrondi.
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
	// Aucun carreau n'est posé parfaitement à plat. Un faux aplomb tiré par carreau suffit à
	// faire varier le reflet du ciel de l'un à l'autre. De loin, on l'éteint : un carreau plus
	// petit que le pixel ne peut pas avoir son propre reflet.
	float tilt_fade = tilt * (1.0 - joint_mask) * (1.0 - smoothstep(0.1, 0.5, fw / tile_size.y));
	slope_u += (ht2 - 0.5) * 0.02 * tilt_fade;
	slope_v += (ht3 - 0.5) * 0.02 * tilt_fade;

	// La normale est en espace vue ; les axes de la face sont en espace objet : on les y amène.
	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	NORMAL = pc_slope_normal(normalize(NORMAL), normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);
//@ all

	// --- Couleur ---------------------------------------------------------------
//@ 2
	// pc_color_in() amène la teinte dans l'espace où le shader fait ses mélanges.
	vec3 col = pc_color_in(tile_color);
//@ 3+
	// Chaque carreau tire sa teinte entre les deux couleurs, puis sa clarté. De loin, les
	// carreaux se fondent : on va vers la teinte moyenne, sinon l'image fourmille.
	float tile_fade = 1.0 - smoothstep(0.35, 1.2, fw / tile_size.y);
	float pick = mix(0.5, ht, tile_fade);
	vec3 col = mix(pc_color_in(tile_color), pc_color_in(tile_color_2), clamp(pick * tile_variation, 0.0, 1.0));
	col *= 1.0 + (ht2 - 0.5) * 0.12 * tile_variation * tile_fade;
//@ 3-12
	// Grandes plages plus claires ou plus sombres, qui enjambent les carreaux.
	float broad = pc_fbm2(p * 0.5, 3, fw * 0.5);
	col *= 0.93 + 0.14 * broad;

	// --- Salissures --------------------------------------------------------------
	// Voile de crasse : un bruit très large, seuillé pour faire des plages.
	float veil = smoothstep(0.4, 0.75, pc_fbm2(p * 0.27 + vec2(40.0, 13.0), 4, fw * 0.27));
	float film = grime * (0.1 + 0.5 * veil);
	// Coulures : un bruit très étiré vers le bas (serré en u, lâche en v), par grandes zones.
	// Sur un émail lisse, la pluie trace des traînées nettes et sombres.
	float runs = 0.0;
	if (streaks > 0.0) {
		float run = pc_fbm2(vec2(u * 11.0, v * 0.35), 4, max(fu * 11.0, fv * 0.35));
		float run_zone = smoothstep(0.3, 0.65, pc_fbm2(p * vec2(0.7, 0.3) + 71.0, 3, fw * 0.7));
		runs = streaks * smoothstep(0.5, 0.82, run) * run_zone;
	}
//@ 13+
	// Grandes plages plus claires ou plus sombres, qui enjambent les carreaux. C'est le bruit
	// qui se voit de plus loin : on le garde à toutes les finesses, avec moins d'octaves
	// (1 en finesse basse, 2 en moyenne, 3 en haute).
	float broad = pc_fbm2(p * 0.5, 1 + quality, fw * 0.5);
	col *= 0.93 + 0.14 * broad;

	// --- Salissures --------------------------------------------------------------
	// Voile de crasse : un bruit très large, seuillé pour faire des plages.
	float veil = smoothstep(0.4, 0.75, pc_fbm2(p * 0.27 + vec2(40.0, 13.0), 2 + quality, fw * 0.27));
	float film = grime * (0.1 + 0.5 * veil);
	// Coulures : un bruit très étiré vers le bas (serré en u, lâche en v), par grandes zones.
	// Sur un émail lisse, la pluie trace des traînées nettes et sombres. Finesse basse : pas
	// de coulures. Moyenne : avec moins d'octaves.
	float runs = 0.0;
	if (streaks > 0.0 && medium) {
		float run = pc_fbm2(vec2(u * 11.0, v * 0.35), 2 + quality, max(fu * 11.0, fv * 0.35));
		float run_zone = smoothstep(0.3, 0.65, pc_fbm2(p * vec2(0.7, 0.3) + 71.0, 1 + quality, fw * 0.7));
		runs = streaks * smoothstep(0.5, 0.82, run) * run_zone;
	}
//@ 3+
	// La crasse reste dans les joints et au bord des carreaux.
	float edge_dirt = exp(-d / 0.008) * (0.1 + 0.3 * grime);
	float dirt = clamp(film + runs + edge_dirt, 0.0, 1.0);
	col = mix(col, col * vec3(0.55, 0.54, 0.52), clamp(film + edge_dirt, 0.0, 1.0));
	col = mix(col, col * vec3(0.52, 0.52, 0.53), clamp(runs, 0.0, 1.0));
	// Rejaillissement : la pluie salit le pied du mur. v_pos.y est la hauteur au-dessus du sol.
//@ 3-12
	float splash = exp(-max(v_pos.y, 0.0) / 0.35) * (0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2)));
//@ 13+
	// Loin du sol, cette salissure est nulle : inutile de calculer son bruit.
	float splash = exp(-max(v_pos.y, 0.0) / 0.35);
	if (splash > 0.004 && medium) {
		splash *= 0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2));
	}
//@ 3+
	col = mix(col, col * vec3(0.52, 0.50, 0.46), ground_dirt * splash);
//@ all

	// --- Joints et sorties -------------------------------------------------------
//@ 2
	col = mix(col, pc_color_in(joint_color), joint_mask);
//@ 3+
	// Un joint encrassé est plus sombre qu'un joint propre.
	col = mix(col, pc_color_in(joint_color) * (1.0 - 0.5 * dirt), joint_mask);
//@ all
	// pc_color_out() rend la couleur dans l'espace que le moteur de rendu attend.
	ALBEDO = pc_color_out(col);
//@ 2
	// Le carreau émaillé est lisse, le joint de ciment est mat.
	ROUGHNESS = mix(0.4, 0.9, joint_mask);
//@ 3+
	// Le carreau émaillé est lisse, le joint de ciment est mat, la crasse ternit l'émail.
	// De loin, joints et carreaux se fondent en une surface satinée.
	float tile_roughness = mix(0.75, 0.22, glaze) + (ht3 - 0.5) * 0.1 * tile_fade + 0.5 * dirt;
	ROUGHNESS = clamp(mix(tile_roughness, 0.92, joint_mask), 0.08, 0.97);
//@ all
	SPECULAR = 0.5;
//@ 3+
	// Un peu d'ombre dans les joints.
	AO = 1.0 - 0.3 * joint_mask;
	AO_LIGHT_AFFECT = 0.35;
//@ all
}
