// Fenêtre à guillotine : un simple rectangle devient une fenêtre complète.
// {STATUS}
//
// Ce que le shader dessine :
//   - le dormant, et deux châssis : celui du haut est fixe, celui du bas glisse vers le haut,
//     derrière lui. C'est la fenêtre à guillotine (« double-hung window »), celle qu'on voit
//     sur les tours de brique de New York ;
//   - des petits bois qui partagent chaque châssis en carreaux ;
//   - le châssis du bas plus ou moins levé d'une fenêtre à l'autre : sous lui, la baie est
//     ouverte, sans vitre ;
//@ 4
//   - un vitrage sombre où le ciel se reflète.
//@ 5+ quiet
//   - le vitrage et ses reflets ;
//   - une pièce derrière la vitre, sans aucune géométrie : on prolonge le regard dans une
//     boîte imaginaire (« interior mapping »). Un bureau : faux plafond de dalles et de
//     luminaires, moquette, cloisons basses, porte vitrée sur le couloir ;
//   - un store à enrouleur, plus ou moins descendu ;
//   - la nuit, des étages entiers allumés, d'autres éteints ;
//@ 6+ quiet
//   - derrière les grandes baies du rez-de-chaussée, le hall : marbre, portes d'ascenseur de
//     bronze, lustres, allumé jour et nuit. Le script dit quelle pièce dessiner, fenêtre par
//     fenêtre, par une donnée attachée à l'instance ;
//@ 10+ quiet
//   - les vitres du rez-de-chaussée : vitrines dans un cadre mince, portes vitrées, verre sans
//     cadre des portes tambour ; derrière, une boutique ou le hall ;
//@ all
//
// Comme les fenêtres de Paris et de Tokyo, et contrairement à la brique, ce shader part des
// UV : il sert sur des rectangles instanciés (MultiMesh), un par fenêtre, que le script pose
// avec MeshBuilder.panel(). Le rectangle de base mesure un mètre de côté ; sa taille réelle
// est l'échelle de son instance.
//@ 5+ quiet
// La pièce est rendue par l'émission : elle ne reçoit ni les ombres ni les lampes de la scène.
//@ all
// Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"
//@ 7+
// La pièce derrière la vitre, ses réglages et ses lumières : rangés dans un fichier partagé
// avec le mur-rideau de la tour de verre.
#include "{SHADER}_bureau.gdshaderinc"
//@ 6+

// Ce qu'il y a derrière la fenêtre. Le script l'écrit dans la donnée de l'instance.
const int KIND_OFFICE = 0;
const int KIND_LOBBY = 1;
//@ 10+
const int KIND_SHOP = 2;
const int KIND_SHOP_DOOR = 3;
const int KIND_DOOR_GLASS = 4;
//@ all

group_uniforms frame;
/** Largeur du dormant : le cadre fixé dans la baie. */
uniform float frame_width : hint_range(0.01, 0.15, 0.005) = 0.05;
/** Largeur des montants des châssis. */
uniform float stile_width : hint_range(0.01, 0.12, 0.005) = 0.045;
/** Hauteur de la traverse haute du châssis du haut, puis de la traverse basse du châssis du bas. */
uniform float top_rail : hint_range(0.01, 0.15, 0.005) = 0.05;
uniform float bottom_rail : hint_range(0.01, 0.2, 0.005) = 0.075;
/** Hauteur des traverses de rencontre, là où les deux châssis se croisent. */
uniform float meeting_rail : hint_range(0.01, 0.1, 0.005) = 0.035;
/** Largeur des petits bois. */
uniform float muntin_width : hint_range(0.005, 0.05, 0.001) = 0.018;
/** Carreaux du châssis du haut, puis du bas : colonnes et rangées. 1 × 1 : une seule vitre. */
uniform ivec2 upper_lights = ivec2(1, 1);
uniform ivec2 lower_lights = ivec2(1, 1);
uniform vec3 frame_color : source_color = vec3(0.16, 0.17, 0.15);
/** Part des fenêtres ouvertes : leur châssis du bas est levé. */
uniform float open_share : hint_range(0.0, 1.0, 0.01) = 0.15;

