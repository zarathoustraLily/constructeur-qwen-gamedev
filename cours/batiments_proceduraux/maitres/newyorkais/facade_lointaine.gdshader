// Façade lointaine : de loin, toute une façade de la tour de brique, dessinée sur un seul
// rectangle.
// {STATUS}
//
// À 250 m, une brique fait moins d'un dixième de pixel, un pilier à peine un pixel : ce qu'on
// voit d'une façade, c'est la teinte de son mur et la grille de ses fenêtres. Ce shader dessine
// cela, et rien d'autre. Le script remplace par lui, au-delà de la distance lointaine, des
// centaines de boîtes et de fenêtres instanciées : un rectangle par façade et par gradin.
//
// La bascule ne doit pas se voir. Chaque morceau reprend donc ce que les shaders de près
// donnent à cette distance, en moyenne :
//   - le mur : la teinte moyenne des briques (ou des pierres du socle), avec les grandes plages
//     et la suie du shader de la brique, calculées par les mêmes bruits, aux mêmes endroits ;
//   - la fenêtre : la part de vitre que laissent le dormant et les châssis, calculée avec les
//     cotes du shader de la fenêtre ; derrière la vitre, la lumière moyenne d'une pièce, ou son
//     store, baissé dans les mêmes pièces que de près ;
//   - le rez-de-chaussée : le bandeau des enseignes et les vitrines, aux cotes de son script.
// La nuit, chaque fenêtre est allumée ou éteinte comme de près : même clé de tirage (l'étage,
// la pièce, la façade, la graine), même règle. Quand la caméra passe la distance lointaine, la
// tour change de dessin sans qu'une fenêtre s'allume ou s'éteigne.
//
// Il part des UV, comme le mur-rideau. La donnée de l'instance donne le premier étage du
// rectangle, sa première colonne, sa façade, et la marge de mur qui reste à chaque bout de la
// façade avant la première travée. La teinte de l'instance (COLOR) ne sert pas à teindre : elle
// porte deux longueurs, l'abscisse du bord gauche du rectangle le long du mur et la hauteur de
// son pied, dans le repère de la tour. Avec elles, le shader retrouve les coordonnées du shader
// de la brique, et ses bruits tombent aux mêmes endroits. Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

// Les cotes du rez-de-chaussée, les mêmes que dans son script : le linteau de pierre, le
// bandeau d'enseigne sous lui, le soubassement des vitrines.
const float LINTEL = 1.0;
const float FASCIA = 0.6;
const float BULKHEAD = 0.45;
// La lumière moyenne d'une pièce vue de loin : ce que le jour y fait entrer, ce que ses
// luminaires y ajoutent. Ce sont les formules du shader des pièces, réduites à leur moyenne ;
// les deux nombres ont été réglés en comparant des images de près et de loin, à la distance de
// la bascule, de jour et de nuit.
const float ROOM_DAYLIGHT = 0.12;
const float ROOM_LAMPS = 0.30;
// Une boutique est plus claire qu'un bureau : murs blancs, rayonnages, vitrine éclairée.
const float SHOP_DAYLIGHT = 0.22;

group_uniforms walls;
/** Les deux teintes des briques, et leur écart : les mêmes que le shader de la brique. */
uniform vec3 wall_color : source_color = vec3(0.62, 0.46, 0.36);
uniform vec3 wall_color_2 : source_color = vec3(0.50, 0.33, 0.25);
uniform float wall_variation : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform vec2 brick_size = vec2(0.2032, 0.0677);
/** Les mêmes nombres pour la pierre du socle. */
uniform vec3 stone_color : source_color = vec3(0.78, 0.75, 0.68);
uniform vec3 stone_color_2 : source_color = vec3(0.73, 0.70, 0.61);
uniform float stone_variation : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform vec2 stone_size = vec2(1.5, 0.61);
uniform float grime : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform vec2 pattern_offset = vec2(0.0, 0.0);
/** Haut du socle de pierre, au-dessus du sol de la tour. */
uniform float stone_top = 0.0;

