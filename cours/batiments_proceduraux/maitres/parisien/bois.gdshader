// Bois massif : planches, cernes, fil, vernis ou peinture.
// {STATUS}
//
// Jusqu'ici les motifs étaient plaqués sur une face (u le long du mur, v vers le haut). Le
// bois, lui, est calculé EN VOLUME : le fil suit un axe de l'objet, et les cernes sont des
// cylindres autour du cœur de l'arbre. Une face coupée dans le sens du fil montre des veines,
// une face en bout montre des cernes, sans rien régler : c'est la position en trois dimensions
// qui décide. Aucune UV n'est requise.
//
// L'immeuble s'en sert peint (« paint » à 1) : porte d'entrée, devantures de boutique.
// Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms mapping;
/** Axe du fil du bois. */
uniform int grain_axis : hint_enum("X", "Y", "Z") = 1;
/** Axe le long duquel les planches se juxtaposent. Doit différer de l'axe du fil. */
uniform int plank_axis : hint_enum("X", "Y", "Z") = 0;

group_uniforms planks;
/** Largeur d'une planche. */
uniform float plank_width : hint_range(0.03, 1.0, 0.005) = 0.14;
/** Longueur d'une planche. 0 : planches d'un seul tenant. */
uniform float plank_length : hint_range(0.0, 6.0, 0.05) = 0.0;
/** Largeur du joint entre planches. */
uniform float gap_width : hint_range(0.0, 0.02, 0.0005) = 0.003;
/** Profondeur du chanfrein au bord des planches. */
uniform float gap_depth : hint_range(0.0, 0.02, 0.0005) = 0.003;

group_uniforms wood;
uniform vec3 color_light : source_color = vec3(0.66, 0.50, 0.33);
uniform vec3 color_dark : source_color = vec3(0.40, 0.26, 0.14);
/** Nombre de cernes par mètre. */
uniform float ring_density : hint_range(10.0, 500.0, 1.0) = 120.0;
/** Contraste entre bois de printemps et bois d'été. */
uniform float ring_contrast : hint_range(0.0, 1.0, 0.01) = 0.6;
/** Ondulation des cernes. */
uniform float figure : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Fil fin et pores. */
uniform float fibre : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Écart de teinte d'une planche à l'autre. */
uniform float plank_variation : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms finish;
/** 0 : bois brut. 1 : vernis brillant. */
uniform float varnish : hint_range(0.0, 1.0, 0.01) = 0.5;
/** 0 : bois apparent. 1 : bois peint. */
uniform float paint : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec3 paint_color : source_color = vec3(0.07, 0.22, 0.18);
/** Usure de la peinture aux arêtes des planches. */
uniform float paint_wear : hint_range(0.0, 1.0, 0.01) = 0.2;
/** Encrassement dans les joints. */
uniform float dirt : hint_range(0.0, 1.0, 0.01) = 0.25;

varying vec3 v_pos;

void vertex() {
	// Position dans le repère de l'immeuble : le bois suit l'objet.
	v_pos = VERTEX;
}

vec3 axis_vector(int axis) {
	return axis == 0 ? vec3(1.0, 0.0, 0.0) : (axis == 1 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0));
}