group_uniforms glass;
uniform float glass_roughness : hint_range(0.0, 0.5, 0.005) = 0.04;
//@ 4
/** Teinte du vitrage tant qu'on ne voit rien derrière : sombre, pour que le ciel s'y reflète. */
uniform vec3 glass_color : source_color = vec3(0.07, 0.09, 0.11);
//@ 5+
/** Force des reflets. 0.5 : vitrage neuf. 1 : reflets marqués. */
uniform float reflectivity : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform vec3 glass_tint : source_color = vec3(0.88, 0.93, 0.91);

group_uniforms storey;
/** Hauteur d'un étage, hauteur de l'allège, largeur d'une travée : le script les donne. */
uniform float floor_height : hint_range(2.5, 6.0, 0.01) = 3.66;
uniform float sill_height : hint_range(0.0, 1.5, 0.01) = 0.85;
uniform float bay_width : hint_range(1.0, 4.0, 0.01) = 2.0;
//@ 6+
/** Hauteur du rez-de-chaussée et de son allège : pour le hall. */
uniform float ground_height : hint_range(3.0, 9.0, 0.01) = 5.5;
uniform float ground_sill : hint_range(0.0, 1.5, 0.01) = 0.6;
//@ 5-6

group_uniforms room;
/** Profondeur des bureaux au plus : 28 pieds (8,5 m) de la fenêtre au couloir. */
uniform float room_depth : hint_range(2.0, 15.0, 0.1) = 8.5;
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
/** Teinte des luminaires : un blanc froid. */
uniform vec3 tube_color : source_color = vec3(0.90, 0.96, 1.0);
//@ 6
/** Teinte des lustres du hall : un blanc chaud. */
uniform vec3 lobby_color : source_color = vec3(1.0, 0.86, 0.66);
//@ 5-6
uniform float lamp_energy : hint_range(0.0, 8.0, 0.05) = 1.6;
//@ all

// « flat » : la valeur n'est pas fondue entre les sommets, elle est la même sur tout le
// rectangle. C'est ce qu'il faut pour une donnée propre à la fenêtre entière.
varying flat vec2 v_size;
varying flat vec3 v_key;
//@ 5+
varying flat vec3 v_axis_x;
varying flat vec3 v_axis_y;
//@ 6+
varying flat float v_kind;
//@ 10+
varying flat float v_bottom;
//@ all

void vertex() {
	// Le rectangle est un carré d'un mètre de côté, mis à l'échelle par son instance : la
	// longueur des deux premiers axes de sa matrice est sa taille en mètres. Dans un
	// MultiMesh, MODEL_MATRIX est la matrice de l'instance.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
//@ 4-5
	// La position de la fenêtre sert de clé de tirage : chaque fenêtre aura les siens.
	v_key = MODEL_MATRIX[3].xyz;
//@ 6+
	// Donnée que le script a attachée à cette instance (voir panel()) : x, ce qu'il y a derrière
	// la fenêtre ; y, son étage ; z, sa colonne sur la façade ; w, la façade. Les trois
	// derniers sont des nombres entiers : ils font une clé de tirage exacte, qui ne dépend pas
	// de la position de la fenêtre au millimètre près.
	v_kind = INSTANCE_CUSTOM.x;
	v_key = INSTANCE_CUSTOM.yzw;
//@ 10+
	// Le bas de la vitre au-dessus du sol : le sol d'une boutique est celui de la rue. La tour
	// est posée au sol, à y = 0.
	v_bottom = MODEL_MATRIX[3].y - 0.5 * v_size.y;
//@ 6+
//@ 5+
	// Les axes de la fenêtre (vers la droite, vers le haut), amenés dans l'espace de la caméra.
	v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
	v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
//@ all
}

