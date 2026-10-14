// Brique de Manhattan, en appareil à boutisses (« common bond »), entièrement calculée : aucune
// image.
// {STATUS}
//
// Ce que le shader dessine :
//   - des assises de briques posées en quinconce, séparées par des joints de mortier ;
//   - un rang de boutisses toutes les six assises : des briques vues par leur bout, deux fois
//     plus courtes. C'est l'appareil de la plupart des murs de brique de New York ;
//@ 3+ quiet
//   - une teinte propre à chaque brique, et quelques briques plus cuites, plus sombres ;
//   - des salissures : suie par grandes plages, coulures de pluie, rejaillissement en pied ;
//   - le relief des joints, en retrait de la face des briques, sans carte de normales ;
//@ 6+ quiet
//
// Le même shader fait aussi la pierre de taille du soubassement : d'autres nombres (des blocs
// de 1,50 m sur 0,61 m, pas de boutisses), le même code.
//@ 13+ quiet
//
// Trois finesses de calcul (« quality »), pour les petites machines : chaque bruit en moins,
// c'est du temps gagné sur chaque pixel de mur, et le mur couvre presque tout l'écran.
//@ all
//
// Le motif part de la position du pixel dans la tour, en mètres. Le maillage n'a donc besoin
// d'aucune coordonnée UV, et une brique mesure la même taille sur tous les murs.
//
// Cotes : brique modulaire américaine, 8 pouces de long et 2⅔ pouces de haut, joint de mortier
// compris (trois assises font 8 pouces) ; joint de ⅜ de pouce. Brick Industry Association,
// Technical Notes 10. Rang de boutisses tous les cinq, six ou sept rangs : Technical Notes 30.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms bricks;
/** Taille d'une panneresse (brique vue sur sa longueur), joint compris : 203 mm × 67,7 mm. */
uniform vec2 brick_size = vec2(0.2032, 0.0677);
/** Un rang de boutisses toutes les N assises. 0 : pas de boutisses (appareil en panneresses). */
uniform int header_every : hint_range(0, 12) = 6;
/** Largeur du joint de mortier : ⅜ de pouce. */
uniform float joint_width : hint_range(0.001, 0.03, 0.0005) = 0.0095;
//@ 3+
/** Retrait du joint par rapport à la face des briques. */
uniform float joint_recess : hint_range(0.0, 0.02, 0.0005) = 0.004;
/** Largeur de l'arrondi au bord de la brique. */
uniform float bevel : hint_range(0.001, 0.02, 0.001) = 0.005;
//@ all

group_uniforms colour;
uniform vec3 brick_color : source_color = vec3(0.62, 0.46, 0.36);
//@ 3+
/** Seconde teinte : chaque brique tire la sienne entre les deux (écarts de cuisson). */
uniform vec3 brick_color_2 : source_color = vec3(0.50, 0.33, 0.25);
//@ all
uniform vec3 joint_color : source_color = vec3(0.66, 0.63, 0.58);
//@ 3+
/** Écart de teinte d'une brique à l'autre. */
uniform float brick_variation : hint_range(0.0, 1.0, 0.01) = 0.6;
/** Part des briques plus cuites, presque brunes. */
uniform float dark_bricks : hint_range(0.0, 0.3, 0.005) = 0.06;

group_uniforms weathering;
/** Suie, par grandes plages. */
uniform float grime : hint_range(0.0, 1.0, 0.01) = 0.35;
/** Coulures de pluie. */
uniform float streaks : hint_range(0.0, 1.0, 0.01) = 0.4;
/** Salissure de rejaillissement en pied de mur. */
uniform float ground_dirt : hint_range(0.0, 1.0, 0.01) = 0.4;
//@ 11+
/** Décalage du motif, en mètres : deux tours voisines n'ont pas les mêmes briques. */
uniform vec2 pattern_offset = vec2(0.0, 0.0);
//@ 13+

group_uniforms performance;
/** Finesse du calcul. Basse : briques, joints, grandes plages de teinte et de suie. Moyenne : en plus, coulures. Haute : tout. */
uniform int quality : hint_enum("Basse", "Moyenne", "Haute") = 2;
//@ all

// Ce que vertex() calcule à chaque sommet arrive à fragment(), fondu d'un sommet à l'autre.
varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	// Position et normale dans le repère de l'objet, en mètres.
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

