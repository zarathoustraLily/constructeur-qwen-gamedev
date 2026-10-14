// Fenêtre parisienne : un simple rectangle devient une fenêtre complète.
// {STATUS}
//
// Ce que le shader dessine :
//   - la menuiserie : dormant, deux vantaux, petits bois ;
//@ 4
//   - un vitrage sombre où le ciel se reflète.
//@ 5+ quiet
//   - le vitrage et ses reflets ;
//   - une pièce derrière la vitre, sans aucune géométrie : on prolonge le regard dans une
//     boîte imaginaire (« interior mapping »). Murs, sol, plafond, lustre allumé la nuit,
//     rideaux et voilages ;
//@ 9+ quiet
//   - des baies en arc ou ovales (lucarnes) : le reste du rectangle est découpé ;
//@ 10+ quiet
//   - une menuiserie dont la teinte peut venir de l'instance (devantures de boutique) ;
//@ 11+ quiet
//   - une pièce meublée, différente à chaque fenêtre : cheminée et miroir ou porte, tableaux,
//     tapis, parquet en point de Hongrie ; des carreaux désaxés, du verre ancien, de la saleté.
//@ all
//
// Contrairement à la pierre, ce shader part des UV : il sert sur des rectangles instanciés
// (MultiMesh), un par fenêtre, que le script pose avec MeshBuilder.panel(). Le rectangle de
// base mesure un mètre de côté ; sa taille réelle est l'échelle de son instance.
//@ 5+ quiet
// La pièce est rendue par l'émission : elle ne reçoit ni les ombres ni les lampes de la scène.
//@ all
// Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms frame;
/** Fenêtre à deux vantaux. */
uniform bool two_leaves = true;
/** Carreaux en hauteur par vantail. */
uniform int pane_rows : hint_range(1, 6) = 3;
/** Largeur des montants et des traverses. */
uniform float frame_width : hint_range(0.01, 0.2, 0.005) = 0.07;
/** Largeur du battement central, là où les deux vantaux se rejoignent. */
uniform float mullion_width : hint_range(0.01, 0.2, 0.005) = 0.085;
/** Largeur des petits bois, les baguettes entre les carreaux. */
uniform float muntin_width : hint_range(0.005, 0.08, 0.001) = 0.026;
uniform vec3 frame_color : source_color = vec3(0.86, 0.86, 0.83);
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
uniform vec3 glass_tint : source_color = vec3(0.88, 0.95, 0.92);
//@ 11+
/** Désaxement des carreaux : chacun reflète un morceau de ciel différent. */
uniform float pane_tilt : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Ondulation du verre ancien. */
uniform float waviness : hint_range(0.0, 1.0, 0.01) = 0.4;
/** Poussière et traces sur le verre. */
uniform float dirt : hint_range(0.0, 1.0, 0.01) = 0.3;
//@ 5+

group_uniforms room;
/** Profondeur moyenne de la pièce. */
uniform float room_depth : hint_range(1.0, 12.0, 0.1) = 4.5;
/** Largeur de la pièce, en largeurs de fenêtre. */
uniform float room_width_factor : hint_range(1.0, 4.0, 0.05) = 2.0;
/** Hauteur sous plafond. */
uniform float ceiling_height : hint_range(2.0, 5.0, 0.05) = 3.1;
/** Hauteur de l'allège : le sol de la pièce est plus bas que le bas de la fenêtre. */
uniform float sill_height : hint_range(0.0, 1.5, 0.01) = 0.0;
//@ 11+
/** Pièce meublée : cheminée et miroir ou porte, tableaux, tapis. Faux : murs nus (boutique, comble). */
uniform bool furnished = true;
//@ 5+
/** Part des fenêtres garnies de rideaux. */
uniform float curtains : hint_range(0.0, 1.0, 0.01) = 0.7;
/** Change le tirage de toutes les pièces. */
uniform float seed = 0.0;