// Distance signée au bois d'un châssis : positive dans un carreau, négative sur le bois.
// « box » : bords gauche, droit, bas et haut du châssis ; « rail_low » et « rail_high » :
// hauteurs de ses traverses basse et haute ; « lights » : ses carreaux, en colonnes et rangées.
float sash_glass(vec2 q, vec4 box, float rail_low, float rail_high, ivec2 lights) {
	vec2 g0 = vec2(box.x + stile_width, box.z + rail_low);
	vec2 g1 = vec2(box.y - stile_width, box.w - rail_high);
	float inside = min(min(q.x - g0.x, g1.x - q.x), min(q.y - g0.y, g1.y - q.y));
	// Les petits bois : des lignes régulières entre les carreaux. On mesure la distance à la
	// plus proche ; floor() donne son numéro, comme celui d'une brique dans son assise.
	vec2 cell = (g1 - g0) / vec2(lights);
	if (lights.x > 1) {
		float k = clamp(floor((q.x - g0.x) / cell.x + 0.5), 1.0, float(lights.x - 1));
		inside = min(inside, abs(q.x - g0.x - k * cell.x) - 0.5 * muntin_width);
	}
	if (lights.y > 1) {
		float k = clamp(floor((q.y - g0.y) / cell.y + 0.5), 1.0, float(lights.y - 1));
		inside = min(inside, abs(q.y - g0.y - k * cell.y) - 0.5 * muntin_width);
	}
	return inside;
}
//@ 5-6

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
//@ 6

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
	// Tirages de la fenêtre : r0 vient de sa clé, les autres de r0.
//@ 4-5
	float r0 = pc_hash3(v_key * 8.0);
//@ 6+
	int kind = int(v_kind + 0.5);
	// Une pièce s'étend sur une, deux ou trois travées ; sur un même étage d'une même façade,
	// toutes les pièces ont la même largeur. « room_id » : le numéro de la pièce le long de
	// l'étage ; « place » : celui de la fenêtre dans sa pièce.
//@ 6-10
	float span = 1.0 + floor(pc_hash2(vec2(v_key.x, v_key.z * 31.0 + 5.0)) * 3.0);
	float room_id = floor(v_key.y / span);
	float place = v_key.y - room_id * span;
	// Deux tirages : celui de la pièce (r0), pour ce qui lui appartient (sa profondeur, sa
	// lumière, son store), et celui de la fenêtre (rw), pour son châssis levé.
	float r0 = pc_hash3(vec3(v_key.x, room_id, v_key.z + 17.0));
	float rw = pc_hash3(v_key + vec3(0.0, 0.0, 57.0));
//@ 11+
	// La graine de la tour entre dans chaque clé : deux tours n'ont pas les mêmes pièces.
	float span = 1.0 + floor(pc_hash2(vec2(v_key.x, v_key.z * 31.0 + 5.0 + seed * 97.0)) * 3.0);
	float room_id = floor(v_key.y / span);
	float place = v_key.y - room_id * span;
	// Deux tirages : celui de la pièce (r0), pour ce qui lui appartient (sa profondeur, sa
	// lumière, son store), et celui de la fenêtre (rw), pour son châssis levé.
	float r0 = pc_hash3(vec3(v_key.x, room_id, v_key.z + 17.0 + seed * 101.0));
	float rw = pc_hash3(v_key + vec3(0.0, 0.0, 57.0 + seed * 101.0));
//@ 6+
//@ 4-5
	float r1 = pc_rehash(r0, 1.0);
	float r2 = pc_rehash(r0, 2.0);
//@ 6+
	float r1 = pc_rehash(rw, 1.0);
	float r2 = pc_rehash(rw, 2.0);
//@ 5+
	float r3 = pc_rehash(r0, 3.0);
//@ 5
	float r4 = pc_rehash(r0, 4.0);
	float r5 = pc_rehash(r0, 5.0);