void fragment() {
	// --- 1. Coordonnées de face --------------------------------------------------------
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
	// Finesse du calcul. « medium » ouvre ou ferme des morceaux entiers du shader. Le test porte
	// sur un uniforme, pas sur le pixel : tous les pixels prennent la même branche.
	bool medium = quality >= 1;
//@ all

	// --- 2. Assises ----------------------------------------------------------------------
	// floor() donne le numéro de l'assise ; ce qui reste est la position dans l'assise.
	float row = floor(v / brick_size.y);
	float vl = v - row * brick_size.y;
	// Distance au joint horizontal le plus proche, celui du dessous ou celui du dessus.
	float dy = min(vl, brick_size.y - vl);
//@ 3+
	// De quel côté est ce joint : en dessous (1) ou au-dessus (-1). Sert au relief.
	float sign_v = vl < 0.5 * brick_size.y ? 1.0 : -1.0;
//@ all

	// --- 3. Briques ----------------------------------------------------------------------
	// Une assise sur « header_every » est un rang de boutisses : les briques y sont vues par
	// leur bout, deux fois plus courtes. Les autres assises sont en panneresses, décalées d'une
	// demi-brique une fois sur deux.
	bool header_row = header_every > 0 && mod(row, float(header_every)) < 0.5;
	float unit = header_row ? 0.5 * brick_size.x : brick_size.x;
	float shift = header_row ? 0.25 : (mod(row, 2.0) < 0.5 ? 0.0 : 0.5);
	float uu = u / unit + shift;
	// floor() encore : le numéro de la brique dans son assise.
	float column = floor(uu);
	float ul = (uu - column) * unit;
	// Distance au joint vertical le plus proche.
	float dx = min(ul, unit - ul);
//@ 3+
	float sign_u = ul < 0.5 * unit ? 1.0 : -1.0;
	float d = min(dx, dy);
	// Le numéro de la brique (colonne, assise) donne ses tirages : toujours les mêmes pour elle.
	float hb = pc_hash2(vec2(column, row) + vec2(17.0, 43.0));
	float hb2 = pc_rehash(hb, 1.0);
	float hb3 = pc_rehash(hb, 2.0);
//@ all

	// --- 4. Joints -----------------------------------------------------------------------
	// pc_band() vaut 1 dans le joint et 0 dehors, avec un bord large d'un pixel : de loin,
	// le joint s'estompe au lieu de scintiller.
	float half_joint = 0.5 * joint_width;
	float joint_mask = max(pc_band(dx, half_joint, fu), pc_band(dy, half_joint, fv));
//@ 3+

	// --- 5. Relief -------------------------------------------------------------------------
	// Pas de carte de normales : on calcule la pente de la surface et on penche la normale.
	// Au bord d'un joint, la brique descend de « joint_recess » sur la largeur de l'arrondi.
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
	// La normale est en espace vue ; les axes de la face sont en espace objet : on les y amène.
	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	NORMAL = pc_slope_normal(normalize(NORMAL), normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);
//@ all

	// --- Couleur -------------------------------------------------------------------------
//@ 2
	// pc_color_in() amène la teinte dans l'espace où le shader fait ses mélanges.
	vec3 col = pc_color_in(brick_color);
//@ 3+
	// Chaque brique tire sa teinte entre les deux couleurs, et quelques-unes sont plus cuites.
	// De loin, les briques se fondent : on va vers la teinte moyenne, sinon l'image fourmille.
	float brick_fade = 1.0 - smoothstep(0.35, 1.2, fw / brick_size.y);
	float pick = mix(0.5, hb, brick_fade);
	vec3 col = mix(pc_color_in(brick_color), pc_color_in(brick_color_2), clamp(pick * brick_variation, 0.0, 1.0));
	// Chaque brique est un peu plus claire ou plus sombre que sa voisine, d'autant plus que
	// l'écart de teinte est fort.
	col *= 1.0 + (hb2 - 0.5) * 0.3 * brick_variation * brick_fade;
	float dark = step(hb3, dark_bricks) * brick_fade;
	col = mix(col, col * vec3(0.68, 0.6, 0.56), dark);
//@ 3-12
	// Grandes plages plus claires ou plus sombres, qui enjambent les briques.
	float broad = pc_fbm2(p * 0.4, 3, fw * 0.4);
	col *= 0.9 + 0.2 * broad;

	// --- Salissures ----------------------------------------------------------------------
	// Suie : un bruit très large, seuillé pour faire des plages. La fumée du charbon noircit la
	// brique par grandes taches, pas uniformément.
	float soot = smoothstep(0.35, 0.8, pc_fbm2(p * 0.12 + vec2(23.0, 7.0), 4, fw * 0.12));
	float film = grime * (0.12 + 0.55 * soot);
	// Coulures : un bruit très étiré vers le bas (serré en u, lâche en v), par grandes zones.
	float runs = 0.0;
	if (streaks > 0.0) {
		float run = pc_fbm2(vec2(u * 7.0, v * 0.25), 4, max(fu * 7.0, fv * 0.25));
		float run_zone = smoothstep(0.35, 0.7, pc_fbm2(p * vec2(0.5, 0.15) + 31.0, 3, fw * 0.5));
		runs = streaks * smoothstep(0.5, 0.85, run) * run_zone;
	}
//@ 13+
	// Grandes plages plus claires ou plus sombres, qui enjambent les briques. Moins d'octaves
	// quand la finesse baisse (1 en basse, 2 en moyenne, 3 en haute).
	float broad = pc_fbm2(p * 0.4, 1 + quality, fw * 0.4);
	col *= 0.9 + 0.2 * broad;

	// --- Salissures ----------------------------------------------------------------------
	// Suie : un bruit très large, seuillé pour faire des plages.
	float soot = smoothstep(0.35, 0.8, pc_fbm2(p * 0.12 + vec2(23.0, 7.0), 2 + quality, fw * 0.12));
	float film = grime * (0.12 + 0.55 * soot);
	// Coulures : finesse basse, pas de coulures ; moyenne, une octave de moins.
	float runs = 0.0;
	if (streaks > 0.0 && medium) {
		float run = pc_fbm2(vec2(u * 7.0, v * 0.25), 2 + quality, max(fu * 7.0, fv * 0.25));
		float run_zone = smoothstep(0.35, 0.7, pc_fbm2(p * vec2(0.5, 0.15) + 31.0, 1 + quality, fw * 0.5));
		runs = streaks * smoothstep(0.5, 0.85, run) * run_zone;
	}
//@ 3+
	// La crasse reste dans les joints et au bord des briques.
	float edge_dirt = exp(-d / 0.006) * (0.08 + 0.25 * grime);
	float dirt = clamp(film + runs + edge_dirt, 0.0, 1.0);
	col = mix(col, col * vec3(0.42, 0.40, 0.40), clamp(film + edge_dirt, 0.0, 1.0));
	col = mix(col, col * vec3(0.55, 0.54, 0.55), clamp(runs, 0.0, 1.0));
	// Rejaillissement : la pluie salit le pied du mur. v_pos.y est la hauteur au-dessus du sol.
	float splash = exp(-max(v_pos.y, 0.0) / 0.5);
//@ 3-12
	if (splash > 0.004) {
		splash *= 0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2));
	}