group_uniforms lighting;
/** 0 : jour. 1 : nuit. */
uniform float night : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Part des pièces allumées le jour. */
uniform float lit_ratio_day : hint_range(0.0, 1.0, 0.01) = 0.06;
/** Part des pièces allumées la nuit. */
uniform float lit_ratio_night : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform vec3 lamp_color : source_color = vec3(1.0, 0.78, 0.5);
uniform float lamp_energy : hint_range(0.0, 8.0, 0.05) = 2.4;

// Teintes de mur et de rideau entre lesquelles chaque pièce tire les siennes.
const vec3 WALL_COLORS[8] = {
	vec3(0.78, 0.75, 0.68),
	vec3(0.74, 0.68, 0.54),
	vec3(0.58, 0.64, 0.63),
	vec3(0.68, 0.58, 0.50),
	vec3(0.50, 0.58, 0.50),
	vec3(0.72, 0.62, 0.36),
	vec3(0.42, 0.15, 0.13),
	vec3(0.14, 0.21, 0.32)
};
const vec3 DRAPE_COLORS[6] = {
	vec3(0.66, 0.61, 0.50),
	vec3(0.40, 0.08, 0.07),
	vec3(0.11, 0.19, 0.30),
	vec3(0.15, 0.24, 0.13),
	vec3(0.60, 0.45, 0.18),
	vec3(0.78, 0.76, 0.72)
};
//@ all

// « flat » : la valeur n'est pas fondue entre les sommets, elle est la même sur tout le
// rectangle. C'est ce qu'il faut pour une donnée propre à la fenêtre entière.
varying flat vec2 v_size;
//@ 5+
varying flat vec3 v_axis_x;
varying flat vec3 v_axis_y;
varying flat vec3 v_room_key;
//@ 9+
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
//@ 9+
	// Donnée que le script a attachée à cette instance : la forme de la baie (voir panel()).
	v_custom = INSTANCE_CUSTOM;
//@ 10+
	// Couleur que le script a donnée à cette instance : la teinte de la menuiserie.
	v_tint = COLOR.rgb;
//@ all
}
//@ 5+

// Masque d'un rectangle centré sur « center », de demi-taille « half_size », à bords adoucis
// sur « soft ». C'est la brique de tout ce qu'on dessine sur les murs de la pièce.
float rect(vec2 p, vec2 center, vec2 half_size, float soft) {
	vec2 q = abs(p - center) - half_size;
	return 1.0 - smoothstep(-soft, soft, max(q.x, q.y));
}
//@ 11+

// Parquet en point de Hongrie. f.x : largeur de la pièce, f.y : profondeur. Des bandes de
// 55 cm, et dans chaque bande des lames inclinées, un sens sur deux.
vec3 parquet(vec2 f, float soft) {
	float strip_width = 0.55;
	float plank = 0.125;
	float strip = floor(f.x / strip_width);
	float a = f.x - strip * strip_width;
	float direction = mod(strip, 2.0) < 0.5 ? 1.0 : -1.0;
	float run = (f.y + direction * a) / plank;
	float id = floor(run);
	float tone = pc_hash2(vec2(id, strip));
	vec3 col = mix(vec3(0.30, 0.18, 0.09), vec3(0.50, 0.33, 0.17), tone);
	float fr = run - id;
	float line_soft = clamp(soft / plank, 0.02, 0.5);
	float seam = smoothstep(0.0, line_soft, fr) * smoothstep(1.0, 1.0 - line_soft, fr);
	float strip_soft = max(soft, 0.006);
	float strip_seam = smoothstep(0.0, strip_soft, a) * smoothstep(strip_width, strip_width - strip_soft, a);
	// De loin, les joints des lames sont plus fins que le pixel : on les efface.
	float visible = 1.0 - smoothstep(0.03, 0.15, soft);
	return col * mix(1.0, mix(0.6, 1.0, seam * strip_seam), visible);
}
//@ 5+