group_uniforms grid;
uniform float bay_width : hint_range(1.0, 4.0, 0.01) = 2.0;
/** Fenêtre des étages : largeur et hauteur, et hauteur de son allège. */
uniform vec2 window_size = vec2(1.2, 1.9);
uniform float sill_height : hint_range(0.0, 1.5, 0.01) = 0.85;
uniform float floor_height : hint_range(2.5, 6.0, 0.01) = 3.66;
uniform float ground_height : hint_range(3.0, 9.0, 0.01) = 5.5;

group_uniforms window;
/** Les cotes de la fenêtre à guillotine : les mêmes que dans son shader. */
uniform vec3 frame_color : source_color = vec3(0.16, 0.17, 0.15);
uniform float frame_width = 0.05;
uniform float stile_width = 0.045;
uniform float top_rail = 0.05;
uniform float bottom_rail = 0.075;
uniform float meeting_rail = 0.035;
uniform float muntin_width = 0.018;
uniform ivec2 upper_lights = ivec2(1, 1);
uniform ivec2 lower_lights = ivec2(1, 1);
uniform float reflectivity : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform vec3 glass_tint : source_color = vec3(0.88, 0.93, 0.91);
/** Part des pièces dont le store est baissé : la même que dans le shader des pièces. */
uniform float shades : hint_range(0.0, 1.0, 0.01) = 0.55;
/** Teinte moyenne des bandeaux d'enseigne du rez-de-chaussée. */
uniform vec3 fascia_color : source_color = vec3(0.145, 0.118, 0.138);

group_uniforms lighting;
uniform float seed = 0.0;
uniform float night : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Les mêmes réglages que pour les pièces de près. */
uniform float floor_lit_day : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float floor_lit_night : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform vec3 tube_color : source_color = vec3(0.90, 0.96, 1.0);
uniform vec3 lobby_color : source_color = vec3(1.0, 0.86, 0.66);
uniform float lamp_energy : hint_range(0.0, 8.0, 0.05) = 1.6;

group_uniforms performance;
uniform int quality : hint_enum("Basse", "Moyenne", "Haute") = 2;

varying flat vec2 v_size;
varying flat vec4 v_custom;
varying flat vec2 v_start;

void vertex() {
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
	// x : le premier étage ; y : la première colonne ; z : la façade ; w : la marge au bout.
	v_custom = INSTANCE_CUSTOM;
	// x : abscisse du bord gauche le long du mur ; y : hauteur du pied, dans la tour.
	v_start = COLOR.rg;
}

// La teinte d'un mur vu de loin, telle que le shader de la brique la donne quand une brique est
// plus petite qu'un pixel : chaque brique ne tire plus sa teinte, on a la moyenne des deux ;
// restent les grandes plages et la suie, les mêmes bruits aux mêmes endroits, et la crasse du
// bord des briques, en moyenne sur une brique. Les joints, plus fins qu'un pixel, ne comptent
// presque plus.
vec3 far_wall(vec3 color_1, vec3 color_2, float variation, vec2 unit, vec2 p, float fw) {
	vec3 col = mix(pc_color_in(color_1), pc_color_in(color_2), clamp(0.5 * variation, 0.0, 1.0));
	float broad = pc_fbm2(p * 0.4, 1 + quality, fw * 0.4);
	col *= 0.9 + 0.2 * broad;
	float soot = smoothstep(0.35, 0.8, pc_fbm2(p * 0.12 + vec2(23.0, 7.0), 2 + quality, fw * 0.12));
	float film = grime * (0.12 + 0.55 * soot);
	// De près, la crasse vaut exp(-d / 6 mm), d étant la distance au joint. Sa moyenne sur une
	// brique de L sur H vaut à peu près 6 mm × (2 / L + 2 / H).
	float edge_dirt = min(0.006 * (2.0 / unit.x + 2.0 / unit.y), 1.0) * (0.08 + 0.25 * grime);
	return mix(col, col * vec3(0.42, 0.40, 0.40), clamp(film + edge_dirt, 0.0, 1.0));
}

