// Mur-rideau : toute une façade de verre et de métal, dessinée sur un seul rectangle.
// {STATUS}
//
// La tour de verre n'a plus de mur porteur en façade : sa façade est une peau accrochée au
// bord des planchers. Ce shader la dessine entière, d'après la position du pixel sur le
// rectangle :
//   - des meneaux verticaux, un par module de façade ;
//   - à chaque plancher, une bande opaque qui cache le bord de la dalle et le vide du faux
//     plafond, bordée de deux traverses : du verre émaillé, mat, dans la tour de 1961 ; du
//     verre sombre, aussi brillant que le reste, dans la tour tout en verre d'aujourd'hui ;
//   - entre deux bandes opaques, le verre de vision, teinté, et le bureau derrière lui : la
//     même pièce que derrière les fenêtres de la tour de brique, rangée dans le fichier
//     « …_bureau.gdshaderinc » que les deux shaders incluent ;
//   - au rez-de-chaussée, le hall, vitré presque du sol au plafond ;
//   - en haut du rectangle, le parapet : une bande opaque.
//@ 9+ quiet
// Un même matériau peut servir de couronne à la tour tout en verre (« crown ») : le verre y
// court du pied au sommet, sans planchers derrière lui ; on voit à travers la charpente qui le
// tient, et la nuit, des projecteurs l'éclairent de l'intérieur.
//@ all
//
// Il part des UV, comme la fenêtre : le script pose un rectangle instancié par façade et par
// gradin. La donnée de l'instance donne le premier étage du rectangle, sa première colonne et
// sa façade : les pièces se tirent avec la même clé que celles des fenêtres de brique.
// Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"
#include "{SHADER}_bureau.gdshaderinc"

group_uniforms grid;
/** Écart voulu entre deux meneaux. Le shader le retouche pour qu'un nombre entier de modules remplisse la façade. */
uniform float module_width : hint_range(0.8, 4.0, 0.01) = 1.52;
/** Largeur d'un meneau, vu de face. */
uniform float mullion_width : hint_range(0.02, 0.2, 0.005) = 0.06;
/** Hauteur d'un étage, puis du rez-de-chaussée, puis du parapet en haut du rectangle. */
uniform float floor_height : hint_range(2.5, 6.0, 0.01) = 3.66;
uniform float ground_height : hint_range(3.0, 9.0, 0.01) = 5.5;
uniform float parapet_height : hint_range(0.0, 3.0, 0.01) = 1.1;
/** Bas du verre de vision au-dessus du plancher, et hauteur de la bande opaque sous le plancher du dessus. */
uniform float sill_height : hint_range(0.0, 1.5, 0.01) = 0.8;
uniform float head_band : hint_range(0.1, 1.5, 0.01) = 0.45;

group_uniforms colours;
uniform vec3 metal_color : source_color = vec3(0.62, 0.63, 0.64);
uniform vec3 spandrel_color : source_color = vec3(0.12, 0.15, 0.16);
uniform vec3 glass_tint : source_color = vec3(0.62, 0.74, 0.72);
/** Force des reflets du verre de vision. */
uniform float reflectivity : hint_range(0.0, 1.0, 0.01) = 0.92;
uniform float glass_roughness : hint_range(0.0, 0.5, 0.005) = 0.03;
/** Vrai : les bandes opaques sont du verre sombre, brillant comme le verre de vision. Faux : de l'émail mat. */
uniform bool glass_spandrels = false;
//@ 9+

group_uniforms crown_settings;
/** Vrai : ce matériau est celui d'une couronne de verre, sans planchers derrière elle. */
uniform bool crown = false;
/** La nuit, la lumière des projecteurs posés au pied de la couronne. */
uniform vec3 crown_glow : source_color = vec3(0.86, 0.93, 1.0);
uniform float crown_energy : hint_range(0.0, 6.0, 0.05) = 2.2;
//@ all

varying flat vec2 v_size;
varying flat vec3 v_axis_x;
varying flat vec3 v_axis_y;
varying flat vec4 v_custom;

void vertex() {
	// Comme pour la fenêtre : la taille du rectangle est l'échelle de son instance.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
	v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
	v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
	// x : le premier étage du rectangle (0 : il part du rez-de-chaussée) ; y : sa première
	// colonne sur sa façade ; z : la façade.
	v_custom = INSTANCE_CUSTOM;
}