void fragment() {
	// --- Repère de la planche ------------------------------------------------
	int thickness_axis = 3 - grain_axis - plank_axis;
	if (thickness_axis < 0 || thickness_axis > 2 || grain_axis == plank_axis) {
		thickness_axis = (grain_axis + 2) % 3;
	}
	float along = v_pos[grain_axis];
	float across = v_pos[plank_axis];
	float depth = v_pos[thickness_axis];
	float f_along = fwidth(along);
	float f_across = fwidth(across);
	float fw = max(f_along, max(f_across, fwidth(depth)));

	float plank = floor(across / plank_width);
	float al = across - plank * plank_width;
	float d_gap = min(al, plank_width - al);
	float sign_a = al < 0.5 * plank_width ? 1.0 : -1.0;
	float h_strip = pc_hash1(plank * 5.0 + 2.0);

	float segment = 0.0;
	float d_end = 1000.0;
	float sign_g = 1.0;
	if (plank_length > 0.001) {
		float g = (along + h_strip * plank_length) / plank_length;
		segment = floor(g);
		float gl = (g - segment) * plank_length;
		d_end = min(gl, plank_length - gl);
		sign_g = gl < 0.5 * plank_length ? 1.0 : -1.0;
	}
	float h_plank = pc_hash2(vec2(plank, segment) + vec2(13.0, 77.0));
	float h_plank2 = pc_rehash(h_plank, 1.0);
	float h_plank3 = pc_rehash(h_plank, 2.0);

	// --- Cernes --------------------------------------------------------------
	// Le cœur de l'arbre est placé derrière la planche, à une distance propre à
	// chaque planche : près, on voit des flammes ; loin, un fil presque droit.
	float x = al - 0.5 * plank_width;
	vec2 pith = vec2((h_plank - 0.5) * 0.22, -(0.025 + 0.3 * h_plank2 * h_plank2));
	pith.x += along * (h_plank3 - 0.5) * 0.035;
	// Le tronc est conique : les cernes sortent de la face l'un après l'autre et
	// dessinent des arches allongées.
	float taper = (pc_rehash(h_plank, 3.0) - 0.5) * 0.06;
	vec3 q3 = vec3(x * 3.0, along * 0.55, depth * 3.0) + h_plank * 41.0;
	float warp = pc_fbm3(q3, 3, fw * 3.0) - 0.5;
	float wobble = pc_noise3(vec3(x * 14.0, along * 2.2, depth * 14.0) + h_plank2 * 17.0) - 0.5;
	float radius = length(vec2(x, depth) - pith) + along * taper + figure * (0.035 * warp + 0.006 * wobble);
	float rings = radius * ring_density;
	// Les années ne se ressemblent pas : cernes tantôt serrés, tantôt larges.
	rings += 1.2 * (pc_noise2(vec2(rings * 0.31, h_plank * 64.0)) - 0.5);
	float ring_fw = fwidth(rings);
	float f = fract(rings);
	// Bois d'été : une bande sombre qui se referme net à la fin du cerne.
	float late = smoothstep(0.42, 0.88, f) * (1.0 - smoothstep(0.9, 1.0, f));
	late = mix(late, 0.27, smoothstep(0.35, 0.95, ring_fw));

	// --- Fil et pores --------------------------------------------------------
	float fib_fine = pc_fbm2(vec2(across * 520.0, along * 14.0) + h_plank * 90.0, 3, max(f_across * 520.0, f_along * 14.0));
	float fib_broad = pc_fbm2(vec2(across * 150.0, along * 3.5) + h_plank2 * 70.0, 3, max(f_across * 150.0, f_along * 3.5));
	float fib = 0.55 * fib_fine + 0.45 * fib_broad;
	float pores = smoothstep(0.72, 0.92, pc_noise2(vec2(across * 1300.0, along * 55.0) + h_plank2 * 30.0));
	pores *= (1.0 - late) * (1.0 - smoothstep(0.25, 0.8, f_across * 1300.0));
	// Plages plus claires ou plus sombres le long de la planche.
	float blotch = pc_fbm2(vec2(across * 7.0, along * 0.9) + h_plank3 * 23.0, 3, max(f_across * 7.0, f_along * 0.9));

	vec3 wood = mix(pc_color_in(color_light), pc_color_in(color_dark),
			clamp(late * ring_contrast + (fib - 0.5) * 0.45 * fibre, 0.0, 1.0));
	wood *= 1.0 - 0.3 * pores * fibre;
	wood *= 0.92 + 0.16 * blotch;
	wood *= 1.0 + (h_plank - 0.5) * 0.34 * plank_variation;
	wood = mix(wood, wood * vec3(1.06, 0.98, 0.9), h_plank2 * plank_variation * 0.7);

	// --- Joints entre planches ----------------------------------------------
	float half_gap = 0.5 * gap_width;
	float gap_mask = max(pc_band(d_gap, half_gap, f_across), pc_band(d_end, half_gap, f_along));
	float ramp_slope;
	float slope_across = 0.0;
	float slope_along = 0.0;
	float bevel = 0.004;
	if (d_gap < d_end) {
		pc_ramp_d(half_gap, half_gap + bevel, d_gap, 2.0 * f_across, ramp_slope);
		slope_across = gap_depth * ramp_slope * sign_a;
	} else {
		pc_ramp_d(half_gap, half_gap + bevel, d_end, 2.0 * f_along, ramp_slope);
		slope_along = gap_depth * ramp_slope * sign_g;
	}
	float d_edge = min(d_gap, d_end);

	// --- Peinture ------------------------------------------------------------
	float brush = pc_fbm2(vec2(across * 180.0, along * 6.0) + 7.0, 3, max(f_across * 180.0, f_along * 6.0));
	float patch_noise = pc_fbm2(vec2(across, along) * 9.0 + h_plank * 60.0, 3, fw * 9.0);
	vec3 painted = pc_color_in(paint_color) * (0.92 + 0.16 * brush) * (0.95 + 0.1 * patch_noise);
	float wear = paint_wear * smoothstep(0.012, 0.0, d_edge - half_gap) * smoothstep(0.35, 0.7, patch_noise);
	float paint_cover = paint * (1.0 - wear);
	vec3 col = mix(wood, painted, paint_cover);

	// --- Encrassement --------------------------------------------------------
	float grime = dirt * (exp(-max(d_edge - half_gap, 0.0) / 0.012) * 0.7 + 0.25 * smoothstep(0.55, 0.85, patch_noise));
	col = mix(col, col * vec3(0.42, 0.40, 0.38), clamp(grime, 0.0, 1.0));
	col = mix(col, vec3(0.03, 0.025, 0.02), gap_mask);

	// --- Relief --------------------------------------------------------------
	float relief = (1.0 - 0.7 * paint_cover) * (1.0 - 0.6 * varnish);
	float soft_height = ((fib - 0.5) * 0.00035 - pores * 0.00025 + late * 0.00015) * fibre * relief;
	soft_height += paint_cover * (brush - 0.5) * 0.00012;

	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	vec3 normal_soft = pc_bump(normalize(NORMAL), VERTEX, soft_height);
	NORMAL = pc_slope_normal(normal_soft,
			normalize(to_view * axis_vector(plank_axis)),
			normalize(to_view * axis_vector(grain_axis)),
			slope_across, slope_along);

	// --- Finition ------------------------------------------------------------
	float raw_rough = mix(0.78, 0.6, late);
	float varnished_rough = mix(0.34, 0.24, varnish);
	float wood_rough = mix(raw_rough, varnished_rough, varnish);
	float paint_rough = 0.32 + 0.1 * brush;
	ALBEDO = pc_color_out(col);
	ROUGHNESS = clamp(mix(wood_rough, paint_rough, paint_cover) + 0.35 * clamp(grime, 0.0, 1.0) + 0.4 * gap_mask, 0.05, 1.0);
	SPECULAR = 0.5;
	CLEARCOAT = max(varnish * (1.0 - paint_cover) * 0.6, paint_cover * 0.35) * (1.0 - gap_mask);
	CLEARCOAT_ROUGHNESS = 0.12;
	AO = 1.0 - 0.5 * gap_mask;
}
