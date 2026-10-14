// Fenêtre coulissante en aluminium : un simple rectangle devient une fenêtre complète.
// {STATUS}
//
// Ce que le shader dessine :
//   - la menuiserie : un dormant mince, et deux vantaux qui se croisent (quatre si la baie est
//     large). C'est la fenêtre coulissante de presque tous les immeubles japonais ;
//@ 4
//   - un vitrage sombre où le ciel se reflète.
//@ 5+ quiet
//   - le vitrage et ses reflets ;
//   - une pièce derrière la vitre, sans aucune géométrie : on prolonge le regard dans une
//     boîte imaginaire (« interior mapping »). Un bureau : plafond à dalles, tubes
//     fluorescents, armoires de métal, store à lames ;
//@ 6+ quiet
//   - d'autres pièces selon l'étage : un logement (placard à portes coulissantes, plafonnier
//     rond, rideaux) ou une cage d'escalier (verre dépoli). Le script dit laquelle, fenêtre
//     par fenêtre, par une donnée attachée à l'instance ;
//@ 10+ quiet
//   - des vitrines et des portes de boutique : vitrages fixes, rayonnages, lumière blanche ;
//@ 11+ quiet
//   - des détails qui changent d'une fenêtre à l'autre : moustiquaire sur un vantail, verre
//     armé, tatamis, cloisons de papier, saleté.
//@ all
//
// Contrairement au carrelage, ce shader part des UV : il sert sur des rectangles instanciés
// (MultiMesh), un par fenêtre, que le script pose avec MeshBuilder.panel(). Le rectangle de
// base mesure un mètre de côté ; sa taille réelle est l'échelle de son instance.
//@ 5+ quiet
// La pièce est rendue par l'émission : elle ne reçoit ni les ombres ni les lampes de la scène.
//@ all
// Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"
//@ 6+

// Ce qu'il y a derrière la fenêtre. Le script l'écrit dans la donnée de l'instance.
const int KIND_OFFICE = 0;
const int KIND_DWELLING = 1;
const int KIND_CORE = 2;
//@ 10+
const int KIND_SHOP = 3;
const int KIND_SHOP_DOOR = 4;
//@ all

group_uniforms frame;
/** Largeur du dormant : le cadre fixé au mur. */
uniform float frame_width : hint_range(0.01, 0.15, 0.005) = 0.04;
/** Largeur des montants et des traverses d'un vantail. */
uniform float sash_width : hint_range(0.01, 0.12, 0.005) = 0.035;
/** Au-delà de cette largeur de baie, la fenêtre a quatre vantaux au lieu de deux. */
uniform float four_sash_width : hint_range(1.0, 5.0, 0.05) = 2.4;
uniform vec3 frame_color : source_color = vec3(0.62, 0.63, 0.64);
//@ 10+
/** Vrai : la teinte de la menuiserie vient de la couleur de l'instance, pas de « frame_color ». */
uniform bool frame_color_from_instance = false;
//@ all

group_uniforms glass;
uniform float glass_roughness : hint_range(0.0, 0.5, 0.005) = 0.04;
//@ 4
/** Teinte du vitrage tant qu'on ne voit rien derrière : sombre, pour que le ciel s'y reflète. */
uniform vec3 glass_color : source_color = vec3(0.07, 0.09, 0.11);
//@ 5+
/** Force des reflets. 0.5 : vitrage neuf. 1 : reflets marqués. */
uniform float reflectivity : hint_range(0.0, 1.0, 0.01) = 0.85;
uniform vec3 glass_tint : source_color = vec3(0.86, 0.94, 0.93);
//@ 11+
/** Part des fenêtres dont un vantail porte une moustiquaire : il paraît plus gris. */
uniform float screens : hint_range(0.0, 1.0, 0.01) = 0.6;
/** Part des fenêtres en verre armé : un treillis de fil métallique noyé dans le verre. */
uniform float wired : hint_range(0.0, 1.0, 0.01) = 0.4;
/** Poussière et traces sur le verre. */
uniform float dirt : hint_range(0.0, 1.0, 0.01) = 0.25;
//@ 5+

group_uniforms room;
/** Profondeur moyenne de la pièce. */
uniform float room_depth : hint_range(1.0, 12.0, 0.1) = 5.0;
/** Largeur de la pièce, en largeurs de fenêtre. */
uniform float room_width_factor : hint_range(1.0, 4.0, 0.05) = 1.7;
/** Hauteur sous plafond. */
uniform float ceiling_height : hint_range(2.0, 5.0, 0.05) = 2.5;
//@ 5
/** Hauteur de l'allège : le sol de la pièce est plus bas que le bas de la fenêtre. */
uniform float sill_height : hint_range(0.0, 1.5, 0.01) = 0.9;
//@ 5+
/** Part des fenêtres garnies : store à lames au bureau, rideaux au logement. */
uniform float dressing : hint_range(0.0, 1.0, 0.01) = 0.6;
/** Change le tirage de toutes les pièces. */
uniform float seed = 0.0;

