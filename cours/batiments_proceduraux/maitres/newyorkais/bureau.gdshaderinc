// La pièce derrière une vitre : un bureau, ou le hall du rez-de-chaussée, sans aucune géométrie.
// {STATUS}
//
// Un fichier « .gdshaderinc » ne dessine rien : il range des fonctions et des réglages, que
// chaque shader recopie chez lui avec « #include ». Celui-ci sert à deux shaders de la tour :
// la fenêtre à guillotine de la tour de brique et le mur-rideau de la tour de verre. Jusqu'à
// l'étape 006, ce code était écrit dans le shader de la fenêtre ; il en a été sorti tel quel,
// rangé en fonctions, pour que le mur-rideau dessine les mêmes bureaux.
//
// Il vit à côté des shaders de la tour, et non avec « procedural_commun », parce qu'il ne sert
// qu'à elle. Il attend que le shader qui l'inclut ait déjà inclus « procedural_commun ».
//
// Ce qu'il fournit :
//   - rect(), stripes(), grid_lines() : les formes de base des dessins de la pièce ;
//@ 7-9
//   - office_surface(), lobby_surface() : la couleur d'une paroi de bureau, ou du hall ;
//@ 10+
//   - office_surface(), lobby_surface(), shop_surface() : la couleur d'une paroi de bureau,
//     du hall, ou d'une boutique ;
//@ all
//   - room_view() : le rayon dans la boîte imaginaire, les cloisons basses, la lumière, le
//     store. C'est la seule que les shaders appellent.

//@ 10+
// Ce qu'il y a derrière la vitre : un bureau, le hall de la tour, une boutique.
const int ROOM_OFFICE = 0;
const int ROOM_LOBBY = 1;
const int ROOM_SHOP = 2;
// Les sortes de boutiques.
const float SHOP_GROCERY = 0.0;
const float SHOP_CAFE = 1.0;
const float SHOP_STORE = 2.0;

//@ all
group_uniforms room;
/** Profondeur des bureaux au plus : 28 pieds (8,5 m) de la fenêtre au couloir dans une tour de 1916. */
uniform float room_depth : hint_range(2.0, 20.0, 0.1) = 8.5;
/** Hauteur du vide entre le faux plafond et la dalle du dessus. */
uniform float plenum : hint_range(0.0, 1.5, 0.05) = 0.6;
/** Part des fenêtres qui ont un store. */
uniform float shades : hint_range(0.0, 1.0, 0.01) = 0.55;
/** Change le tirage de toutes les pièces. */
uniform float seed = 0.0;

group_uniforms lighting;
/** 0 : jour. 1 : nuit. */
uniform float night : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Part des étages allumés, le jour puis la nuit. */
uniform float floor_lit_day : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float floor_lit_night : hint_range(0.0, 1.0, 0.01) = 0.45;
/** Teinte des luminaires des bureaux : un blanc froid. */
uniform vec3 tube_color : source_color = vec3(0.90, 0.96, 1.0);
/** Teinte des lustres du hall : un blanc chaud. */
uniform vec3 lobby_color : source_color = vec3(1.0, 0.86, 0.66);
uniform float lamp_energy : hint_range(0.0, 8.0, 0.05) = 1.6;
//@ 10+
/** Teinte des lampes chaudes : celles des cafés. */
uniform vec3 warm_color : source_color = vec3(1.0, 0.78, 0.5);
//@ 13+