//@ 5-6
	float r6 = pc_rehash(r0, 6.0);
	float r7 = pc_rehash(r0, 7.0);
	float r8 = pc_rehash(r0, 8.0);
	float r9 = pc_rehash(r0, 9.0);
//@ all

	// --- 2. Les deux châssis -------------------------------------------------------
	// Ils se rencontrent au milieu de la baie. Celui du haut est fixe, côté rue ; celui du bas
	// glisse vers le haut, derrière lui. « lift » : de combien il est levé (0 : fermé).
	float mid = 0.5 * h;
	float lift = r1 < open_share ? mix(0.08, 0.45, r2) * (mid - frame_width) : 0.0;
	// Les deux châssis : bords gauche, droit, bas et haut.
	vec4 upper_box = vec4(frame_width, w - frame_width, mid - meeting_rail, h - frame_width);
	vec4 lower_box = vec4(frame_width, w - frame_width, frame_width + lift, mid + lift);
	// Tout se joue sur une distance : positive dans le verre, négative sur le bois.
	float upper_in = sash_glass(q, upper_box, meeting_rail, top_rail, upper_lights);
	float lower_in = sash_glass(q, lower_box, bottom_rail, meeting_rail, lower_lights);
	// Où est le pixel : devant le châssis du haut ? Là où passe celui du bas ? Sous le châssis
	// du bas levé, il n'y a ni bois ni vitre : la baie est ouverte.
	bool in_upper = q.y >= upper_box.z;
	bool in_lower = q.y >= lower_box.z && q.y <= lower_box.w;
	// Ce qu'on voit en premier : le bois ou la vitre du châssis de devant, sinon le vide.
	float front = in_upper ? upper_in : (in_lower ? lower_in : 1.0);
	// Le dormant, tout autour : le cadre fixé dans la baie.
	float edge = min(min(q.x, w - q.x), min(q.y, h - q.y));
	front = min(front, edge - frame_width);
	// 1 sur la vitre (ou le vide), 0 sur le bois, avec un bord large d'un pixel.
	float glass_cover = pc_step(0.0, front, footprint);
	// Derrière la vitre du haut passe le châssis du bas, s'il est levé : son bois se voit à
	// travers ; ailleurs, on regarde à travers deux vitres.
	float wood_behind = (in_upper && in_lower) ? 1.0 - pc_step(0.0, lower_in, footprint) : 0.0;
	float double_glass = (in_upper && in_lower) ? 1.0 - wood_behind : 0.0;
	float open_cover = (!in_upper && !in_lower) ? glass_cover : 0.0;
//@ 10+
	if (kind >= KIND_SHOP) {
		// Les vitres du rez-de-chaussée n'ont pas de châssis à guillotine. La vitrine : une glace
		// fixe dans un cadre mince. La porte vitrée : un cadre plus large, une traverse basse
		// haute, une barre de poussée à hauteur de main. Le verre des portes tambour : sans cadre.
		front = edge - 0.04;
		if (kind == KIND_SHOP_DOOR) {
			front = min(min(edge - 0.07, q.y - 0.22), abs(q.y - 1.0) - 0.025);
		} else if (kind == KIND_DOOR_GLASS) {
			front = 1.0;
		}
		glass_cover = pc_step(0.0, front, footprint);
		wood_behind = 0.0;
		double_glass = 0.0;
		open_cover = 0.0;
	}
//@ all
	// La couleur du bois peint, et un filet d'ombre au ras de la vitre.
	vec3 frame_albedo = pc_color_in(frame_color);
	frame_albedo *= 1.0 - 0.25 * exp(-max(-front, 0.0) / 0.006);
//@ 7+

	// --- 3. La pièce derrière la vitre ------------------------------------------------
	// Tout le calcul de la pièce est rangé dans « …_bureau.gdshaderinc » : le mur-rideau de la
	// tour de verre dessine les mêmes bureaux. On lui donne la vitre, la boîte de la pièce, le
	// tirage de la pièce et son étage.