group_uniforms lighting;
/** 0 : jour. 1 : nuit. */
uniform float night : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Part des bureaux allumés, le jour puis la nuit. Un bureau s'éclaire en plein jour. */
uniform float office_lit_day : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float office_lit_night : hint_range(0.0, 1.0, 0.01) = 0.4;
//@ 6+
/** Part des logements allumés, le jour puis la nuit. */
uniform float home_lit_day : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float home_lit_night : hint_range(0.0, 1.0, 0.01) = 0.6;
//@ 5+
/** Teinte des tubes fluorescents : un blanc froid, à peine vert. */
uniform vec3 tube_color : source_color = vec3(0.86, 0.96, 1.0);
//@ 6+
/** Teinte des lampes chaudes des logements. */
uniform vec3 lamp_color : source_color = vec3(1.0, 0.80, 0.55);
//@ 5+
uniform float lamp_energy : hint_range(0.0, 8.0, 0.05) = 1.6;
//@ all

// « flat » : la valeur n'est pas fondue entre les sommets, elle est la même sur tout le
// rectangle. C'est ce qu'il faut pour une donnée propre à la fenêtre entière.
varying flat vec2 v_size;
//@ 5+
varying flat vec3 v_axis_x;
varying flat vec3 v_axis_y;
varying flat vec3 v_room_key;
//@ 6+
varying flat vec4 v_custom;
//@ 10+
varying flat vec3 v_tint;
//@ all

void vertex() {
	// Le rectangle est un carré d'un mètre de côté, mis à l'échelle par son instance : la
	// longueur des deux premiers axes de sa matrice est sa taille en mètres. Dans un
	// MultiMesh, MODEL_MATRIX est la matrice de l'instance.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
//@ 5+
	// Les axes de la fenêtre (vers la droite, vers le haut), amenés dans l'espace de la caméra.
	v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
	v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
	// La position de la fenêtre sert de clé de tirage : chaque fenêtre aura sa pièce.
	v_room_key = MODEL_MATRIX[3].xyz;
//@ 6+
	// Donnée que le script a attachée à cette instance (voir panel()) : x, ce qu'il y a derrière
	// la fenêtre ; y, la hauteur de son allège.
	v_custom = INSTANCE_CUSTOM;
//@ 10+
	// Couleur que le script a donnée à cette instance : la teinte de la menuiserie.
	v_tint = COLOR.rgb;
//@ all
}
//@ 5+

// Masque d'un rectangle centré sur « center », de demi-taille « half_size », à bords adoucis
// sur « soft ». C'est la brique de tout ce qu'on dessine sur les parois de la pièce.
float rect(vec2 p, vec2 center, vec2 half_size, float soft) {
	vec2 q = abs(p - center) - half_size;
	return 1.0 - smoothstep(-soft, soft, max(q.x, q.y));
}

// Rayures : 1 sur des lignes de demi-largeur « half_width », espacées de « pitch » le long
// de x ; 0 ailleurs. De loin, quand le pas devient plus fin que le pixel, elles s'effacent.
float stripes(float x, float pitch, float half_width, float soft) {
	float to_line = abs(fract(x / pitch + 0.5) - 0.5) * pitch;
	float line = 1.0 - smoothstep(half_width, half_width + soft, to_line);
	return line * (1.0 - smoothstep(0.15, 0.6, soft / pitch));
}

// Quadrillage : des rayures dans les deux sens.
float grid_lines(vec2 p, vec2 pitch, float half_width, float soft) {
	return max(stripes(p.x, pitch.x, half_width, soft), stripes(p.y, pitch.y, half_width, soft));
}

// Paroi d'un bureau. « face » : 0 mur du fond, 1 mur latéral, 2 sol, 3 plafond. « m » : les
// coordonnées sur la paroi, en mètres ; « extent » : sa taille. « fixture » reçoit le masque
// des luminaires : 1 sur un tube fluorescent.
vec3 office_surface(int face, vec2 m, vec2 extent, float soft, float r, out float fixture) {
	fixture = 0.0;
	if (face == 3) {
		// Plafond suspendu : des dalles de 60 cm, et un luminaire à tubes toutes les trois dalles.
		vec3 col = vec3(0.80, 0.80, 0.78) * (1.0 - 0.10 * grid_lines(m, vec2(0.6), 0.008, soft));
		vec2 cell = vec2(1.8, 1.8);
		vec2 in_cell = (fract(m / cell) - 0.5) * cell;
		fixture = rect(in_cell, vec2(0.0), vec2(0.6, 0.14), soft);
		return col;
	}
	if (face == 2) {
		// Moquette en dalles de 50 cm, deux gris en damier.
		vec2 tile = floor(m / 0.5);
		return vec3(0.30, 0.31, 0.33) * (mod(tile.x + tile.y, 2.0) < 0.5 ? 1.0 : 0.9);
	}
	vec3 col = vec3(0.78, 0.78, 0.75);
	// Plinthe grise.
	col = mix(col, vec3(0.35, 0.35, 0.36), 1.0 - smoothstep(0.08 - soft, 0.08 + soft, m.y));
	if (face == 0) {
		// Mur du fond : une rangée d'armoires de métal, puis une porte.
		float run = extent.x * (0.35 + 0.4 * r);
		float cabinet = rect(m, vec2(0.5 * run + 0.1, 0.9), vec2(0.5 * run, 0.9), soft);
		vec3 steel = vec3(0.56, 0.58, 0.57) * (1.0 - 0.35 * grid_lines(vec2(m.x - 0.1, m.y), vec2(0.45, 0.9), 0.004, soft));
		col = mix(col, steel, cabinet);
		float door_x = min(run + 0.9, extent.x - 0.5);
		col = mix(col, vec3(0.52, 0.47, 0.40), rect(m, vec2(door_x, 1.0), vec2(0.42, 1.0), soft));
	} else {
		// Mur latéral : un tableau blanc dans son cadre d'aluminium.
		vec2 board = vec2(extent.x * (0.35 + 0.3 * r), 1.45);
		col = mix(col, vec3(0.55, 0.56, 0.57), rect(m, board, vec2(0.93, 0.48), soft));
		col = mix(col, vec3(0.90, 0.91, 0.90), rect(m, board, vec2(0.90, 0.45), soft));
	}
	return col;
}
//@ 6+