group_uniforms performance;
/** Finesse du calcul. Basse : des parois d'une seule teinte. Moyenne : les parois dessinées et les stores. Haute : en plus, les cloisons basses. */
uniform int quality : hint_enum("Basse", "Moyenne", "Haute") = 2;
//@ all

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
// des luminaires : 1 sur un luminaire.
vec3 office_surface(int face, vec2 m, vec2 extent, float soft, float r, out float fixture) {
	fixture = 0.0;
	if (face == 3) {
		// Faux plafond : des dalles de 2 pieds sur 4 (0,61 × 1,22 m), et un luminaire encastré
		// de la taille d'une dalle, un toutes les quatre dalles en largeur et trois en profondeur.
		vec3 col = vec3(0.82, 0.82, 0.80) * (1.0 - 0.12 * grid_lines(m, vec2(0.61, 1.22), 0.006, soft));
		vec2 cell = vec2(2.44, 3.66);
		fixture = rect(mod(m, cell), vec2(0.61, 1.83), vec2(0.27, 0.57), soft);
		return col;
	}
	if (face == 2) {
		// Moquette en dalles de 50 cm, deux gris bleutés en damier.
		vec2 tile = floor(m / 0.5);
		return vec3(0.28, 0.30, 0.34) * (mod(tile.x + tile.y, 2.0) < 0.5 ? 1.0 : 0.9);
	}
	vec3 col = mix(vec3(0.80, 0.79, 0.75), vec3(0.72, 0.74, 0.74), r);
	// Plinthe sombre.
	col = mix(col, vec3(0.25, 0.25, 0.26), 1.0 - smoothstep(0.1 - soft, 0.1 + soft, m.y));
	if (face == 0) {
		// Mur du fond : la cloison du couloir, et sa porte de bois à vitre dépolie.
		float door_x = extent.x * (0.25 + 0.5 * r);
		float door = rect(m, vec2(door_x, 1.05), vec2(0.46, 1.05), soft);
		float pane = rect(m, vec2(door_x, 1.45), vec2(0.32, 0.45), soft);
		col = mix(col, mix(vec3(0.42, 0.29, 0.18), vec3(0.78, 0.80, 0.78), pane), door);
	} else {
		// Mur latéral : une rangée de classeurs métalliques, et un tableau au-dessus.
		float run = extent.x * (0.3 + 0.4 * r);
		float cabinet = rect(m, vec2(0.5 * run + 0.2, 0.66), vec2(0.5 * run, 0.66), soft);
		vec3 steel = vec3(0.50, 0.52, 0.50) * (1.0 - 0.3 * grid_lines(vec2(m.x - 0.2, m.y), vec2(0.46, 0.33), 0.004, soft));
		col = mix(col, steel, cabinet);
		vec2 picture = vec2(extent.x * (0.55 + 0.25 * r), 1.65);
		col = mix(col, vec3(0.20, 0.18, 0.16), rect(m, picture, vec2(0.42, 0.32), soft));
		col = mix(col, mix(vec3(0.55, 0.62, 0.66), vec3(0.72, 0.62, 0.44), r), rect(m, picture, vec2(0.38, 0.28), soft));
	}
	return col;
}

// Paroi du hall du rez-de-chaussée : murs de marbre veiné, portes d'ascenseur de bronze au
// fond, plafond à caissons et lustres, sol de marbre en damier. Mêmes arguments.
vec3 lobby_surface(int face, vec2 m, vec2 extent, float soft, out float fixture) {
	fixture = 0.0;
	if (face == 3) {
		// Caissons de 1,50 m : un creux bordé d'une moulure plus sombre. Un lustre rond au
		// milieu d'un caisson sur quatre.
		vec2 in_cell = mod(m, vec2(1.5)) - 0.75;
		float rim = 1.0 - smoothstep(0.06, 0.06 + soft, 0.75 - max(abs(in_cell.x), abs(in_cell.y)));
		vec3 col = vec3(0.86, 0.82, 0.72) * (1.0 - 0.3 * rim);
		fixture = 1.0 - smoothstep(0.24, 0.24 + soft, length(mod(m, vec2(3.0)) - 1.5));
		return col;
	}
	if (face == 2) {
		vec2 tile = floor(m / 0.6);
		return mod(tile.x + tile.y, 2.0) < 0.5 ? vec3(0.80, 0.77, 0.70) : vec3(0.36, 0.30, 0.26);
	}
	// Le marbre : un bruit étiré, seuillé en veines plus sombres.
	float vein = pc_fbm2(m * vec2(1.5, 0.6), 3, soft * 1.5);
	vec3 col = mix(vec3(0.84, 0.80, 0.72), vec3(0.66, 0.60, 0.52), smoothstep(0.5, 0.7, vein));
	if (face == 0) {
		// Au fond, les portes d'ascenseur, une tous les 2,40 m : deux vantaux de bronze.
		float x = mod(m.x, 2.4) - 1.2;
		float door = rect(vec2(x, m.y), vec2(0.0, 1.2), vec2(0.6, 1.2), soft);
		vec3 bronze = vec3(0.45, 0.32, 0.18) * (1.0 - 0.5 * (1.0 - smoothstep(0.004, 0.004 + soft, abs(x))));
		col = mix(col, bronze, door);
	}
	return col;
}
//@ 10+

