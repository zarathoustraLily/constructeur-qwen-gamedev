// Ferronnerie : un simple rectangle devient un garde-corps de fer ajouré.
// {STATUS}
//
// Ce que le shader dessine : des lisses, une frise de cercles, des montants et un motif
// courant au choix (barreaux droits, volutes en S, croisillons).
//@ 10+ quiet
// Un quatrième motif, l'éventail, remplit l'imposte en demi-cercle d'une porte.
//@ all
//
// L'idée de l'étape : dessiner par une DISTANCE SIGNÉE. Pour chaque pixel, on calcule sa
// distance au fer le plus proche : négative dans le fer, positive dans le vide. Une barre est
// alors « la distance à une droite, moins une demi-épaisseur », un anneau « la distance à un
// cercle », et réunir deux formes revient à prendre le minimum des deux distances.
// Tout ce qui n'est pas du fer est découpé, y compris dans les ombres portées.
//
// Comme la fenêtre, ce shader part des UV et sert sur des rectangles instanciés ; la taille
// du panneau est l'échelle de son instance. Le motif s'ajuste pour tomber juste sur la
// longueur. Toutes les longueurs sont en mètres.
shader_type spatial;
render_mode cull_disabled;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms pattern;
//@ 7-9
uniform int motif : hint_enum("Barreaux", "Volutes", "Croisillons") = 1;
//@ 10+
/** « Éventail » remplit une imposte en demi-cercle : rayons et arcs partant du milieu du bord bas. */
uniform int motif : hint_enum("Barreaux", "Volutes", "Croisillons", "Éventail") = 1;
//@ all
/** Largeur approximative d'un module du motif. */
uniform float module_width : hint_range(0.2, 1.2, 0.01) = 0.5;
/** Entraxe approximatif des barreaux droits. */
uniform float bar_spacing : hint_range(0.06, 0.2, 0.005) = 0.115;
/** Frise de cercles sous la main courante. */
uniform bool frieze = true;

group_uniforms metal;
/** Largeur des fers. */
uniform float bar_width : hint_range(0.004, 0.04, 0.001) = 0.014;
uniform vec3 iron_color : source_color = vec3(0.03, 0.035, 0.04);
uniform float roughness : hint_range(0.1, 1.0, 0.01) = 0.5;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.5;

varying flat vec2 v_size;

void vertex() {
	// Taille du panneau en mètres : l'échelle de son instance, comme pour la fenêtre.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
}