// Paroi d'un logement. Mêmes arguments que office_surface(). « r » et « r2 » : deux tirages.
vec3 dwelling_surface(int face, vec2 m, vec2 extent, float soft, float r, float r2, out float fixture) {
	fixture = 0.0;
//@ 11+
	// Une pièce sur deux est à la japonaise : tatamis, plafond de bois.
	bool japanese = r2 < 0.5;
//@ 6+
	if (face == 3) {
		// Plafonnier rond, au milieu de la pièce.
		fixture = 1.0 - smoothstep(0.26 - soft, 0.26 + soft, length(m - 0.5 * extent));
//@ 11+
		if (japanese) {
			// Plafond de planches, avec une baguette tous les 45 cm.
			return vec3(0.62, 0.50, 0.36) * (1.0 - 0.3 * stripes(m.x, 0.45, 0.012, soft));
		}
//@ 6+
		return vec3(0.80, 0.79, 0.75);
	}
	if (face == 2) {
//@ 11+
		if (japanese) {
			// Tatamis : des nattes de 90 cm sur 180, bordées d'un galon sombre.
			vec2 mat_size = vec2(0.9, 1.8);
			vec2 in_mat = abs(fract(m / mat_size) - 0.5) * mat_size;
			float border = 1.0 - smoothstep(0.02, 0.02 + soft, min(0.5 * mat_size.x - in_mat.x, 0.5 * mat_size.y - in_mat.y));
			border *= 1.0 - smoothstep(0.05, 0.25, soft);
			return mix(vec3(0.60, 0.58, 0.36), vec3(0.10, 0.14, 0.10), border);
		}
//@ 6+
		// Plancher clair, des lames dans la profondeur de la pièce.
		float plank = floor(m.x / 0.11);
		return mix(vec3(0.50, 0.38, 0.24), vec3(0.60, 0.47, 0.31), pc_hash2(vec2(plank, r * 50.0)));
	}
	// Murs : un beige sable, plus ou moins chaud d'une pièce à l'autre.
	vec3 col = mix(vec3(0.80, 0.77, 0.68), vec3(0.74, 0.76, 0.70), r);
	col = mix(col, vec3(0.42, 0.33, 0.24), 1.0 - smoothstep(0.07 - soft, 0.07 + soft, m.y));
	if (face == 0) {
		// Mur du fond : un placard à portes coulissantes. Deux panneaux de papier dans un
		// cadre sombre, avec une poignée ronde chacun.
		float x = extent.x * (0.3 + 0.4 * r2);
		float closet = rect(m, vec2(x, 0.9), vec2(0.9, 0.9), soft);
		col = mix(col, vec3(0.16, 0.12, 0.09), rect(m, vec2(x, 0.9), vec2(0.93, 0.93), soft));
		vec3 paper = vec3(0.80, 0.77, 0.68);
		paper *= 1.0 - 0.6 * rect(m, vec2(x, 0.9), vec2(0.008, 0.9), soft);
		float pull = 1.0 - smoothstep(0.03, 0.03 + soft, length(vec2(abs(m.x - x) - 0.12, m.y - 0.85)));
		paper = mix(paper, vec3(0.10, 0.08, 0.07), pull);
		col = mix(col, paper, closet);
	} else {
		// Mur latéral : un calendrier.
		vec2 sheet = vec2(extent.x * (0.3 + 0.4 * r), 1.5);
		col = mix(col, vec3(0.88, 0.87, 0.84), rect(m, sheet, vec2(0.18, 0.27), soft));
		col = mix(col, vec3(0.60, 0.16, 0.14), rect(m, sheet + vec2(0.0, 0.17), vec2(0.18, 0.08), soft));
	}
	return col;
}
//@ 10+