// Part de vitre d'une fenêtre à guillotine fermée de « size » : ce que laissent le dormant, les
// montants, les traverses et les petits bois. Les mêmes cotes que dans le shader de la fenêtre.
float glass_share(vec2 size) {
	float glass_w = size.x - 2.0 * (frame_width + stile_width);
	float upper_h = 0.5 * size.y - frame_width - top_rail;
	float lower_h = 0.5 * size.y - frame_width - bottom_rail - meeting_rail;
	float area = glass_w * (upper_h + lower_h);
	// Les petits bois : des bandes verticales sur la hauteur de chaque châssis, horizontales sur
	// sa largeur.
	area -= muntin_width * (float(upper_lights.x - 1) * upper_h + float(lower_lights.x - 1) * lower_h);
	area -= muntin_width * glass_w * float(upper_lights.y - 1 + lower_lights.y - 1);
	return clamp(area / (size.x * size.y), 0.0, 1.0);
}

// Ce qu'on voit derrière la vitre, en moyenne : la pièce éclairée par le jour et par ses
// luminaires, ou bien son store, éclairé du dehors le jour, de la pièce la nuit.
vec3 far_room(float daylight, float lit, vec3 light_tint, float shade_cover, float r0) {
	float day = 1.0 - night;
	float lamp_power = lamp_energy * lit * mix(0.5, 1.0, night);
	vec3 moon = vec3(0.012, 0.016, 0.03) * night;
	vec3 room = vec3(0.92, 0.96, 1.0) * day * daylight + light_tint * lamp_power * ROOM_LAMPS + 0.4 * moon;
	vec3 cloth = mix(vec3(0.88, 0.85, 0.76), vec3(0.76, 0.78, 0.74), step(0.6, pc_rehash(r0, 12.0)));
	vec3 shade = cloth * (vec3(0.95, 0.97, 1.0) * day * 0.6 + light_tint * lamp_power * 0.55 + 2.0 * moon);
	return mix(room, shade, shade_cover);
}