//@ 7-9
	bool lobby = kind == KIND_LOBBY;
	// Le sol est sous l'allège ; le plafond, sous le vide du faux plafond ; la profondeur est
	// tirée, jusqu'aux 28 pieds de la règle de 1916. Le hall est plus haut et plus profond.
	float sill = lobby ? ground_sill : sill_height;
	float room_h = lobby ? ground_height - 0.4 : floor_height - plenum;
	float depth = lobby ? 14.0 : room_depth * (0.6 + 0.4 * r3);
//@ 10+
	// Derrière la vitre : le hall (derrière les portes tambour aussi), une boutique, ou un bureau.
	int room_kind = ROOM_OFFICE;
	if (kind == KIND_LOBBY || kind == KIND_DOOR_GLASS) {
		room_kind = ROOM_LOBBY;
	} else if (kind == KIND_SHOP || kind == KIND_SHOP_DOOR) {
		room_kind = ROOM_SHOP;
	}
	// Pour une vitre du rez-de-chaussée, la donnée de l'instance porte la sorte de boutique à la
	// place de l'étage.
	float shop_type = v_key.x;
	bool lobby = room_kind != ROOM_OFFICE;
	// Le sol d'un bureau est sous l'allège ; celui du rez-de-chaussée est celui de la rue. Le
	// plafond d'un bureau est sous le vide du faux plafond ; la profondeur est tirée, jusqu'aux
	// 28 pieds de la règle de 1916. Le hall et les boutiques sont plus hauts et plus profonds.
	float sill = lobby ? v_bottom : sill_height;
	float room_h = lobby ? ground_height - 0.4 : floor_height - plenum;
	float depth = room_kind == ROOM_LOBBY ? 14.0 : (room_kind == ROOM_SHOP ? room_depth : room_depth * (0.6 + 0.4 * r3));
//@ 7+
	// La pièce fait « span » travées de large, et la fenêtre est la « place »-ième ; le hall court
	// tout le long de la façade.
	vec4 room = vec4(0.5 * w - (place + 0.5) * bay_width, 0.0, -sill, -sill + max(room_h, h + sill + 0.1));
	room.y = room.x + span * bay_width;
	if (lobby) {
		room.xy = vec2(0.5 * w - 20.0, 0.5 * w + 20.0);
	}
	vec3 near_light;
//@ 7-9
	vec3 interior = room_view(q, vec2(w, h), VIEW, v_axis_x, v_axis_y, room, depth, lobby, r0, v_key.x, footprint, near_light);
//@ 10+
	vec3 interior = room_view(q, vec2(w, h), VIEW, v_axis_x, v_axis_y, room, depth, room_kind, shop_type, r0, v_key.x, footprint, near_light);
//@ 7+
	vec3 view_dir = normalize(VIEW);
	vec3 axis_z = normalize(cross(v_axis_x, v_axis_y));
//@ 5-6

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

	// Dimensions de la boîte. Le sol est sous l'allège ; le plafond, sous le vide du faux
	// plafond ; la profondeur est tirée, jusqu'aux 28 pieds de la règle de 1916.
//@ 5
	float sill = sill_height;
	float room_h = floor_height - plenum;
	float depth = room_depth * (0.6 + 0.4 * r3);
//@ 6
	bool lobby = kind == KIND_LOBBY;
	float sill = lobby ? ground_sill : sill_height;
	float room_h = lobby ? ground_height - 0.4 : floor_height - plenum;
	float depth = lobby ? 14.0 : room_depth * (0.6 + 0.4 * r3);
//@ 5-6
//@ 5
	// La pièce fait une, deux ou trois travées de large, et la fenêtre est dans l'une d'elles.
	float span = 1.0 + floor(r4 * 3.0);
	float place = floor(r5 * span);
//@ 5-6
	// La fenêtre est au milieu de sa travée.
	float x0 = 0.5 * w - (place + 0.5) * bay_width;
	float x1 = x0 + span * bay_width;