// Paroi d'une boutique. « shop_type » : SHOP_GROCERY, une épicerie, rayonnages chargés de
// paquets de toutes les couleurs ; SHOP_CAFE, un café, lambris de bois, comptoir, suspensions ;
// SHOP_STORE, un magasin, murs blancs et présentoirs. Mêmes autres arguments.
vec3 shop_surface(int face, vec2 m, vec2 extent, float soft, float shop_type, float r, out float fixture) {
	fixture = 0.0;
	bool cafe = abs(shop_type - SHOP_CAFE) < 0.5;
	if (face == 3) {
		if (cafe) {
			// Plafond sombre, et une suspension ronde tous les 1,80 m.
			fixture = 1.0 - smoothstep(0.16, 0.16 + soft, length(mod(m, vec2(1.8)) - 0.9));
			return vec3(0.22, 0.17, 0.13);
		}
		// Des rangées de tubes dans la profondeur, tous les 1,20 m.
		fixture = 1.0 - smoothstep(0.06, 0.06 + soft, abs(fract(m.x / 1.2) - 0.5) * 1.2);
		return vec3(0.84, 0.84, 0.82);
	}
	if (face == 2) {
		vec3 floor_col = cafe ? vec3(0.34, 0.24, 0.15) : vec3(0.72, 0.71, 0.68);
		return floor_col * (1.0 - 0.12 * grid_lines(m, vec2(0.6), 0.004, soft));
	}
	if (cafe) {
		// Lambris de bois, un comptoir sombre au fond, et l'ardoise du menu au-dessus.
		vec3 col = vec3(0.45, 0.30, 0.17) * (1.0 - 0.25 * stripes(m.x, 0.25, 0.005, soft));
		col = mix(col, vec3(0.13, 0.09, 0.07), rect(m, vec2(0.5 * extent.x, 0.55), vec2(0.5 * extent.x, 0.55), soft) * float(face == 0));
		col = mix(col, vec3(0.08, 0.09, 0.09), rect(m, vec2(0.5 * extent.x, 1.9), vec2(0.35 * extent.x, 0.35), soft) * float(face == 0));
		return col;
	}
	if (shop_type < 0.5) {
		// Épicerie : cinq tablettes, et sur chacune des paquets de largeurs et de teintes tirées.
		float shelf = 0.38;
		float row = floor(m.y / shelf);
		float in_row = m.y - row * shelf;
		float box_id = floor(m.x / 0.11 + pc_hash1(row * 3.0 + 1.0) * 5.0);
		float hb = pc_hash2(vec2(box_id, row + r * 40.0));
		vec3 box = mix(vec3(0.75, 0.22, 0.18), vec3(0.88, 0.76, 0.30), step(0.35, hb));
		box = mix(box, vec3(0.24, 0.42, 0.68), step(0.6, hb));
		box = mix(box, vec3(0.88, 0.88, 0.85), step(0.8, hb));
		// De loin, les paquets se fondent en une teinte moyenne.
		box = mix(box, vec3(0.66, 0.56, 0.46), smoothstep(0.03, 0.12, soft));
		float top = 0.20 + 0.10 * pc_rehash(hb, 1.0);
		vec3 col = mix(vec3(0.82, 0.82, 0.80), box, step(0.05, in_row) * step(in_row, top));
		return mix(vec3(0.82, 0.82, 0.80), col, step(m.y, 5.0 * shelf));
	}
	// Magasin : des murs blancs, des niches éclairées, et dans chacune quelque chose de coloré.
	vec3 col = vec3(0.88, 0.87, 0.84);
	vec2 niche = vec2(1.2, 0.9);
	vec2 in_niche = mod(m - vec2(0.3, 0.4), niche);
	float inside = rect(in_niche, 0.5 * niche, 0.5 * niche - 0.08, soft) * step(m.y, 2.3) * step(0.4, m.y);
	vec3 goods = mix(vec3(0.30, 0.22, 0.20), vec3(0.62, 0.48, 0.36), pc_hash2(floor((m - vec2(0.3, 0.4)) / niche) + r * 13.0));
	col = mix(col, goods, inside * rect(in_niche, vec2(0.6, 0.35), vec2(0.3, 0.2), soft));
	return col;
}
//@ all