void fragment() {
	// --- 1. Coordonnées ------------------------------------------------------------
	// q est en mètres, avec l'origine en bas à gauche du rectangle.
	float w = v_size.x;
	float h = v_size.y;
	vec2 q = vec2(UV.x * w, (1.0 - UV.y) * h);
	float footprint = max(fwidth(q.x), fwidth(q.y));

	// --- 2. Modules : floor() donne la colonne -----------------------------------------
	// Un nombre entier de modules remplit la façade : le module est retouché pour tomber juste.
	float modules = max(1.0, floor(w / module_width + 0.5));
	float unit = w / modules;
	float column = min(floor(q.x / unit), modules - 1.0);
	float xl = q.x - column * unit;
	float to_mullion = min(xl, unit - xl);

	// --- 3. Étages : floor() donne l'étage ---------------------------------------------
	// Le rez-de-chaussée est plus haut que les autres. « level » : le numéro de l'étage ;
	// « base » : la hauteur de son plancher sur le rectangle.
	float first = v_custom.x;
	float level;
	float base;
	float level_h;
	if (first < 0.5 && q.y < ground_height) {
		level = 0.0;
		base = 0.0;
		level_h = ground_height;
	} else {
		float y0 = first < 0.5 ? ground_height : 0.0;
		float k = floor((q.y - y0) / floor_height);
		level = max(first, 1.0) + k;
		base = y0 + k * floor_height;
		level_h = floor_height;
	}
	float yl = q.y - base;
	bool lobby = level < 0.5;
	// Le verre de vision : de l'allège à la bande opaque du haut. Le hall est vitré presque du
	// sol au plafond.
	float vision_low = lobby ? 0.12 : sill_height;
	float vision_high = level_h - head_band;
	// Distance au bord du verre de vision : positive dedans, négative sur le métal ou
	// l'émail. Le parapet, en haut du rectangle, est tout opaque.
	float inside = min(min(yl - vision_low, vision_high - yl), to_mullion - 0.5 * mullion_width);
	if (q.y > h - parapet_height) {
		inside = -1.0;
	}
//@ 9+
	if (crown) {
		// Couronne : pas d'étages, pas de parapet ; du verre entre les meneaux, du pied au
		// sommet, et une lisse de métal en haut.
		inside = min(to_mullion - 0.5 * mullion_width, h - 0.15 - q.y);
	}
//@ all
	float glass_cover = pc_step(0.0, inside, footprint);
	// Le métal : les meneaux, et deux traverses de 5 cm qui bordent la bande opaque.
	float transom = max(pc_band(yl - vision_low, 0.025, footprint), pc_band(yl - vision_high, 0.025, footprint));
	float metal = max(1.0 - pc_step(0.5 * mullion_width, to_mullion, footprint), transom * (1.0 - glass_cover));

	// --- 4. La pièce derrière le verre ---------------------------------------------------
	// Comme derrière les fenêtres de brique : une pièce s'étend sur plusieurs modules (ici deux
	// à quatre), la même largeur sur tout un étage d'une façade, et elle se tire avec la même
	// clé, son étage, son numéro le long de l'étage et sa façade.
	float col_id = v_custom.y + column;
//@ 7-10
	float span = 2.0 + floor(pc_hash2(vec2(level, v_custom.z * 31.0 + 5.0)) * 3.0);
	float room_id = floor(col_id / span);
	float place = col_id - room_id * span;
	float r0 = pc_hash3(vec3(level, room_id, v_custom.z + 17.0));
//@ 11+
	// La graine de la tour entre dans chaque clé, comme pour les fenêtres.
	float span = 2.0 + floor(pc_hash2(vec2(level, v_custom.z * 31.0 + 5.0 + seed * 97.0)) * 3.0);
	float room_id = floor(col_id / span);
	float place = col_id - room_id * span;
	float r0 = pc_hash3(vec3(level, room_id, v_custom.z + 17.0 + seed * 101.0));
//@ all
	float r3 = pc_rehash(r0, 3.0);
	// La vitre de ce module : son coin bas gauche, sa taille.
	vec2 pane_q = vec2(xl - 0.5 * mullion_width, yl - vision_low);
	vec2 pane = vec2(unit - mullion_width, vision_high - vision_low);
	// Un plateau de bureaux d'une tour de verre est plus profond que ceux de 1916 : on y
	// éclaire le fond à la lampe, plus à la fenêtre.
	float depth = lobby ? 14.0 : room_depth * (0.8 + 0.6 * r3);
	float room_floor = -vision_low;
	float room_ceiling = room_floor + (lobby ? level_h - 0.4 : level_h - plenum);
	vec4 room = vec4(-place * unit - 0.5 * mullion_width, 0.0, room_floor, max(room_ceiling, pane.y + 0.1));
	room.y = room.x + span * unit;
	if (lobby) {
		room.xy = vec2(pane_q.x - q.x - 1.0, pane_q.x - q.x + w + 1.0);
	}
	vec3 near_light;
//@ 7-9
	vec3 interior = room_view(pane_q, pane, VIEW, v_axis_x, v_axis_y, room, depth, lobby, r0, level, footprint, near_light);
//@ 10+
	vec3 interior = room_view(pane_q, pane, VIEW, v_axis_x, v_axis_y, room, depth, lobby ? ROOM_LOBBY : ROOM_OFFICE, 0.0, r0, level, footprint, near_light);
//@ all
//@ 9+
	if (crown) {
		// Dans la couronne, derrière le verre : la charpente d'acier qui le tient, des croix de
		// Saint-André entre les meneaux, sur un fond sombre. La nuit, les projecteurs posés en
		// bas l'éclairent, de moins en moins en montant.
		vec2 cell = vec2(xl / unit, fract(q.y / unit));
		float brace = min(abs(cell.x - cell.y), abs(cell.x + cell.y - 1.0)) * unit;
		float strut = 1.0 - smoothstep(0.03, 0.03 + 1.5 * footprint, brace);
		float glow = crown_energy * night * (1.0 - 0.7 * q.y / h);
		vec3 dark = vec3(0.03, 0.035, 0.04) * (1.0 - night);
		interior = mix(dark + pc_color_in(crown_glow) * glow, vec3(0.08) + pc_color_in(crown_glow) * glow * 0.3, strut);
	}
//@ all

	// --- 5. Verre ------------------------------------------------------------------
	// Le verre d'une tour de verre est teinté et très réfléchissant : on y voit le ciel bien
	// plus que les bureaux (loi de Fresnel, forme de Schlick).
	vec3 view_dir = normalize(VIEW);
	vec3 n_glass = normalize(cross(v_axis_x, v_axis_y));
	float n_dot_v = clamp(dot(n_glass, view_dir), 0.0, 1.0);
	float f0 = 0.16 * reflectivity * reflectivity;
	float fresnel = f0 + (1.0 - f0) * pow(1.0 - n_dot_v, 5.0);
	vec3 transmitted = interior * pc_color_in(glass_tint) * (1.0 - fresnel);
	// Ombre des meneaux sur ce qu'on voit juste derrière eux.
	transmitted *= mix(0.6, 1.0, smoothstep(0.0, 0.04, inside));

	// --- 6. Relief et sorties ------------------------------------------------------------
	// Les meneaux avancent de 8 cm devant le verre : on penche la normale à leurs bords.
	float relief = 0.08 * (1.0 - pc_ramp(0.5 * mullion_width - 0.004, 0.5 * mullion_width + 0.004, to_mullion, 2.0 * footprint));
	vec3 n_metal = pc_bump(normalize(NORMAL), VERTEX, relief);
	vec3 opaque = mix(pc_color_in(spandrel_color), pc_color_in(metal_color), metal);
	ALBEDO = pc_color_out(mix(opaque, vec3(0.0), glass_cover));
	EMISSION = pc_color_out(transmitted * glass_cover);
	// L'émail est un verre opaque : lisse, mais moins réfléchissant que le verre de vision. Dans
	// une tour tout en verre, la bande opaque brille autant que le reste.
	float spandrel_rough = glass_spandrels ? glass_roughness : 0.12;
	float spandrel_spec = glass_spandrels ? reflectivity : 0.6;
	METALLIC = 0.7 * metal * (1.0 - glass_cover);
	ROUGHNESS = mix(mix(spandrel_rough, 0.35, metal), glass_roughness, glass_cover);
	SPECULAR = mix(mix(spandrel_spec, 0.5, metal), reflectivity, glass_cover);
	NORMAL = normalize(mix(n_metal, n_glass, glass_cover));
}