// Paroi d'une boutique. « restaurant » : des murs de bois et des bandes de papier (le menu)
// à la place des rayonnages.
vec3 shop_surface(int face, vec2 m, vec2 extent, float soft, float r, bool restaurant, out float fixture) {
	fixture = 0.0;
	if (face == 3) {
		// Des lignes de tubes dans la profondeur, tous les 1,20 m.
		float across = abs(fract(m.x / 1.2) - 0.5) * 1.2;
		fixture = (1.0 - smoothstep(0.06, 0.06 + soft, across)) * (restaurant ? 0.35 : 1.0);
		return restaurant ? vec3(0.30, 0.22, 0.15) : vec3(0.82, 0.82, 0.80);
	}
	if (face == 2) {
		vec3 floor_col = restaurant ? vec3(0.26, 0.24, 0.22) : vec3(0.70, 0.70, 0.67);
		return floor_col * (1.0 - 0.12 * grid_lines(m, vec2(0.45), 0.004, soft));
	}
	if (restaurant) {
		// Lambris de bois, comptoir sombre, et le menu : des bandes de papier écrites à la
		// main, accrochées en rang sous le plafond.
		vec3 col = vec3(0.42, 0.28, 0.16) * (1.0 - 0.25 * stripes(m.x, 0.3, 0.006, soft));
		col = mix(col, vec3(0.12, 0.09, 0.07), rect(m, vec2(0.5 * extent.x, 0.5), vec2(0.5 * extent.x, 0.5), soft));
		float slip_x = abs(fract(m.x / 0.22) - 0.5) * 0.22;
		float slip = (1.0 - smoothstep(0.07, 0.07 + soft, slip_x)) * rect(vec2(0.0, m.y), vec2(0.0, extent.y - 0.75), vec2(1.0, 0.24), soft);
		return mix(col, vec3(0.90, 0.87, 0.78), slip);
	}
	// Rayonnages : cinq tablettes, et sur chacune des paquets de largeurs et de teintes tirées.
	float shelf_height = 0.38;
	float row = floor(m.y / shelf_height);
	float in_row = m.y - row * shelf_height;
	float box_id = floor(m.x / 0.11 + pc_hash1(row * 3.0 + 1.0) * 5.0);
	float h = pc_hash2(vec2(box_id, row + r * 40.0));
	vec3 box = mix(vec3(0.72, 0.24, 0.20), vec3(0.86, 0.76, 0.34), step(0.35, h));
	box = mix(box, vec3(0.26, 0.42, 0.66), step(0.6, h));
	box = mix(box, vec3(0.86, 0.86, 0.83), step(0.8, h));
	// De loin, les paquets se fondent en une teinte moyenne.
	box = mix(box, vec3(0.66, 0.56, 0.46), smoothstep(0.03, 0.12, soft));
	// Chaque paquet a sa hauteur ; au-dessus de lui, on voit le fond du rayonnage.
	float top = 0.20 + 0.10 * pc_rehash(h, 1.0);
	vec3 col = mix(vec3(0.80, 0.80, 0.78), box, step(0.05, in_row) * step(in_row, top));
	return mix(vec3(0.80, 0.80, 0.78), col, step(m.y, 5.0 * shelf_height));
}
//@ all