//@ 13+
	if (splash > 0.004 && medium) {
		splash *= 0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2));
	}
//@ 3+
	col = mix(col, col * vec3(0.50, 0.48, 0.45), ground_dirt * splash);
//@ all

	// --- Joints et sorties -------------------------------------------------------------------
//@ 2
	col = mix(col, pc_color_in(joint_color), joint_mask);
	// pc_color_out() rend la couleur dans l'espace que le moteur de rendu attend.
	ALBEDO = pc_color_out(col);
	ROUGHNESS = mix(0.85, 0.95, joint_mask);
//@ 3+
	// Un joint encrassé est plus sombre qu'un joint propre.
	col = mix(col, pc_color_in(joint_color) * (1.0 - 0.55 * dirt), joint_mask);
	// pc_color_out() rend la couleur dans l'espace que le moteur de rendu attend.
	ALBEDO = pc_color_out(col);
	// La brique est mate ; la suie la rend plus mate encore.
	ROUGHNESS = clamp(0.82 + (hb2 - 0.5) * 0.1 * brick_fade + 0.12 * dirt + 0.08 * joint_mask, 0.6, 0.98);
	// Un peu d'ombre dans les joints.
	AO = 1.0 - 0.35 * joint_mask;
	AO_LIGHT_AFFECT = 0.35;
//@ all
	SPECULAR = 0.35;
}