// Ce qu'on voit par un pixel de vitre : la pièce derrière elle, éclairée, avec ses cloisons
// basses et son store.
//   q, size    : le point de la vitre, en mètres depuis son coin bas gauche, et la taille de
//                la vitre ;
//   view       : la direction du regard (VIEW) ; axis_x, axis_y : les axes de la vitre, vers la
//                droite et vers le haut, dans l'espace de la caméra ;
//   room       : bords gauche et droit de la pièce, hauteur de son sol et de son plafond, dans
//                le repère de la vitre ; depth : sa profondeur ;
//@ 7-9
//   lobby      : vrai pour le hall du rez-de-chaussée ;
//@ 10+
//   room_kind  : ROOM_OFFICE, ROOM_LOBBY ou ROOM_SHOP ; shop_type : la sorte de la boutique ;
//@ all
//   r0         : le tirage de la pièce ; floor_key : son étage ;
//   footprint  : la taille d'un pixel sur la vitre, en mètres.
// « near_light » reçoit la lumière qui tombe juste derrière la vitre : de quoi éclairer ce qui
// s'y trouve (le châssis levé d'une fenêtre à guillotine).
//@ 7-9
vec3 room_view(vec2 q, vec2 size, vec3 view, vec3 axis_x, vec3 axis_y, vec4 room, float depth,
		bool lobby, float r0, float floor_key, float footprint, out vec3 near_light) {
//@ 10+
vec3 room_view(vec2 q, vec2 size, vec3 view, vec3 axis_x, vec3 axis_y, vec4 room, float depth,
		int room_kind, float shop_type, float r0, float floor_key, float footprint, out vec3 near_light) {
	bool lobby = room_kind == ROOM_LOBBY;
	bool shop = room_kind == ROOM_SHOP;
//@ all
	float r6 = pc_rehash(r0, 6.0);
	float r7 = pc_rehash(r0, 7.0);
	float r8 = pc_rehash(r0, 8.0);
	float r9 = pc_rehash(r0, 9.0);

	// --- Un rayon dans la boîte ---------------------------------------------------
	// Repère de la vitre : x vers la droite, y vers le haut, z vers l'extérieur. La direction
	// du regard y entre dans la pièce : sa composante z est négative. On l'empêche d'être
	// rasante, pour ne pas diviser par zéro.
	vec3 view_dir = normalize(view);
	vec3 axis_z = normalize(cross(axis_x, axis_y));
	vec3 d = -vec3(dot(view_dir, axis_x), dot(view_dir, axis_y), dot(view_dir, axis_z));
	d.z = min(d.z, -0.03);
	d = normalize(d);
	vec3 origin = vec3(q, 0.0);
	float x0 = room.x;
	float x1 = room.y;
	float floor_y = room.z;
	float ceil_y = room.w;

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
		extent = vec2(x1 - x0, ceil_y - floor_y);
		surface_normal = vec3(0.0, 0.0, 1.0);
		sky_fill = 0.8;
	} else if (t_hit == tx) {
		face = 1;
		m = vec2(-hit.z, hit.y - floor_y);
		extent = vec2(depth, ceil_y - floor_y);
		surface_normal = vec3(d.x > 0.0 ? -1.0 : 1.0, 0.0, 0.0);
		sky_fill = 0.7;
	} else {
		face = d.y < 0.0 ? 2 : 3;
		m = vec2(hit.x - x0, -hit.z);
		extent = vec2(x1 - x0, depth);
		surface_normal = vec3(0.0, d.y < 0.0 ? 1.0 : -1.0, 0.0);
		sky_fill = d.y < 0.0 ? 1.0 : 0.42;
	}

	// La couleur de la paroi.
	float fixture;
	vec3 albedo;
//@ 13+
	if (quality == 0) {
		// Finesse basse : une paroi d'une seule teinte, et les luminaires devinés au plafond.
		albedo = vec3(0.62, 0.62, 0.60);
		fixture = face == 3 ? 0.2 : 0.0;
	} else if (lobby) {
//@ 7-12
	if (lobby) {
//@ all
		albedo = lobby_surface(face, m, extent, soft, fixture);
//@ 10+
	} else if (shop) {
		albedo = shop_surface(face, m, extent, soft, shop_type, r6, fixture);
//@ all
	} else {
		albedo = office_surface(face, m, extent, soft, r6, fixture);
	}

	// Des cloisons basses entre les postes de travail : un plan parallèle à la vitre, haut de
	// 1,35 m, coupé d'une allée tous les 3,60 m. S'il est touché avant la paroi, il la cache.
	float t_part = -(2.2 + 1.6 * r7) / d.z;
	vec3 part_hit = origin + d * t_part;
	float part_y = part_hit.y - floor_y;
	float aisle = mod(part_hit.x - x0 + 3.6 * r8, 3.6);
//@ 7-9
	if (!lobby && t_part < t_hit && part_y > 0.0 && part_y < 1.35 && aisle > 1.2) {
//@ 10-12
	if (room_kind == ROOM_OFFICE && t_part < t_hit && part_y > 0.0 && part_y < 1.35 && aisle > 1.2) {
//@ 13+
	if (quality >= 2 && room_kind == ROOM_OFFICE && t_part < t_hit && part_y > 0.0 && part_y < 1.35 && aisle > 1.2) {
//@ all
		// Toile gris-bleu, coiffée d'une lisse d'aluminium.
		albedo = mix(vec3(0.40, 0.43, 0.48), vec3(0.70, 0.71, 0.72), step(1.30, part_y));
		fixture = 0.0;
		t_hit = t_part;
		hit = part_hit;
		surface_normal = vec3(0.0, 0.0, 1.0);
		sky_fill = 0.6;
	}

	// --- Éclairage -----------------------------------------------------------------
	// Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. On calcule donc sa
	// lumière ici ; le shader la sortira par EMISSION.
	float day = 1.0 - night;
	// Un étage entier est allumé ou éteint : la nuit, les équipes de ménage passent d'étage en
	// étage. Dans un étage allumé, presque toutes les pièces le sont ; dans un étage éteint,
	// une sur vingt.
	float floor_lit = step(pc_hash2(vec2(floor_key, 7.0 + seed)), mix(floor_lit_day, floor_lit_night, night));
	float lit = floor_lit > 0.5 ? step(r9, 0.9) : step(r9, 0.05);
	vec3 light_tint = pc_color_in(tube_color);
	if (lobby) {
		// Le hall reste allumé jour et nuit, d'une lumière chaude.
		lit = 1.0;
		light_tint = pc_color_in(lobby_color);
	}
//@ 10+
	if (shop) {
		// Une boutique ouverte est éclairée en plein jour ; la nuit, trois sur dix ont fermé.
		// Les cafés ont une lumière chaude.
		lit = step(r9, mix(0.95, 0.7, night));
		light_tint = abs(shop_type - SHOP_CAFE) < 0.5 ? pc_color_in(warm_color) : light_tint;
	}
//@ all
	// Le jour entre par la vitre et s'éteint avec la profondeur.
	float depth_fade = exp(hit.z / 3.4);
	vec3 day_light = vec3(0.92, 0.96, 1.0) * day * sky_fill * (0.22 + 0.78 * depth_fade) * 0.6;
	// Les luminaires éclairent toute la pièce à peu près également : un peu plus ce qui
	// regarde vers le haut. En plein jour, une pièce allumée compte peu à côté du dehors.
	float lamp_power = lamp_energy * lit * mix(0.5, 1.0, night);
	vec3 lamp_light = light_tint * lamp_power * (0.48 + 0.3 * max(surface_normal.y, 0.0));
	vec3 moon = vec3(0.012, 0.016, 0.03) * night * (0.3 + 0.7 * depth_fade);
	vec3 interior = albedo * (day_light + lamp_light + moon);
	// Les luminaires eux-mêmes : très clairs s'ils sont allumés, gris sinon.
	interior = mix(interior, light_tint * (0.25 * day + 2.4 * lamp_power), fixture);
	near_light = vec3(0.45) * day + light_tint * lamp_power * 0.2 + moon;

	// --- Le store --------------------------------------------------------------------
	// Une toile tendue 6 cm derrière la vitre, descendue plus ou moins bas depuis le haut : le
	// store à enrouleur. Elle laisse passer la lumière, pas les formes : le jour, elle est
	// éclairée du dehors ; la nuit, de la pièce, si la pièce est allumée.
	float t_shade = -0.06 / d.z;
	vec2 c = origin.xy + d.xy * t_shade;
//@ 7-9
	if (!lobby && pc_rehash(r0, 10.0) < shades && t_shade < t_hit) {
//@ 10-12
	if (room_kind == ROOM_OFFICE && pc_rehash(r0, 10.0) < shades && t_shade < t_hit) {
//@ 13+
	if (quality >= 1 && room_kind == ROOM_OFFICE && pc_rehash(r0, 10.0) < shades && t_shade < t_hit) {
//@ all
		// Le plus souvent, le store ne cache que le haut de la vitre.
		float low = size.y * mix(0.3, 0.95, pc_rehash(r0, 11.0));
		vec3 cloth = mix(vec3(0.88, 0.85, 0.76), vec3(0.76, 0.78, 0.74), step(0.6, pc_rehash(r0, 12.0)));
		vec3 shade_col = cloth * (vec3(0.95, 0.97, 1.0) * day * 0.6 + light_tint * lamp_power * 0.55 + moon * 2.0);
		// La barre de lestage, en bas de la toile.
		float bar = 1.0 - smoothstep(0.012, 0.012 + soft, abs(c.y - low - 0.012));
		shade_col = mix(shade_col, shade_col * 0.35, bar);
		interior = mix(interior, shade_col, step(low, c.y));
	}
	return interior;
}