void fragment() {
	// --- 1. Coordonnées de la fenêtre -----------------------------------------
	// Ce shader part des UV, pas de la position : UV va de (0,0) en haut à gauche à (1,1)
	// en bas à droite. q est en mètres, avec l'origine en bas à gauche.
	float w = v_size.x;
	float h = v_size.y;
	vec2 q = vec2(UV.x * w, (1.0 - UV.y) * h);
	// Empreinte du pixel : la taille d'un pixel sur la fenêtre, en mètres.
	float footprint = max(fwidth(q.x), fwidth(q.y));
//@ 5
	float sill = sill_height;
//@ 6+
	// Ce qu'il y a derrière cette fenêtre, et la hauteur de son allège : la donnée de l'instance.
	int kind = int(v_custom.x + 0.5);
	float sill = v_custom.y;
//@ 5+

	// Tirages de la pièce : r0 vient de la position de la fenêtre, les autres de r0.
	float r0 = pc_hash3(v_room_key * 8.0 + vec3(seed * 17.0, seed * 5.0, seed * 3.0));
	float r1 = pc_rehash(r0, 1.0);
	float r2 = pc_rehash(r0, 2.0);
	float r3 = pc_rehash(r0, 3.0);
	float r4 = pc_rehash(r0, 4.0);
	float r5 = pc_rehash(r0, 5.0);
//@ 6+
	float r6 = pc_rehash(r0, 6.0);
//@ 5+
	float r7 = pc_rehash(r0, 7.0);
	float r8 = pc_rehash(r0, 8.0);
//@ 6+
	float r9 = pc_rehash(r0, 9.0);
//@ all

	// --- 2. Menuiserie ---------------------------------------------------------
	// Tout se joue sur une distance : « inside » est positive dans le verre, négative dans
	// l'aluminium. On part de la distance au bord du rectangle, puis on retire chaque profilé.
	float edge = min(min(q.x, w - q.x), min(q.y, h - q.y));
	// Les vantaux : deux, ou quatre si la baie est large. floor() donne le numéro du vantail
	// où se trouve le pixel, comme il donnait le numéro du carreau sur le mur.
	float sashes = w > four_sash_width ? 4.0 : 2.0;
	float sash_span = (w - 2.0 * frame_width) / sashes;
	float sash = clamp(floor((q.x - frame_width) / sash_span), 0.0, sashes - 1.0);
	float lx = (q.x - frame_width) - sash * sash_span;
	// Un vantail coulisse devant son voisin : là où ils se croisent, leurs deux montants se
	// recouvrent et on n'en voit qu'un, un peu plus large. Au milieu d'une fenêtre à quatre
	// vantaux, les deux montants se touchent sans se recouvrir.
	bool centre_joint = sashes > 3.0;
	float left_stile = (sash < 0.5 || (centre_joint && sash > 1.5 && sash < 2.5)) ? sash_width : 0.65 * sash_width;
	float right_stile = (sash > sashes - 1.5 || (centre_joint && sash > 0.5 && sash < 1.5)) ? sash_width : 0.65 * sash_width;
	// La traverse basse porte les roulettes : elle est plus haute que celle du haut.
	float y0 = frame_width + 1.6 * sash_width;
	float y1 = h - frame_width - sash_width;
	float inside = min(min(lx - left_stile, sash_span - right_stile - lx), min(q.y - y0, y1 - q.y));
	// Une porte-fenêtre a une traverse de plus, à hauteur de main.
	if (h > 1.75) {
		inside = min(inside, abs(q.y - 0.85) - 0.5 * sash_width);
	}
//@ 6+
	if (kind == KIND_CORE) {
		// Cage d'escalier : un châssis fixe, sans vantail.
		inside = edge;
	}
//@ 10+
	if (kind == KIND_SHOP) {
		// Vitrine : des glaces fixes entre des montants, un tous les 1,25 m environ.
		float panes = max(1.0, floor((w - 2.0 * frame_width) / 1.25 + 0.5));
		float pane_span = (w - 2.0 * frame_width) / panes;
		float px = mod(q.x - frame_width, pane_span);
		inside = min(min(px, pane_span - px) - 0.02, q.y - 0.09);
	} else if (kind == KIND_SHOP_DOOR) {
		// Porte de verre : un cadre, une traverse basse et une barre de poussée.
		inside = min(min(edge - 0.03, q.y - 0.16), abs(q.y - 1.0) - 0.035);
	}
//@ all
	inside = min(inside, edge - frame_width);
	// 1 sur le verre, 0 sur l'aluminium, avec un bord large d'un pixel.
	float glass_cover = pc_step(0.0, inside, footprint);
//@ 5+

	// --- 3. Un rayon dans la pièce ---------------------------------------------
	// La pièce n'existe pas : c'est une boîte imaginaire derrière la vitre. Pour chaque
	// pixel, on prolonge le regard dans cette boîte et on cherche la paroi qu'il touche.
	// Repère de la fenêtre : x vers la droite, y vers le haut, z vers l'extérieur.
	vec3 view_dir = normalize(VIEW);
	vec3 axis_z = normalize(cross(v_axis_x, v_axis_y));
	// Direction du regard, exprimée dans le repère de la fenêtre. Elle entre dans la pièce :
	// sa composante z est négative. On l'empêche d'être rasante, pour ne pas diviser par zéro.
	vec3 d = -vec3(dot(view_dir, v_axis_x), dot(view_dir, v_axis_y), dot(view_dir, axis_z));
	d.z = min(d.z, -0.03);
	d = normalize(d);
	vec3 origin = vec3(q, 0.0);

	// Dimensions de la boîte, tirées pour cette fenêtre.
	float room_w = max(w * room_width_factor * (0.85 + 0.3 * r1), w + 0.4);
	float x0 = 0.5 * w - room_w * (0.3 + 0.4 * r2);
	float x1 = x0 + room_w;
	float floor_y = -sill;
	float room_h = max(ceiling_height, h + sill + 0.15);
	float ceil_y = floor_y + room_h;
	float depth = room_depth * (0.75 + 0.5 * r3);
//@ 10+
	// Une boutique est plus profonde qu'un bureau. La troisième donnée de l'instance précise
	// ce qu'il y a derrière une vitrine ou une porte : 0, un magasin ; 1, un restaurant ; 2, le
	// hall d'entrée de l'immeuble, étroit et nu.
	bool shop = kind >= KIND_SHOP;
	bool restaurant = shop && v_custom.z > 0.5 && v_custom.z < 1.5;
	bool hall = shop && v_custom.z > 1.5;
	if (shop) {
		depth *= hall ? 0.8 : 1.5;
	}
//@ 5+

	// Distance le long du rayon jusqu'à chaque paire de parois ; la plus courte gagne.
	float tx = abs(d.x) > 0.00001 ? ((d.x > 0.0 ? x1 : x0) - origin.x) / d.x : 100000.0;
	float ty = abs(d.y) > 0.00001 ? ((d.y > 0.0 ? ceil_y : floor_y) - origin.y) / d.y : 100000.0;
	float tz = -depth / d.z;
	float t_hit = min(tx, min(ty, tz));
	vec3 hit = origin + d * t_hit;
	// Adoucissement des dessins de la pièce : au moins 8 mm, plus quand on est loin.
	float soft = max(0.008, 1.5 * footprint);

	// Quelle paroi, et où sur elle : « m » en mètres, « extent » la taille de la paroi.
	int face;
	vec2 m;
	vec2 extent;
	vec3 surface_normal;
	// Part de jour que la paroi reçoit : le sol en prend plus que le plafond.
	float sky_fill;
	if (t_hit == tz) {
		face = 0;
		m = vec2(hit.x - x0, hit.y - floor_y);
		extent = vec2(room_w, room_h);
		surface_normal = vec3(0.0, 0.0, 1.0);
		sky_fill = 0.8;
	} else if (t_hit == tx) {
		face = 1;
		m = vec2(-hit.z, hit.y - floor_y);
		extent = vec2(depth, room_h);
		surface_normal = vec3(d.x > 0.0 ? -1.0 : 1.0, 0.0, 0.0);
		sky_fill = 0.7;
	} else {
		face = d.y < 0.0 ? 2 : 3;
		m = vec2(hit.x - x0, -hit.z);
		extent = vec2(room_w, depth);
		surface_normal = vec3(0.0, d.y < 0.0 ? 1.0 : -1.0, 0.0);
		sky_fill = d.y < 0.0 ? 1.0 : 0.42;
	}

	// La couleur de la paroi : une fonction par sorte de pièce.
	float fixture;
//@ 5
	vec3 albedo = office_surface(face, m, extent, soft, r4, fixture);
//@ 6+
	vec3 albedo;
	if (kind == KIND_DWELLING) {
		albedo = dwelling_surface(face, m, extent, soft, r4, r6, fixture);
//@ 10+
	} else if (shop && !hall) {
		albedo = shop_surface(face, m, extent, soft, r4, restaurant, fixture);
//@ 6+
	} else {
		albedo = office_surface(face, m, extent, soft, r4, fixture);
	}
//@ 5+

	// --- 4. Éclairage de la pièce ------------------------------------------------
	// Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. On calcule donc sa
	// lumière ici, et on la sortira par EMISSION.
	float day = 1.0 - night;
//@ 5
	// La pièce est allumée si son tirage tombe sous la part de pièces allumées.
	float lit = step(r0, mix(office_lit_day, office_lit_night, night));
	vec3 light_tint = pc_color_in(tube_color);
//@ 6+
	// La pièce est allumée si son tirage tombe sous la part de pièces allumées. Cette part
	// dépend de l'heure et de la sorte de pièce.
	float lit_share = mix(office_lit_day, office_lit_night, night);
	vec3 light_tint = pc_color_in(tube_color);
	if (kind == KIND_DWELLING) {
		lit_share = mix(home_lit_day, home_lit_night, night);
		// Deux logements sur trois ont une lumière chaude, les autres un blanc froid.
		light_tint = r9 < 0.66 ? pc_color_in(lamp_color) : light_tint;
	} else if (kind == KIND_CORE) {
		// Un escalier reste allumé toute la nuit.
		lit_share = mix(0.3, 1.0, night);
	}
//@ 10+
	if (shop) {
		// Une boutique ouverte est éclairée en plein jour ; la nuit, certaines ont fermé. Le
		// hall d'entrée, lui, reste allumé toute la nuit.
		lit_share = hall ? mix(0.5, 1.0, night) : mix(0.95, 0.7, night);
		light_tint = restaurant ? pc_color_in(lamp_color) : light_tint;
	}
//@ 6+
	float lit = step(r0, lit_share);
//@ 5+
	// Le jour entre par la fenêtre et s'éteint avec la profondeur.
	float depth_fade = exp(hit.z / 3.4);
	vec3 day_light = vec3(0.92, 0.96, 1.0) * day * sky_fill * (0.22 + 0.78 * depth_fade) * 0.85;
	// Des tubes au plafond éclairent toute la pièce à peu près également : pas de lampe
	// ponctuelle, seulement un peu plus de lumière sur ce qui regarde vers le haut. En plein
	// jour, une pièce allumée compte peu à côté de la lumière du dehors.
	float lamp_power = lamp_energy * lit * mix(0.5, 1.0, night);
	vec3 lamp_light = light_tint * lamp_power * (0.48 + 0.3 * max(surface_normal.y, 0.0));
	vec3 moon = vec3(0.012, 0.016, 0.03) * night * (0.3 + 0.7 * depth_fade);
	vec3 interior = albedo * (day_light + lamp_light + moon);
	// Les luminaires eux-mêmes : très clairs s'ils sont allumés, gris sinon.
	interior = mix(interior, light_tint * (0.25 * day + 2.4 * lamp_power), fixture);

	// --- 5. Ce qui garnit la fenêtre -------------------------------------------------
	// Un plan de plus, 8 cm derrière la vitre : s'il est touché avant la paroi, il la cache.
	float t_dress = -0.08 / d.z;
	vec2 c = origin.xy + d.xy * t_dress;
	// Le jour éclaire les étoffes de face ; une pièce allumée les éclaire de dos.
	vec3 cloth_day = vec3(0.95, 0.97, 1.0) * day * 0.9;
	vec3 cloth_back = light_tint * lamp_power * 0.3 + moon;
//@ 5
	if (r7 < dressing && t_dress < t_hit) {
//@ 6+
	if (kind == KIND_OFFICE && r7 < dressing && t_dress < t_hit) {
//@ 5+
		// Store à lames : plus ou moins baissé, lames plus ou moins fermées, tirés par fenêtre.
		float lowered = mix(0.25, 1.0, r8);
		float cover = step(h * (1.0 - lowered), c.y);
		float pitch = 0.025;
		float closed = mix(0.4, 0.92, r5);
		float in_slat = fract(c.y / pitch);
		// De près, on voit chaque lame et le jour entre elles. De loin, une lame est plus fine
		// que le pixel : on prend la moyenne, qui est la part fermée.
		float slat_fade = 1.0 - smoothstep(0.25, 0.9, footprint / pitch);
		float body = mix(closed, step(in_slat, closed), slat_fade);
		vec3 slat = vec3(0.84, 0.84, 0.80) * (cloth_day * (0.6 + 0.35 * in_slat * slat_fade) + cloth_back);
		interior = mix(interior, slat, cover * body);
	}
//@ 6+
	if (kind == KIND_DWELLING && r7 < dressing && t_dress < t_hit) {
		// Voilage, puis rideaux tirés de chaque côté. Les plis sont deux sinusoïdes, effacées
		// quand elles deviennent plus fines que le pixel.
		float off_center = abs(c.x - 0.5 * w);
		float opening = mix(0.1, 1.0, r8 * r8);
		float sheer_phase = c.x * 71.0 + 2.0 * sin(c.y * 2.3 + r0 * 20.0);
		float sheer_folds = mix(0.5, 0.5 + 0.3 * sin(sheer_phase) + 0.2 * sin(sheer_phase * 1.63 + r1 * 30.0), 1.0 - smoothstep(0.004, 0.03, footprint));
		vec3 sheer = vec3(0.86, 0.85, 0.82) * (cloth_day * (0.7 + 0.3 * sheer_folds) + cloth_back * (0.9 + 0.5 * sheer_folds));
		interior = interior * 0.45 + sheer;
		vec3 drape_col = mix(vec3(0.62, 0.58, 0.48), vec3(0.30, 0.38, 0.42), step(0.5, r5));
		float inner_edge = (0.5 * w + 0.15) * (0.25 + 0.75 * opening);
		float fold_phase = off_center * 46.0 / (0.3 + opening) + 1.5 * sin(c.y * 1.7 + r1 * 10.0);
		float folds = mix(0.5, 0.5 + 0.32 * sin(fold_phase) + 0.18 * sin(fold_phase * 1.71 + r2 * 40.0), 1.0 - smoothstep(0.006, 0.05, footprint));
		float drape = smoothstep(inner_edge - soft, inner_edge + soft, off_center);
		interior = mix(interior, drape_col * (cloth_day * (0.66 + 0.34 * folds) + cloth_back * (0.45 + 0.55 * folds)), drape);
	}
//@ 11+
	if (kind == KIND_DWELLING && r9 > 0.72 && t_dress < t_hit) {
		// Cloisons de papier (shoji) à la place des rideaux : un quadrillage de baguettes de
		// bois sur du papier blanc. Le papier laisse passer la lumière, pas les formes : blanc
		// le jour, lumineux la nuit si la pièce est allumée.
		float from_middle = abs(c.x - 0.5 * w);
		float lattice = grid_lines(c - vec2(0.5 * w, 0.0), vec2(0.24, 0.30), 0.006, soft);
		lattice = max(lattice, 1.0 - smoothstep(0.02, 0.02 + soft, min(from_middle, abs(from_middle - 0.5 * w))));
		vec3 paper = vec3(0.90, 0.88, 0.82) * (cloth_day * 0.8 + light_tint * lamp_power * 0.75 + moon * 2.0);
		interior = mix(paper, vec3(0.20, 0.13, 0.08) * (cloth_day * 0.5 + moon), lattice);
	}
//@ 6+
	if (kind == KIND_CORE) {
		// Verre dépoli : il laisse passer la lumière, pas les formes. On ne voit qu'une lueur.
		interior = vec3(0.50, 0.54, 0.55) * (cloth_day * 0.55 + light_tint * lamp_power * 0.6 + moon * 2.0);
	}
//@ 5+

	// --- 6. Vitrage --------------------------------------------------------------
//@ 5-10
	vec3 n_glass = axis_z;
//@ 11+
	// Les deux vantaux ne sont pas dans le même rail, et aucun n'est parfaitement d'aplomb :
	// la normale de chaque vitre penche un peu à sa façon, et chacune reflète un autre
	// morceau de ciel.
	vec2 pane_seed = vec2(sash + 1.0 + r0 * 91.0, r1 * 57.0);
	vec2 tilt = (vec2(pc_hash2(pane_seed), pc_hash2(pane_seed + vec2(7.0, 3.0))) - 0.5) * 0.03;
	vec3 n_glass = normalize(axis_z + v_axis_x * tilt.x + v_axis_y * tilt.y);
//@ 5+

	// Ce que la vitre réfléchit ne la traverse pas : plus le regard est rasant, plus elle
	// renvoie le ciel et moins on voit la pièce (loi de Fresnel, forme de Schlick). f0 est la
	// même réflectance de face que celle que le moteur déduit de SPECULAR.
	float n_dot_v = clamp(dot(n_glass, view_dir), 0.0, 1.0);
	float f0 = 0.16 * reflectivity * reflectivity;
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
	// Ombre de la menuiserie sur ce qu'on voit juste derrière elle.
	float frame_shadow = mix(0.55, 1.0, smoothstep(0.0, 0.03, inside));
//@ 5-10
	vec3 transmitted = interior * pc_color_in(glass_tint) * (1.0 - fresnel) * frame_shadow;
//@ 11+

	// La saleté s'accumule dans les angles et en bas des vitres.
	float grime_noise = pc_fbm2(q * 6.0 + pane_seed, 3, footprint * 6.0);
	float grime = clamp(dirt * (0.25 + 0.75 * grime_noise) * (0.3 + 0.9 * exp(-max(inside, 0.0) / 0.035)), 0.0, 1.0);
	// Moustiquaire : une toile fine devant un des deux vantaux. Elle le grise et l'assombrit.
	float screen_side = step(0.5, r5) * (sashes - 1.0);
	float screened = (kind <= KIND_DWELLING && r2 < screens && abs(sash - screen_side) < 0.5) ? 1.0 : 0.0;
	// Verre armé : un treillis de fil en losanges, noyé dans l'épaisseur du verre. Il ne se
	// voit que de près.
	float wire = 0.0;
	if (r3 < wired && kind <= KIND_DWELLING) {
		vec2 diagonal = vec2(q.x + q.y, q.x - q.y) * 0.7071;
		wire = grid_lines(diagonal, vec2(0.022), 0.0006, 0.6 * footprint) * (1.0 - smoothstep(0.002, 0.008, footprint));
	}
	vec3 transmitted = interior * pc_color_in(glass_tint) * (1.0 - fresnel) * (1.0 - 0.75 * grime) * frame_shadow;
	transmitted *= (1.0 - 0.35 * screened) * (1.0 - 0.7 * wire);
//@ all

	// --- Menuiserie : couleur et relief --------------------------------------------
//@ 4-9
	vec3 frame_albedo = pc_color_in(frame_color);
//@ 10+
	// La couleur d'une instance arrive telle que le script l'a écrite, sans conversion.
	vec3 frame_albedo = frame_color_from_instance ? v_tint : pc_color_in(frame_color);
//@ all
	// Un filet d'ombre au ras du vitrage.
	frame_albedo *= 1.0 - 0.25 * exp(-max(-inside, 0.0) / 0.005);
	// Le profilé dépasse du verre d'un centimètre : on penche la normale au bord.
	float frame_height = 0.01 * (1.0 - pc_ramp(-0.003, 0.003, inside, 2.0 * footprint));
	vec3 n_frame = pc_bump(normalize(NORMAL), VERTEX, frame_height);

	// --- Sorties -------------------------------------------------------------------
//@ 4
	ALBEDO = pc_color_out(mix(frame_albedo, pc_color_in(glass_color), glass_cover));
	// L'aluminium anodisé est un métal satiné ; le verre est lisse.
	METALLIC = 0.6 * (1.0 - glass_cover);
	ROUGHNESS = mix(0.4, glass_roughness, glass_cover);
	// SPECULAR règle la force du reflet : fort sur le verre, ordinaire sur le métal.
	SPECULAR = mix(0.5, 0.85, glass_cover);
	NORMAL = normalize(mix(n_frame, normalize(NORMAL), glass_cover));
//@ 5-10
	// Le verre n'a plus de couleur propre : ce qu'on voit à travers sort par EMISSION, et le
	// reflet du ciel est ajouté par le moteur.
	ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.0), glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
	// L'aluminium anodisé est un métal satiné ; le verre est lisse.
	METALLIC = 0.6 * (1.0 - glass_cover);
	ROUGHNESS = mix(0.4, glass_roughness, glass_cover);
	SPECULAR = mix(0.5, reflectivity, glass_cover);
	NORMAL = normalize(mix(n_frame, n_glass, glass_cover));
//@ 6-10
	if (kind == KIND_CORE) {
		// Le verre dépoli diffuse la lumière au lieu de la réfléchir.
		ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.45, 0.48, 0.48), glass_cover));
		ROUGHNESS = mix(0.4, 0.55, glass_cover);
	}
