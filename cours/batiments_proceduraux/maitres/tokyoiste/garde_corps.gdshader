// Garde-corps et grilles d'aluminium : un simple rectangle devient un ouvrage ajouré.
// {STATUS}
//
// Trois motifs. Le script choisit lequel, rectangle par rectangle, par la donnée de l'instance :
//   0. des barreaux verticaux entre deux lisses : le garde-corps de balcon le plus courant ;
//   1. des panneaux translucides dans un cadre : on ne voit pas à travers ;
//   2. la grille ronde d'un climatiseur : des anneaux et des rayons devant le ventilateur.
//
// L'idée de l'étape : dessiner par une DISTANCE SIGNÉE. Pour chaque pixel, on calcule sa
// distance au métal le plus proche : négative dans le métal, positive dans le vide. Un barreau
// est alors « la distance à une droite, moins une demi-épaisseur », un anneau « la distance à
// un cercle », et réunir deux formes revient à prendre le minimum des deux distances.
// Tout ce qui n'est pas du métal est découpé, y compris dans les ombres portées.
//
// Comme la fenêtre, ce shader part des UV et sert sur des rectangles instanciés ; la taille
// du panneau est l'échelle de son instance. Le motif s'ajuste pour tomber juste sur la
// longueur. Toutes les longueurs sont en mètres.
shader_type spatial;
render_mode cull_disabled;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

// Les motifs, tels que le script les écrit dans la donnée de l'instance.
const int MOTIF_BARS = 0;
const int MOTIF_PANELS = 1;
const int MOTIF_FAN_GRILLE = 2;

group_uniforms pattern;
/** Entraxe approximatif des barreaux. */
uniform float bar_spacing : hint_range(0.06, 0.2, 0.005) = 0.11;
/** Entraxe approximatif des poteaux. */
uniform float post_spacing : hint_range(0.5, 2.0, 0.05) = 1.0;
/** Largeur d'un barreau. */
uniform float bar_width : hint_range(0.004, 0.04, 0.001) = 0.016;
/** Largeur des lisses et des poteaux. */
uniform float rail_width : hint_range(0.01, 0.1, 0.002) = 0.04;

group_uniforms metal;
uniform vec3 metal_color : source_color = vec3(0.62, 0.63, 0.64);
uniform float roughness : hint_range(0.1, 1.0, 0.01) = 0.4;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.6;
/** Teinte des panneaux translucides. */
uniform vec3 panel_color : source_color = vec3(0.74, 0.80, 0.82);
/** Teinte de la carrosserie d'un climatiseur. */
uniform vec3 casing_color : source_color = vec3(0.80, 0.80, 0.76);

varying flat vec2 v_size;
varying flat float v_motif;

void vertex() {
	// Taille du panneau en mètres : l'échelle de son instance, comme pour la fenêtre.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
	// Le motif : première valeur de la donnée que le script a attachée à l'instance.
	v_motif = INSTANCE_CUSTOM.x;
}