//@ 6
	if (lobby) {
		// Le hall court tout le long de la façade.
		x0 = 0.5 * w - 20.0;
		x1 = 0.5 * w + 20.0;
	}
//@ 5-6
	float floor_y = -sill;
	float ceil_y = floor_y + max(room_h, h + sill + 0.1);

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
//@ 5
	vec3 albedo = office_surface(face, m, extent, soft, r6, fixture);
//@ 6
	vec3 albedo;
	if (lobby) {
		albedo = lobby_surface(face, m, extent, soft, fixture);
	} else {
		albedo = office_surface(face, m, extent, soft, r6, fixture);
	}
//@ 5-6

	// Des cloisons basses entre les postes de travail : un plan parallèle à la vitre, haut de
	// 1,35 m, coupé d'une allée tous les 3,60 m. S'il est touché avant la paroi, il la cache.
	float t_part = -(2.2 + 1.6 * r7) / d.z;
	vec3 part_hit = origin + d * t_part;
	float part_y = part_hit.y - floor_y;
	float aisle = mod(part_hit.x - x0 + 3.6 * r8, 3.6);
//@ 5
	if (t_part < t_hit && part_y > 0.0 && part_y < 1.35 && aisle > 1.2) {
//@ 6
	if (!lobby && t_part < t_hit && part_y > 0.0 && part_y < 1.35 && aisle > 1.2) {
//@ 5-6
		// Toile gris-bleu, coiffée d'une lisse d'aluminium.
		albedo = mix(vec3(0.40, 0.43, 0.48), vec3(0.70, 0.71, 0.72), step(1.30, part_y));
		fixture = 0.0;
		t_hit = t_part;
		hit = part_hit;
		surface_normal = vec3(0.0, 0.0, 1.0);
		sky_fill = 0.6;
	}

	// --- 4. Éclairage de la pièce ------------------------------------------------
	// Le moteur n'éclaire pas cette pièce : elle n'a pas de géométrie. On calcule donc sa
	// lumière ici, et on la sortira par EMISSION.
	float day = 1.0 - night;
	// Un étage entier est allumé ou éteint : la nuit, les équipes de ménage passent d'étage en
	// étage. Dans un étage allumé, presque toutes les pièces le sont ; dans un étage éteint,
	// une sur vingt.
//@ 5
	// L'étage se déduit de la hauteur de la fenêtre.
	float floor_key = floor(v_key.y / floor_height);
//@ 6
	float floor_key = v_key.x;
//@ 5-6
	float floor_lit = step(pc_hash2(vec2(floor_key, 7.0 + seed)), mix(floor_lit_day, floor_lit_night, night));
	float lit = floor_lit > 0.5 ? step(r9, 0.9) : step(r9, 0.05);
	vec3 light_tint = pc_color_in(tube_color);
//@ 6
	if (lobby) {
		// Le hall reste allumé jour et nuit, d'une lumière chaude.
		lit = 1.0;
		light_tint = pc_color_in(lobby_color);
	}
//@ 5-6
	// Le jour entre par la fenêtre et s'éteint avec la profondeur.
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

	// --- 5. Le store ---------------------------------------------------------------
	// Une toile tendue 6 cm derrière la vitre, descendue plus ou moins bas depuis le haut : le
	// store à enrouleur. Elle laisse passer la lumière, pas les formes : le jour, elle est
	// éclairée du dehors ; la nuit, de la pièce, si la pièce est allumée.
	float t_shade = -0.06 / d.z;
	vec2 c = origin.xy + d.xy * t_shade;
	float r10 = pc_rehash(r0, 10.0);
	float r11 = pc_rehash(r0, 11.0);
//@ 5
	if (r10 < shades && t_shade < t_hit) {
//@ 6
	if (!lobby && r10 < shades && t_shade < t_hit) {
//@ 5-6
		// Le plus souvent, le store ne cache que le haut de la vitre.
		float low = h * mix(0.3, 0.95, r11);
		vec3 cloth = mix(vec3(0.88, 0.85, 0.76), vec3(0.76, 0.78, 0.74), step(0.6, pc_rehash(r0, 12.0)));
		vec3 shade_col = cloth * (vec3(0.95, 0.97, 1.0) * day * 0.6 + light_tint * lamp_power * 0.55 + moon * 2.0);
		// La barre de lestage, en bas de la toile.
		float bar = 1.0 - smoothstep(0.012, 0.012 + soft, abs(c.y - low - 0.012));
		shade_col = mix(shade_col, shade_col * 0.35, bar);
		interior = mix(interior, shade_col, step(low, c.y));
	}
//@ 5+

	// --- 6. Vitrage --------------------------------------------------------------
	// Ce que la vitre réfléchit ne la traverse pas : plus le regard est rasant, plus elle
	// renvoie le ciel et moins on voit la pièce (loi de Fresnel, forme de Schlick).
	vec3 n_glass = axis_z;
	float n_dot_v = clamp(dot(n_glass, view_dir), 0.0, 1.0);
	float f0 = 0.16 * reflectivity * reflectivity;
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
	vec3 tint = pc_color_in(glass_tint) * (1.0 - fresnel);
	// À travers une vitre, ou deux. Le bois du châssis du bas, levé, se voit derrière la vitre
	// du haut. Par la baie ouverte, on voit la pièce sans rien entre elle et nous.
	vec3 transmitted = interior * mix(tint, tint * tint, double_glass);
//@ 5-6
	vec3 wood_seen = frame_albedo * (vec3(0.45) * day * sky_fill + light_tint * lamp_power * 0.2 + moon);
//@ 7+
	vec3 wood_seen = frame_albedo * near_light;
//@ 5+
	transmitted = mix(transmitted, wood_seen * tint, wood_behind);
	transmitted = mix(transmitted, interior, open_cover);
	// Ombre du bois sur ce qu'on voit juste derrière lui.
	transmitted *= mix(0.55, 1.0, smoothstep(0.0, 0.03, front));
//@ all

	// --- Relief du bois ------------------------------------------------------------
	// Le bois dépasse de la vitre de deux centimètres : on penche la normale au bord.
	float frame_height = 0.02 * (1.0 - pc_ramp(-0.003, 0.003, front, 2.0 * footprint));
	vec3 n_frame = pc_bump(normalize(NORMAL), VERTEX, frame_height);
	// La vitre réfléchit ; la baie ouverte ne réfléchit rien.
	float glass = glass_cover * (1.0 - open_cover);

	// --- Sorties -------------------------------------------------------------------
//@ 4
	// Ce qu'on voit à travers : une vitre sombre, où le ciel se reflète ; le bois du châssis du
	// bas levé se devine derrière elle ; la baie ouverte est noire.
	vec3 seen = pc_color_in(glass_color);
	seen = mix(seen, frame_albedo * 0.4, wood_behind);
	seen = mix(seen, vec3(0.015), open_cover);
	ALBEDO = pc_color_out(mix(frame_albedo, seen, glass_cover));
	NORMAL = normalize(mix(n_frame, normalize(NORMAL), glass_cover));
//@ 5+
	// Le verre n'a plus de couleur propre : ce qu'on voit à travers sort par EMISSION, et le
	// reflet du ciel est ajouté par le moteur.
	ALBEDO = pc_color_out(mix(frame_albedo, vec3(0.0), glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
	NORMAL = normalize(mix(n_frame, n_glass, glass));
//@ all
	// Le bois peint est mat ; le verre est lisse ; la baie ouverte ne renvoie rien.
	ROUGHNESS = mix(mix(0.55, glass_roughness, glass), 1.0, open_cover);
//@ 4
	SPECULAR = mix(0.5, 0.85, glass) * (1.0 - open_cover);
//@ 5+
	SPECULAR = mix(0.5, reflectivity, glass) * (1.0 - open_cover);
//@ all
}