//@ 11+
	// Le verre n'a de couleur propre que sa saleté, sa moustiquaire et son fil : ce qu'on voit
	// à travers sort par EMISSION, et le reflet du ciel est ajouté par le moteur.
	vec3 glass_albedo = vec3(0.30, 0.29, 0.27) * grime + vec3(0.16, 0.17, 0.17) * screened;
	glass_albedo = mix(glass_albedo, vec3(0.04), wire);
	ALBEDO = pc_color_out(mix(frame_albedo, glass_albedo, glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
	// L'aluminium anodisé est un métal satiné ; le verre est lisse, sauf sale ou voilé.
	METALLIC = 0.6 * (1.0 - glass_cover);
	ROUGHNESS = mix(0.4, clamp(glass_roughness + 0.45 * grime + 0.5 * screened, 0.0, 1.0), glass_cover);
	SPECULAR = mix(0.5, reflectivity * (1.0 - 0.6 * screened), glass_cover);
	NORMAL = normalize(mix(n_frame, n_glass, glass_cover));
	if (kind == KIND_CORE) {
		// Le verre dépoli diffuse la lumière au lieu de la réfléchir.
		ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.45, 0.48, 0.48), glass_cover));
		ROUGHNESS = mix(0.4, 0.55, glass_cover);
	}
//@ all
}