// Seuil de trame entre 0 et 1, d'après la position du pixel (bruit à gradient entrelacé).
float dither(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// Distance au bord du cadre : lisse haute, lisse basse et poteaux. Le nombre de poteaux est
// ajusté pour que les modules tombent juste sur la longueur. « along » reçoit la position
// dans le module, « module » sa largeur.
float frame_distance(vec2 p, vec2 size, out float along, out float module) {
	float half_rail = 0.5 * rail_width;
	float count = max(1.0, floor(size.x / post_spacing + 0.5));
	module = size.x / count;
	along = mod(p.x, module);
	// La lisse haute sert de main courante ; la lisse basse est à 8 cm du sol.
	float d = abs(p.y - (size.y - half_rail)) - half_rail;
	d = min(d, abs(p.y - 0.08) - 0.7 * half_rail);
	// Un poteau à chaque limite de module, donc aussi aux deux bouts.
	return min(d, min(along, module - along) - 0.8 * half_rail);
}

void fragment() {
	// p : position du pixel sur le panneau, en mètres, origine en bas à gauche.
	vec2 size = v_size;
	vec2 p = vec2(UV.x * size.x, (1.0 - UV.y) * size.y);
	float fw = max(fwidth(p.x), fwidth(p.y));
	float pixel = max(fw, 0.00001);
	int motif = int(v_motif + 0.5);
	// hw : demi-largeur d'un barreau.
	float hw = 0.5 * bar_width;

	vec3 col = pc_color_in(metal_color);
	float metal = metallic;
	float rough = roughness;
	// « structure » : distance aux grandes pièces, qu'on ne laisse jamais devenir plus fines
	// qu'un pixel. « d » : distance à tout le métal, barreaux compris.
	float structure;
	float d;

	if (motif == MOTIF_FAN_GRILLE) {
		// Climatiseur : la carrosserie est pleine ; seule la grille est dessinée dessus.
		vec2 centre = vec2(0.42 * size.x, 0.5 * size.y);
		float radius = 0.42 * min(size.x, size.y);
		vec2 from_centre = p - centre;
		float r = length(from_centre);
		// Anneaux tous les 2,5 cm, et huit rayons.
		float rings = abs(fract(r / 0.025 + 0.5) - 0.5) * 0.025 - 0.003;
		float spoke_step = PI / 4.0;
		float spokes = abs(fract(atan(from_centre.y, from_centre.x) / spoke_step + 0.5) - 0.5) * spoke_step * r - 0.004;
		float wire = min(rings, spokes);
		float in_fan = 1.0 - pc_step(radius, r, fw);
		// De loin, la grille se fond en un disque gris.
		float wire_cover = mix(0.3, 1.0 - pc_step(0.0, wire, fw), 1.0 - smoothstep(0.004, 0.02, fw));
		col = mix(pc_color_in(casing_color), mix(vec3(0.05), vec3(0.55), wire_cover), in_fan);
		metal = 0.1;
		rough = 0.6;
		structure = -1.0;
		d = -1.0;
	} else {
		float along;
		float module;
		structure = frame_distance(p, size, along, module);
		if (motif == MOTIF_PANELS) {
			// Panneaux translucides : tout est plein entre les deux lisses.
			float in_panel = min(p.y - 0.08, size.y - p.y);
			d = min(structure, -in_panel);
			col = mix(pc_color_in(panel_color), col, 1.0 - pc_step(0.0, structure, fw));
			metal = metallic * (1.0 - pc_step(0.0, structure, fw));
			rough = mix(roughness, 0.3, pc_step(0.0, structure, fw));
		} else {
			// Barreaux : leur nombre est ajusté à la largeur du module, comme celui des poteaux.
			float count = max(1.0, floor(module / bar_spacing + 0.5));
			float pitch = module / count;
			float bars = abs(fract(along / pitch + 0.5) - 0.5) * pitch - hw;
			// Un barreau ne dépasse pas des lisses.
			bars = max(bars, max(0.08 - p.y, p.y - size.y));
			d = min(structure, bars);
		}
	}

	// Lisses et poteaux ne sont jamais rendus plus fins qu'un pixel : de loin, l'ouvrage
	// garde ses grandes lignes.
	float solid = clamp(0.5 - (structure - max(0.55 * fw - 0.5 * rail_width, 0.0)) / pixel, 0.0, 1.0);
	// Les barreaux comptent pour la part du pixel qu'ils couvrent vraiment. De près, la
	// découpe est franche ; de loin, une trame en fait un voile au lieu de les laisser
	// disparaître ou se boucher.
	float thin = clamp(bar_width / pixel, 0.0, 1.0);
	float veil = clamp(0.5 - d / pixel, 0.0, 1.0) * mix(thin, 1.0, smoothstep(1.5 * hw, 3.0 * hw, -d));
	float threshold = mix(0.5, dither(FRAGCOORD.xy), smoothstep(0.4 * hw, 1.2 * hw, fw));
	// ALPHA à 0 ou 1, et un seuil : le pixel est gardé ou jeté, sans transparence à trier.
	// C'est ce qui permet au vide de ne pas porter d'ombre.
	ALPHA = max(step(0.5, solid), step(threshold, veil));
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// Relief : section arrondie des barreaux, effacée quand ils deviennent trop fins à l'écran.
	float rounding = clamp(d / hw + 1.0, 0.0, 1.0);
	float height = hw * sqrt(1.0 - rounding * rounding) * (1.0 - smoothstep(0.5 * hw, 2.0 * hw, fw));
	NORMAL = pc_bump(normalize(NORMAL), VERTEX, motif == MOTIF_BARS ? height : 0.0);

	ALBEDO = pc_color_out(col);
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = 0.5;
}