// Seuil de trame entre 0 et 1, d'après la position du pixel (bruit à gradient entrelacé).
float dither(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// Distance d'un point p au segment a-b : on projette p sur la droite, on borne la projection
// aux deux bouts, et on mesure ce qui reste.
float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// Distance au trait d'une spirale d'Archimède centrée sur l'origine. Le rayon vaut
// « pitch » fois l'angle cumulé divisé par un tour ; le trait va de l'angle « from » à
// l'angle « to », en radians.
float sd_spiral(vec2 q, float pitch, float from, float to) {
	float b = pitch / TAU;
	float r = length(q);
	float angle = atan(q.y, q.x);
	float lo = ceil((from - angle) / TAU);
	float hi = floor((to - angle) / TAU);
	float d = 1000.0;
	if (hi >= lo) {
		float turn = clamp(round((r / b - angle) / TAU), lo, hi);
		d = abs(r - b * (angle + TAU * turn));
	}
	vec2 end_a = b * from * vec2(cos(from), sin(from));
	vec2 end_b = b * to * vec2(cos(to), sin(to));
	return min(d, min(length(q - end_a), length(q - end_b)));
}

// Volute en S dans une demi-travée : une spirale en bas contre le barreau, une spirale
// en haut contre le montant central, reliées par une tige. p : x depuis le montant
// central, y depuis la lisse basse. Renvoie la distance à l'axe du fer.
float sd_scroll(vec2 p, float half_module, float field, float hw) {
	float radius = min(0.42 * half_module, 0.19 * field);
	float pitch = 0.5 * radius;
	vec2 low_center = vec2(half_module - 1.5 * hw - radius, radius + 0.035);
	vec2 high_center = vec2(1.5 * hw + radius, field - radius - 0.035);
	// Les deux spirales font un tour et demi ; celle du haut est la même, retournée.
	float d = sd_spiral(p - low_center, pitch, PI, 2.0 * TAU);
	d = min(d, sd_spiral(high_center - p, pitch, PI, 2.0 * TAU));
	// Tige en S entre les bouts des deux spirales.
	vec2 low_end = low_center + vec2(radius, 0.0);
	vec2 high_end = high_center - vec2(radius, 0.0);
	float t = clamp((p.y - low_end.y) / (high_end.y - low_end.y), 0.0, 1.0);
	float stem_x = mix(low_end.x, high_end.x, t * t * (3.0 - 2.0 * t));
	float slope = (high_end.x - low_end.x) * 6.0 * t * (1.0 - t) / (high_end.y - low_end.y);
	float stem = abs(p.x - stem_x) / sqrt(1.0 + slope * slope);
	if (p.y < low_end.y || p.y > high_end.y) {
		stem = min(length(p - low_end), length(p - high_end));
	}
	return min(d, stem);
}

// Distance au bord du fer d'un garde-corps, négative dans le fer. p : mètres, origine en
// bas à gauche. hw : demi-largeur des fers. « structure » reçoit la distance aux seules
// pièces maîtresses : lisses et montants.
float railing_distance(vec2 p, vec2 size, float hw, out float structure) {
	// Lisses : basse, sous la frise, main courante.
	float low_rail = 0.07;
	float hand_rail = size.y - 1.6 * bar_width;
	float sub_rail = frieze ? hand_rail - 0.14 : hand_rail;
	float d = abs(p.y - low_rail) - hw;
	d = min(d, abs(p.y - hand_rail) - 1.6 * hw);
	d = min(d, abs(p.y - sub_rail) - hw);
	structure = d;

	if (frieze) {
		// Frise de cercles.
		float band = hand_rail - sub_rail;
		float ring_radius = 0.5 * band - hw;
		float count = max(round(size.x / (2.0 * ring_radius + bar_width)), 1.0);
		float step_x = size.x / count;
		vec2 c = vec2((fract(p.x / step_x) - 0.5) * step_x, p.y - 0.5 * (hand_rail + sub_rail));
		d = min(d, abs(length(c) - ring_radius) - 0.7 * hw);
	}

	// Champ : barreaux et motif courant.
	float field = sub_rail - low_rail;
	float v = p.y - low_rail;
	if (v > 0.0 && v < field) {
		float module_count = max(round(size.x / module_width), 1.0);
		float module = size.x / module_count;
		float u = (fract(p.x / module) - 0.5) * module;
		float half_module = 0.5 * module;
		// Un montant à chaque limite de module.
		d = min(d, half_module - abs(u) - hw);
		structure = d;
		if (motif == 0) {
			float bars = max(round(module / bar_spacing), 1.0);
			float pitch = module / bars;
			d = min(d, abs((fract(p.x / pitch + 0.5) - 0.5) * pitch) - 0.8 * hw);
		} else if (motif == 1) {
			vec2 h = vec2(abs(u), v);
			// Montant central, losange à mi-hauteur, volutes de part et d'autre.
			d = min(d, h.x - 0.8 * hw);
			d = min(d, (h.x / 0.028 + abs(v - 0.5 * field) / 0.055 - 1.0) * 0.024);
			d = min(d, sd_scroll(h, half_module, field, hw) - 0.75 * hw);
		} else {
			// Croix de Saint-André, anneau et bouton au croisement.
			vec2 h = vec2(abs(u), abs(v - 0.5 * field));
			d = min(d, sd_segment(h, vec2(0.0), vec2(half_module, 0.5 * field)) - 0.75 * hw);
			d = min(d, abs(length(h) - min(0.3 * half_module, 0.16 * field)) - 0.7 * hw);
			d = min(d, length(h) - 2.2 * hw);
		}
	}
	return d;
}

//@ 10+
// Distance au bord du fer d'un éventail d'imposte : rayons et arcs autour du milieu du
// bord bas, dans la demi-ellipse inscrite au panneau. « structure » : l'arc extérieur.
float fan_distance(vec2 p, vec2 size, float hw, out float structure) {
	vec2 e = vec2((p.x - 0.5 * size.x) / (0.5 * size.x), p.y / size.y);
	float radial = length(e);
	float scale = min(0.5 * size.x, size.y);
	float ray_step = 0.5 * PI / 5.0;
	float angle = atan(e.y, abs(e.x));
	float d = abs(fract(angle / ray_step + 0.5) - 0.5) * ray_step * radial * scale - hw;
	d = min(d, abs(radial - 0.3) * scale - hw);
	structure = abs(radial - 0.97) * scale - 1.2 * hw;
	d = min(d, structure);
	// Moyeu plein au centre ; rien au-delà de l'ellipse.
	d = min(d, (radial - 0.16) * scale);
	return max(d, (radial - 1.0) * scale);
}
//@ all

void fragment() {
	// p : position du pixel sur le panneau, en mètres, origine en bas à gauche.
	vec2 size = v_size;
	vec2 p = vec2(UV.x * size.x, (1.0 - UV.y) * size.y);
	float fw = max(fwidth(p.x), fwidth(p.y));
	// hw : demi-largeur d'un fer.
	float hw = 0.5 * bar_width;
	float structure;
//@ 7-9
	float d = railing_distance(p, size, hw, structure);
//@ 10+
	float d = motif == 3 ? fan_distance(p, size, hw, structure) : railing_distance(p, size, hw, structure);
//@ all
	float pixel = max(fw, 0.00001);

	// Lisses et montants ne sont jamais rendus plus fins qu'un pixel : de loin, l'ouvrage
	// garde ses grandes lignes.
	float solid = clamp(0.5 - (structure - max(0.55 * fw - hw, 0.0)) / pixel, 0.0, 1.0);
	// Le reste du motif compte pour la part du pixel qu'il couvre vraiment. De près, la
	// découpe est franche ; de loin, une trame en fait un voile sombre au lieu de le
	// laisser disparaître ou se boucher.
	float thin = clamp(bar_width / pixel, 0.0, 1.0);
	float veil = clamp(0.5 - d / pixel, 0.0, 1.0) * mix(thin, 1.0, smoothstep(1.5 * hw, 3.0 * hw, -d));
	float threshold = mix(0.5, dither(FRAGCOORD.xy), smoothstep(0.4 * hw, 1.2 * hw, fw));
	// ALPHA à 0 ou 1, et un seuil : le pixel est gardé ou jeté, sans transparence à trier.
	// C'est ce qui permet au vide de ne pas porter d'ombre.
	ALPHA = max(step(0.5, solid), step(threshold, veil));
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// Relief : section arrondie des fers, effacée quand ils deviennent trop fins à l'écran.
	float rounding = clamp(d / hw + 1.0, 0.0, 1.0);
	float height = hw * sqrt(1.0 - rounding * rounding) * (1.0 - smoothstep(0.5 * hw, 2.0 * hw, fw));
	NORMAL = pc_bump(normalize(NORMAL), VERTEX, height);

	ALBEDO = pc_color_out(pc_color_in(iron_color));
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.5;
}