// Mur de la pièce, sans mobilier. m.x : le long du mur, m.y : hauteur. Un soubassement plus
// sombre, une cimaise, une plinthe et une corniche suffisent à faire lire un mur.
vec3 wall(vec2 m, float height, vec3 base, float soft) {
	vec3 col = base;
	float low = 1.0 - smoothstep(0.92 - soft, 0.92 + soft, m.y);
	col = mix(col, base * 0.9 + 0.04, low);
	float rail = rect(vec2(0.0, m.y), vec2(0.0, 0.95), vec2(1.0, 0.03), soft);
	col = mix(col, vec3(0.80, 0.78, 0.73), rail * 0.8);
	float base_board = 1.0 - smoothstep(0.13 - soft, 0.13 + soft, m.y);
	col = mix(col, vec3(0.78, 0.76, 0.71), base_board);
	float cornice = smoothstep(height - 0.16 - soft, height - 0.16 + soft, m.y);
	col = mix(col, vec3(0.82, 0.80, 0.76), cornice);
	col *= 1.0 - 0.25 * rect(vec2(0.0, m.y), vec2(0.0, height - 0.17), vec2(1.0, 0.012), soft);
	return col;
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
//@ 5+

	// Tirages de la pièce : r0 vient de la position de la fenêtre, les autres de r0.
	float r0 = pc_hash3(v_room_key * 8.0 + vec3(seed * 17.0, seed * 5.0, seed * 3.0));
	float r1 = pc_rehash(r0, 1.0);
	float r2 = pc_rehash(r0, 2.0);
	float r3 = pc_rehash(r0, 3.0);
	float r4 = pc_rehash(r0, 4.0);
	float r5 = pc_rehash(r0, 5.0);
//@ 11+
	float r6 = pc_rehash(r0, 6.0);
//@ 5+
	float r7 = pc_rehash(r0, 7.0);
	float r8 = pc_rehash(r0, 8.0);
	float r9 = pc_rehash(r0, 9.0);
//@ all

	// --- 2. Menuiserie ---------------------------------------------------------
	// Tout se joue sur une distance : « inside » est positive dans le verre, négative dans le
	// bois. On part de la distance au bord du rectangle, puis on retire chaque pièce de bois.
	float edge = min(min(q.x, w - q.x), min(q.y, h - q.y));
//@ 9+
	// Forme de la baie : 0 rectangle, 1 arc, 2 ovale. Elle vient de l'instance. Hors de la
	// forme, le pixel est jeté : le rectangle est découpé.
	int shape = int(v_custom.x + 0.5);
	// « spring » : hauteur où l'arc prend naissance.
	float spring = h;
	if (shape == 1) {
		// v_custom.y : flèche de l'arc, en part de la demi-largeur. 1 : plein cintre.
		float rise = clamp(v_custom.y * 0.5 * w, 0.01, 0.8 * h);
		spring = h - rise;
		if (q.y > spring) {
			// Distance au bord d'une demi-ellipse posée sur la naissance de l'arc.
			vec2 from_center = vec2(q.x - 0.5 * w, q.y - spring);
			float k = length(from_center / vec2(0.5 * w, rise));
			edge = min(edge, (1.0 - k) * length(from_center) / max(k, 0.001));
		}
	} else if (shape == 2) {
		vec2 from_center = q - 0.5 * vec2(w, h);
		float k = length(from_center / (0.5 * vec2(w, h)));
		edge = (1.0 - k) * length(from_center) / max(k, 0.001);
	}
	if (edge < 0.0) {
		discard;
	}
//@ all
	// Limites du vantail où se trouve le pixel : celui de gauche ou celui de droite.
	float leaf_x0 = frame_width;
	float leaf_x1 = w - frame_width;
	if (two_leaves) {
		if (q.x < 0.5 * w) {
			leaf_x1 = 0.5 * w - 0.5 * mullion_width;
		} else {
			leaf_x0 = 0.5 * w + 0.5 * mullion_width;
		}
	}
	// La traverse basse, qui porte le jet d'eau, est plus haute que les autres.
	float y0 = frame_width * 1.6;
//@ 4-8
	float y1 = h - frame_width;
//@ 9+
	// Baie en arc : les vantaux s'arrêtent à la naissance de l'arc, sous une imposte vitrée.
	float y1 = shape == 1 ? spring - 0.5 * frame_width : h - frame_width;
//@ all
	// Carreaux : même recette que les assises de pierre, floor() donne le numéro du carreau.
	float rows = float(pane_rows);
	float pane_h = (y1 - y0) / rows;
	float cy = clamp(floor((q.y - y0) / pane_h), 0.0, rows - 1.0);
	float ly = (q.y - y0) - cy * pane_h;
	float half_muntin = 0.5 * muntin_width;
	// Distance aux quatre bords du carreau. Un petit bois n'existe qu'entre deux carreaux.
	float bottom = ly - (cy > 0.5 ? half_muntin : 0.0);
	float top = pane_h - (cy < rows - 1.5 ? half_muntin : 0.0) - ly;
	float inside = min(min(q.x - leaf_x0, leaf_x1 - q.x), min(bottom, top));
//@ 9+
	if (shape == 1 && q.y > y1) {
		// Imposte : un seul vitrage au-dessus de la traverse, partagé par le battement.
		inside = q.y - (spring + 0.5 * frame_width);
		if (two_leaves) {
			inside = min(inside, abs(q.x - 0.5 * w) - 0.5 * mullion_width);
		}
	} else if (shape == 2) {
		// Œil-de-bœuf : un cadre et une croix.
		inside = min(abs(q.x - 0.5 * w), abs(q.y - 0.5 * h)) - half_muntin;
	}
//@ all
	inside = min(inside, edge - frame_width);
	// 1 sur le verre, 0 sur le bois, avec un bord large d'un pixel.
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
	float floor_y = -sill_height;
	float room_h = max(ceiling_height, h + sill_height + 0.2);
	float ceil_y = floor_y + room_h;
	float depth = room_depth * (0.75 + 0.5 * r3);

	// Distance le long du rayon jusqu'à chaque paire de parois ; la plus courte gagne.
	float tx = abs(d.x) > 0.00001 ? ((d.x > 0.0 ? x1 : x0) - origin.x) / d.x : 100000.0;
	float ty = abs(d.y) > 0.00001 ? ((d.y > 0.0 ? ceil_y : floor_y) - origin.y) / d.y : 100000.0;
	float tz = -depth / d.z;
	float t_hit = min(tx, min(ty, tz));
	vec3 hit = origin + d * t_hit;
	// Adoucissement des dessins de la pièce : au moins 8 mm, plus quand on est loin.
	float soft = max(0.008, 1.5 * footprint);

	vec3 base_wall = WALL_COLORS[int(clamp(floor(r4 * 8.0), 0.0, 7.0))];
	vec3 lamp_pos = vec3(0.5 * (x0 + x1), ceil_y - 0.6, -0.5 * depth);
	vec3 albedo;
	vec3 surface_normal;
	// Part de jour que la paroi reçoit : le sol en prend plus que le plafond.
	float sky_fill;
	if (t_hit == tz) {
		// Mur du fond.
		vec2 m = vec2(hit.x - x0, hit.y - floor_y);
		albedo = wall(m, room_h, base_wall, soft);
		surface_normal = vec3(0.0, 0.0, 1.0);
		sky_fill = 0.8;
//@ 11+
		// Sur le mur du fond : une cheminée et son miroir, ou une porte à deux vantaux.
		float feature_x = room_w * (0.3 + 0.4 * r5);
		if (furnished && r6 < 0.55) {
			vec3 marble = mix(vec3(0.72, 0.70, 0.66), vec3(0.20, 0.07, 0.06), step(0.7, r7));
			marble *= 0.9 + 0.2 * pc_fbm2(m * 7.0 + r0 * 30.0, 3, soft * 7.0);
			float mantel = rect(m, vec2(feature_x, 0.56), vec2(0.68, 0.56), soft);
			albedo = mix(albedo, marble, mantel);
			float hearth = rect(m, vec2(feature_x, 0.38), vec2(0.36, 0.38), soft);
			albedo = mix(albedo, vec3(0.015), hearth);
			float mirror_top = min(2.55, room_h - 0.45);
			vec2 mirror_center = vec2(feature_x, 0.5 * (1.2 + mirror_top));
			vec2 mirror_half = vec2(0.5, 0.5 * (mirror_top - 1.2));
			float gilt = rect(m, mirror_center, mirror_half + 0.07, soft);
			albedo = mix(albedo, vec3(0.55, 0.38, 0.12), gilt);
			float mirror = rect(m, mirror_center, mirror_half, soft);
			// Le miroir renvoie la fenêtre : une tache claire sur fond de pièce.
			float glow = rect(m, vec2(feature_x + (0.5 - r5) * 0.6, mirror_center.y + 0.1), vec2(0.2, mirror_half.y * 0.75), 0.08);
			albedo = mix(albedo, mix(base_wall * 0.55, vec3(1.3, 1.35, 1.4), glow), mirror);
		} else if (furnished) {
			float door = rect(m, vec2(feature_x, 1.12), vec2(0.72, 1.12), soft);
			vec3 door_col = vec3(0.76, 0.74, 0.69);
			float panel = rect(vec2(abs(m.x - feature_x), m.y), vec2(0.36, 1.45), vec2(0.24, 0.55), soft)
					+ rect(vec2(abs(m.x - feature_x), m.y), vec2(0.36, 0.45), vec2(0.24, 0.3), soft);
			door_col *= 1.0 - 0.14 * clamp(panel, 0.0, 1.0);
			door_col *= 1.0 - 0.5 * rect(m, vec2(feature_x, 1.12), vec2(0.008, 1.12), soft);
			albedo = mix(albedo, door_col, door);
		}
//@ 5+
	} else if (t_hit == tx) {
		// Murs latéraux.
		vec2 m = vec2(-hit.z, hit.y - floor_y);
		albedo = wall(m, room_h, base_wall, soft);
		surface_normal = vec3(d.x > 0.0 ? -1.0 : 1.0, 0.0, 0.0);
		sky_fill = 0.7;
//@ 11+
		// Sur chaque mur latéral : un tableau encadré, à une place et d'une taille tirées.
		float side = d.x > 0.0 ? 1.0 : 0.0;
		float pr = pc_rehash(r0, 11.0 + side);
		vec2 picture_center = vec2(depth * (0.3 + 0.4 * pr), 1.65);
		vec2 picture_half = vec2(0.28 + 0.3 * pc_rehash(r0, 13.0 + side), 0.22 + 0.25 * pr);
		if (furnished) {
			float gilt = rect(m, picture_center, picture_half + 0.045, soft);
			albedo = mix(albedo, vec3(0.42, 0.29, 0.10), gilt);
			float canvas = rect(m, picture_center, picture_half, soft);
			vec3 paint_col = mix(vec3(0.12, 0.16, 0.14), vec3(0.50, 0.40, 0.26), pc_fbm2(m * 3.0 + pr * 40.0, 3, soft * 3.0));
			albedo = mix(albedo, paint_col, canvas);
		}
//@ 5+
	} else if (d.y < 0.0) {
//@ 5-10
		// Sol : un parquet, des lames dans la profondeur de la pièce.
		float plank = floor((hit.x - x0) / 0.12);
		albedo = mix(vec3(0.30, 0.18, 0.09), vec3(0.50, 0.33, 0.17), pc_hash2(vec2(plank, r0 * 50.0)));
		surface_normal = vec3(0.0, 1.0, 0.0);
		sky_fill = 1.0;
//@ 11+
		// Sol : parquet en point de Hongrie et, parfois, un tapis.
		vec2 f = vec2(hit.x - x0, -hit.z);
		albedo = parquet(f, soft);
		surface_normal = vec3(0.0, 1.0, 0.0);
		sky_fill = 1.0;
		if (furnished && r8 < 0.6) {
			vec2 rug_center = vec2(0.5 * room_w, 0.55 * depth);
			vec2 rug_half = vec2(0.32 * room_w, 0.28 * depth);
			float rug = rect(f, rug_center, rug_half, soft);
			vec3 rug_col = mix(vec3(0.33, 0.07, 0.06), vec3(0.09, 0.13, 0.22), step(0.5, r9));
			float border = rug - rect(f, rug_center, rug_half - 0.16, soft);
			rug_col = mix(rug_col, vec3(0.55, 0.45, 0.28), clamp(border, 0.0, 1.0) * 0.7);
			albedo = mix(albedo, rug_col, rug);
		}
//@ 5+
	} else {
//@ 5-10
		// Plafond.
		albedo = vec3(0.80, 0.79, 0.76);
//@ 11+
		// Plafond : blanc, avec une rosace autour du lustre.
		vec2 c = vec2(hit.x - lamp_pos.x, hit.z - lamp_pos.z);
		albedo = vec3(0.80, 0.79, 0.76);
		float rosette = smoothstep(0.42 + soft, 0.42 - soft, length(c));
		albedo *= 1.0 - 0.08 * rosette * (0.5 + 0.5 * sin(length(c) * 60.0));
//@ 5+
		surface_normal = vec3(0.0, -1.0, 0.0);
		sky_fill = 0.42;
	}

	// --- 4. Éclairage de la pièce ------------------------------------------------
	// Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. On calcule donc sa
	// lumière ici, et on la sortira par EMISSION.
	vec3 lamp_tint = pc_color_in(lamp_color);
	// La pièce est allumée si son tirage tombe sous la part de pièces allumées.
	float lit = step(r0, mix(lit_ratio_day, lit_ratio_night, night));
	float day = 1.0 - night;
	// Le jour entre par la fenêtre et s'éteint avec la profondeur.
	float depth_fade = exp(hit.z / 3.4);
	vec3 day_light = vec3(0.92, 0.96, 1.0) * day * sky_fill * (0.22 + 0.78 * depth_fade) * 0.85;
	vec3 to_lamp = lamp_pos - hit;
	float lamp_dist = length(to_lamp);
	float lambert = max(dot(surface_normal, to_lamp / max(lamp_dist, 0.001)), 0.0);
	// En plein jour, une lampe allumée compte peu à côté de la lumière du dehors.
	float lamp_power = lamp_energy * lit * mix(0.45, 1.0, night);
	vec3 lamp_light = lamp_tint * lamp_power * (lambert + 0.22) / (1.0 + 0.3 * lamp_dist * lamp_dist);
	vec3 moon = vec3(0.012, 0.016, 0.03) * night * (0.3 + 0.7 * depth_fade);
	vec3 interior = albedo * (day_light + lamp_light + moon);

	// Lustre : un halo, si le rayon passe près de la lampe avant de toucher une paroi.
	float t_lamp = dot(lamp_pos - origin, d);
	if (t_lamp > 0.0 && t_lamp < t_hit) {
		float miss = length(origin + d * t_lamp - lamp_pos);
		float bulb = exp(-miss * miss / 0.012) + 0.25 * exp(-miss * miss / 0.09);
		interior += lamp_tint * (lamp_power * 1.4 + 0.02 * day) * bulb;
	}

	// --- 5. Rideaux et voilages ---------------------------------------------------
	// Un plan de plus, 12 cm derrière la vitre : s'il est touché avant la paroi, il la cache.
	float t_curtain = -0.12 / d.z;
	if (r7 < curtains && t_curtain < t_hit) {
		vec2 c = origin.xy + d.xy * t_curtain;
		float center_x = 0.5 * w;
		float rod_half = 0.5 * w + 0.22;
		// Ouverture des rideaux, tirée par fenêtre : de presque fermés à grands ouverts.
		float opening = mix(0.12, 1.0, r8 * r8);
		float sway = 0.07 * (1.0 - opening) * sin(clamp((c.y - floor_y) / room_h, 0.0, 1.0) * 3.14159);
		float inner_edge = rod_half * (0.22 + 0.78 * opening) - sway;
		float off_center = abs(c.x - center_x);
		float in_height = step(floor_y, c.y) * step(c.y, ceil_y - 0.12);
		// Le jour éclaire les étoffes de face ; une pièce allumée les éclaire de dos.
		vec3 cloth_day = vec3(0.95, 0.97, 1.0) * day * 0.9;
		vec3 cloth_back = lamp_tint * lamp_power * 0.2 + moon;

		// Voilage : il couvre l'ouverture, parfois seulement le bas (brise-bise). Il voile ce
		// qui est derrière lui et renvoie le jour : blanc de jour, lumineux la nuit.
		if (r9 < 0.7) {
			float sheer_top = r9 < 0.25 ? floor_y + sill_height + 0.48 * h : ceil_y - 0.12;
			float sheer_phase = c.x * 71.0 + 2.0 * sin(c.y * 2.3 + r0 * 20.0);
			float sheer_folds = 0.5 + 0.3 * sin(sheer_phase) + 0.2 * sin(sheer_phase * 1.63 + r1 * 30.0);
			float sheer_fade = 1.0 - smoothstep(0.004, 0.03, footprint);
			sheer_folds = mix(0.5, sheer_folds, sheer_fade);
			float sheer_cover = step(off_center, inner_edge) * in_height
					* (1.0 - smoothstep(sheer_top - 0.01, sheer_top + 0.01, c.y));
			vec3 sheer = vec3(0.86, 0.85, 0.82) * (cloth_day * (0.7 + 0.3 * sheer_folds) + cloth_back * (0.9 + 0.5 * sheer_folds));
			interior = mix(interior, interior * 0.45 + sheer, sheer_cover);
		}

		// Rideaux lourds, tirés de chaque côté. De jour on en voit l'envers, souvent doublé
		// d'une toile claire ; la nuit, l'étoffe éclairée par la pièce. Les plis sont deux
		// sinusoïdes, effacées quand elles deviennent plus fines que le pixel.
		vec3 drape_col = DRAPE_COLORS[int(clamp(floor(r5 * 6.0), 0.0, 5.0))];
		vec3 lining = pc_rehash(r0, 15.0) < 0.6 ? vec3(0.80, 0.77, 0.70) : drape_col;
		float fold_phase = off_center * 46.0 / (0.3 + opening) + 1.5 * sin(c.y * 1.7 + r1 * 10.0);
		float folds = 0.5 + 0.32 * sin(fold_phase) + 0.18 * sin(fold_phase * 1.71 + r2 * 40.0);
		float fold_fade = 1.0 - smoothstep(0.006, 0.05, footprint);
		folds = mix(0.5, folds, fold_fade);
		float drape = smoothstep(inner_edge - soft, inner_edge + soft, off_center) * in_height;
		vec3 drape_light = lining * cloth_day * (0.66 + 0.34 * folds) + drape_col * cloth_back * (0.45 + 0.55 * folds);
		interior = mix(interior, drape_light, drape);
	}

	// --- 6. Vitrage --------------------------------------------------------------
//@ 5-10
	vec3 n_glass = axis_z;
//@ 11+
	// Numéro du carreau dans la fenêtre : (vantail, rang). L'imposte d'une baie en arc et les
	// quatre quartiers d'un œil-de-bœuf ont le leur.
	float leaf = (two_leaves && q.x >= 0.5 * w) ? 1.0 : 0.0;
	vec2 pane_id = vec2(leaf + 1.0, cy + 1.0);
	if (shape == 1 && q.y > y1) {
		pane_id = vec2(leaf + 1.0, rows + 1.0);
	} else if (shape == 2) {
		pane_id = vec2(step(0.5 * w, q.x) + 1.0, step(0.5 * h, q.y) + 1.0);
	}
	// Chaque carreau est posé un peu de travers, et le verre ancien ondule : la normale du
	// vitrage n'est pas tout à fait celle du rectangle, et chaque carreau reflète un morceau
	// de ciel différent.
	vec2 pane_seed = pane_id + vec2(r0 * 91.0, r1 * 57.0);
	vec2 tilt = (vec2(pc_hash2(pane_seed), pc_hash2(pane_seed + vec2(7.0, 3.0))) - 0.5) * 0.035 * pane_tilt;
	vec2 wave = (vec2(pc_noise2(q * 3.2 + pane_seed), pc_noise2(q * 3.2 + pane_seed + vec2(19.0, 43.0))) - 0.5) * 0.022 * waviness;
	vec3 n_glass = normalize(axis_z + v_axis_x * (tilt.x + wave.x) + v_axis_y * (tilt.y + wave.y));
//@ 5+

	// Ce que la vitre réfléchit ne la traverse pas : plus le regard est rasant, plus elle
	// renvoie le ciel et moins on voit la pièce (loi de Fresnel, forme de Schlick). f0 est la
	// même réflectance de face que celle que le moteur déduit de SPECULAR.
	float n_dot_v = clamp(dot(n_glass, view_dir), 0.0, 1.0);
	float f0 = 0.16 * reflectivity * reflectivity;
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
//@ 11+

	// La saleté s'accumule dans les angles et en bas des carreaux.
	float grime_noise = pc_fbm2(q * 6.0 + pane_seed, 4, footprint * 6.0);
	float corner_grime = exp(-max(inside, 0.0) / 0.035);
	float grime = clamp(dirt * (0.25 + 0.75 * grime_noise) * (0.3 + 0.9 * corner_grime), 0.0, 1.0);
//@ 5+
	// Ombre de la menuiserie sur ce qu'on voit juste derrière elle.
	float frame_shadow = mix(0.55, 1.0, smoothstep(0.0, 0.035, inside));
//@ 5-10
	vec3 transmitted = interior * pc_color_in(glass_tint) * (1.0 - fresnel) * frame_shadow;
//@ 11+
	vec3 transmitted = interior * pc_color_in(glass_tint) * (1.0 - fresnel) * (1.0 - 0.75 * grime) * frame_shadow;
//@ all

	// --- Menuiserie : couleur et relief --------------------------------------------
//@ 4-9
	vec3 frame_albedo = pc_color_in(frame_color);
//@ 10
	// La couleur d'une instance arrive telle que le script l'a écrite, sans conversion.
	vec3 frame_albedo = frame_color_from_instance ? v_tint : pc_color_in(frame_color);
//@ 11+
	// La couleur d'une instance arrive telle que le script l'a écrite, sans conversion.
	vec3 frame_base = frame_color_from_instance ? v_tint : pc_color_in(frame_color);
	// Une peinture jamais tout à fait unie.
	float frame_grime = pc_fbm2(q * 9.0 + 3.0, 3, footprint * 9.0);
	vec3 frame_albedo = frame_base * (0.9 + 0.12 * frame_grime);
//@ all
	// Un filet d'ombre au ras du vitrage.
	frame_albedo *= 1.0 - 0.25 * exp(-max(-inside, 0.0) / 0.006);
	// Le bois dépasse du verre d'un bon centimètre : on penche la normale au bord.
	float frame_height = 0.012 * (1.0 - pc_ramp(-0.004, 0.004, inside, 2.0 * footprint));
	vec3 n_frame = pc_bump(normalize(NORMAL), VERTEX, frame_height);

	// --- Sorties -------------------------------------------------------------------
//@ 4
	ALBEDO = pc_color_out(mix(frame_albedo, pc_color_in(glass_color), glass_cover));
	ROUGHNESS = mix(0.45, glass_roughness, glass_cover);
	// SPECULAR règle la force du reflet : fort sur le verre, ordinaire sur le bois peint.
	SPECULAR = mix(0.5, 0.85, glass_cover);
	NORMAL = normalize(mix(n_frame, normalize(NORMAL), glass_cover));
//@ 5-10
	// Le verre n'a plus de couleur propre : ce qu'on voit à travers sort par EMISSION, et le
	// reflet du ciel est ajouté par le moteur.
	ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.0), glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
	ROUGHNESS = mix(0.45, glass_roughness, glass_cover);
	SPECULAR = mix(0.5, reflectivity, glass_cover);
	NORMAL = normalize(mix(n_frame, n_glass, glass_cover));
//@ 11+
	// Le verre n'a de couleur propre que sa saleté : ce qu'on voit à travers sort par
	// EMISSION, et le reflet du ciel est ajouté par le moteur. Un verre sale est moins lisse.
	ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.30, 0.29, 0.27) * grime, glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
	ROUGHNESS = mix(0.45, clamp(glass_roughness + 0.45 * grime, 0.0, 1.0), glass_cover);
	SPECULAR = mix(0.5, reflectivity, glass_cover);
	NORMAL = normalize(mix(n_frame, n_glass, glass_cover));
//@ all
}