void fragment() {
	float w = v_size.x;
	float h = v_size.y;
	vec2 q = vec2(UV.x * w, (1.0 - UV.y) * h);
	float footprint = max(fwidth(q.x), fwidth(q.y));
	// Hauteur du pixel dans la tour, et les coordonnées du shader de la brique.
	float y = v_start.y + q.y;
	vec2 p = v_start + q + pattern_offset;

	// --- Étages, comme le mur-rideau : floor() donne l'étage ---------------------------
	float first = v_custom.x;
	float level;
	float base;
	if (first < 0.5 && q.y < ground_height) {
		level = 0.0;
		base = 0.0;
	} else {
		float y0 = first < 0.5 ? ground_height : 0.0;
		float k = floor((q.y - y0) / floor_height);
		level = max(first, 1.0) + k;
		base = y0 + k * floor_height;
	}
	float yl = q.y - base;
	bool ground = level < 0.5;

	// --- Travées : floor() donne la colonne ----------------------------------------------
	float margin = v_custom.w;
	float bays = floor((w - 2.0 * margin) / bay_width + 0.5);
	float bx = q.x - margin;
	float bay = floor(bx / bay_width);
	float in_bay = bx - bay * bay_width;
	float from_axis = abs(in_bay - 0.5 * bay_width);
	bool in_grid = bay >= 0.0 && bay <= bays - 1.0;

	// --- La clé de tirage de la pièce : celle du shader de la fenêtre -------------------
	float face = v_custom.z;
	float column = v_custom.y + bay;
	float span = 1.0 + floor(pc_hash2(vec2(level, face * 31.0 + 5.0 + seed * 97.0)) * 3.0);
	float room_id = floor(column / span);
	float r0 = pc_hash3(vec3(level, room_id, face + 17.0 + seed * 101.0));
	float r9 = pc_rehash(r0, 9.0);

	// --- L'ouverture de cette case, sa part de vitre, sa lumière -------------------------
	float opening;
	float share;
	float fascia = 0.0;
	float lit;
	vec3 light_tint;
	float shade_cover = 0.0;
	float daylight = ROOM_DAYLIGHT;
	if (ground) {
		// Le rez-de-chaussée : sous le linteau, le bandeau d'enseigne ; sous lui, les vitrines,
		// posées sur leur soubassement. De près, un pilastre de pierre sépare les boutiques
		// toutes les deux ou trois travées : en moyenne, il mange un cinquième de pilier de
		// chaque côté de la travée.
		float pier = bay_width - window_size.x;
		float window_top = ground_height - LINTEL - FASCIA;
		float inside = min(0.5 * bay_width - 0.2 * pier - from_axis, min(q.y - BULKHEAD, window_top - q.y));
		opening = in_grid ? pc_step(0.0, inside, footprint) : 0.0;
		share = 0.94;
		float band = min(q.y - window_top, window_top + FASCIA - q.y);
		fascia = in_grid ? pc_step(0.0, band, footprint) : 0.0;
		// Une boutique ouverte est éclairée en plein jour ; la nuit, trois sur dix ont fermé.
		lit = step(r9, mix(0.95, 0.7, night));
		light_tint = mix(pc_color_in(tube_color), pc_color_in(lobby_color), 0.35);
		daylight = SHOP_DAYLIGHT;
	} else {
		// Les étages : la fenêtre, centrée dans sa travée, de l'allège au haut de la fenêtre.
		float inside = min(0.5 * window_size.x - from_axis, min(yl - sill_height, sill_height + window_size.y - yl));
		opening = in_grid ? pc_step(0.0, inside, footprint) : 0.0;
		share = glass_share(window_size);
		// La règle des pièces de près : un étage entier est allumé ou éteint ; dans un étage
		// allumé, neuf pièces sur dix le sont ; dans un étage éteint, une sur vingt.
		float floor_lit = step(pc_hash2(vec2(level, 7.0 + seed)), mix(floor_lit_day, floor_lit_night, night));
		lit = floor_lit > 0.5 ? step(r9, 0.9) : step(r9, 0.05);
		light_tint = pc_color_in(tube_color);
		// Le store, dans les mêmes pièces que de près, descendu à la même hauteur. Comme de
		// près, il n'est dessiné qu'à partir de la finesse moyenne.
		if (quality >= 1 && pc_rehash(r0, 10.0) < shades) {
			float low = window_size.y * mix(0.3, 0.95, pc_rehash(r0, 11.0));
			shade_cover = pc_step(low, yl - sill_height, footprint);
		}
	}

	// --- La vitre : ce qui la traverse, ce qu'elle reflète -------------------------------
	// Le reflet est celui du moteur : une vitre noire et lisse reflète le ciel. Ce qui la
	// traverse sort par EMISSION, atténué par la teinte du verre et par ce qu'il reflète.
	float n_dot_v = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float f0 = 0.16 * reflectivity * reflectivity;
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
	vec3 transmitted = far_room(daylight, lit, light_tint, shade_cover, r0) * pc_color_in(glass_tint) * (1.0 - fresnel);

	// --- Sorties -------------------------------------------------------------------------
	// Le mur : de la pierre au rez-de-chaussée et jusqu'en haut du socle, de la brique au-dessus.
	vec3 wall;
	if (ground || y < stone_top) {
		wall = far_wall(stone_color, stone_color_2, stone_variation, stone_size, p, footprint);
	} else {
		wall = far_wall(wall_color, wall_color_2, wall_variation, brick_size, p, footprint);
	}
	vec3 albedo = mix(wall, pc_color_in(fascia_color), fascia);
	// Dans l'ouverture, une part de cadre, de la teinte du cadre, et une part de vitre, noire.
	albedo = mix(albedo, pc_color_in(frame_color) * (1.0 - share), opening);
	ALBEDO = pc_color_out(albedo);
	EMISSION = pc_color_out(transmitted * share * opening);
	ROUGHNESS = mix(mix(0.85, 0.5, fascia), mix(0.55, 0.04, share), opening);
	SPECULAR = mix(0.35, mix(0.5, reflectivity, share), opening);
}
