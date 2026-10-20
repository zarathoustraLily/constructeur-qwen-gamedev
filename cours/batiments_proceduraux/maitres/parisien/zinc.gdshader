// Zinc de toiture parisienne, entièrement calculé.
// {STATUS}
//
// Ce que le shader dessine :
//   - des feuilles posées à tasseaux : un couvre-joint en relief tous les « seam_spacing » ;
//   - des joints transversaux (agrafures), décalés d'une bande à l'autre ;
//   - une teinte gris-bleu qui varie d'une feuille à l'autre, une patine claire, des coulures ;
//   - une luminosité d'ensemble réglable, pour qu'un toit ne ressemble pas à son voisin ;
//   - un léger gondolement des feuilles, qui casse les reflets du ciel.
//
// C'est le shader de la pierre avec d'autres nombres : une grille (bandes et feuilles au lieu
// d'assises et de blocs), un tirage par case, des bruits étirés dans le sens de la pente, et un
// relief par pente exacte. Le motif part de la position : u le long de l'égout, v vers le
// faîte. Aucune UV n'est requise. Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms sheets;
/** Entraxe des tasseaux. */
uniform float seam_spacing : hint_range(0.3, 1.0, 0.01) = 0.52;
/** Largeur du couvre-joint. Vers 0.006 : joint debout. */
uniform float seam_width : hint_range(0.004, 0.08, 0.001) = 0.042;
/** Hauteur du tasseau. */
uniform float seam_height : hint_range(0.0, 0.08, 0.001) = 0.03;
/** Longueur d'une feuille le long de la pente. */
uniform float sheet_length : hint_range(0.5, 6.0, 0.05) = 1.95;
/** 0 : joints transversaux alignés. 1 : décalés d'une bande à l'autre. */
uniform float stagger : hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms colour;
uniform vec3 zinc_color : source_color = vec3(0.43, 0.45, 0.47);
uniform vec3 patina_color : source_color = vec3(0.62, 0.65, 0.67);
uniform vec3 dirt_color : source_color = vec3(0.19, 0.19, 0.18);
/** Luminosité d'ensemble. Sous 1 : vieux zinc sombre. Au-dessus : zinc récent, clair. */
uniform float brightness : hint_range(0.5, 1.5, 0.01) = 1.0;
/** Écart de teinte d'une feuille à l'autre. */
uniform float sheet_variation : hint_range(0.0, 1.0, 0.01) = 0.55;
/** Voile clair de patine. */
uniform float patina : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Coulures le long de la pente. */
uniform float streaks : hint_range(0.0, 1.0, 0.01) = 0.45;
/** Encrassement au pied des tasseaux et des joints. */
uniform float dirt : hint_range(0.0, 1.0, 0.01) = 0.4;

group_uniforms surface;
uniform float roughness_base : hint_range(0.05, 1.0, 0.01) = 0.6;
/** Part de reflet métallique. Le zinc patiné est presque mat : rester sous 0.6. */
uniform float metallic_base : hint_range(0.0, 1.0, 0.01) = 0.35;
/** Gondolement des feuilles. */
uniform float oil_canning : hint_range(0.0, 1.0, 0.01) = 0.5;
//@ 11+
/** Décalage du motif, en mètres : deux toits voisins n'ont pas les mêmes feuilles. */
uniform vec2 pattern_offset = vec2(0.0, 0.0);
//@ all

varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	// Position et normale dans le repère de l'immeuble, comme pour la pierre.
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

void fragment() {
	// --- Coordonnées de face -------------------------------------------------
	vec3 n = normalize(v_nrm);
	vec3 t;
	vec3 b;
	pc_face_frame(n, t, b);
//@ 9-10
	float u = dot(v_pos, t);
	float v = dot(v_pos, b);
//@ 11+
	float u = dot(v_pos, t) + pattern_offset.x;
	float v = dot(v_pos, b) + pattern_offset.y;
//@ all
	float fu = fwidth(u);
	float fv = fwidth(v);
	float fw = max(fu, fv);
	vec2 p = vec2(u, v);

	// --- Bandes et feuilles --------------------------------------------------
	float strip = floor(u / seam_spacing);
	float ul = u - strip * seam_spacing;
	float ds = min(ul, seam_spacing - ul);
	float sign_u = ul < 0.5 * seam_spacing ? 1.0 : -1.0;
	float h_strip = pc_hash1(strip * 3.0 + 11.0);

	float vv = (v + stagger * h_strip * sheet_length) / sheet_length;
	float sheet = floor(vv);
	float vl = (vv - sheet) * sheet_length;
	float to_joint = min(vl, sheet_length - vl);

	float h_sheet = pc_hash2(vec2(strip, sheet) + vec2(5.0, 91.0));
	float h_sheet2 = pc_rehash(h_sheet, 1.0);
	float h_sheet3 = pc_rehash(h_sheet, 2.0);

	// --- Relief franc : tasseaux et agrafures, par pente exacte --------------
	// Les rampes font au moins deux pixels : en dessous, le relief scintille.
	float half_seam = 0.5 * seam_width;
	float side = min(0.3 * seam_width, 0.008);
	float ramp_slope;
	float cap = 1.0 - pc_ramp_d(half_seam - side, half_seam, ds, 2.0 * fu, ramp_slope);
	float slope_u = -seam_height * ramp_slope * sign_u;

	// Agrafure : la feuille du dessus recouvre celle du dessous par un pli.
	float fold_rise = pc_ramp_d(0.0, 0.0025, vl, 2.0 * fv, ramp_slope);
	float fold_decay = exp(-vl / 0.014);
	float slope_v = 0.003 * fold_decay * (ramp_slope - fold_rise / 0.014) * (1.0 - cap);

	// --- Relief doux : gondolement et grain ----------------------------------
	// Chaque feuille se bombe ou se creuse un peu. Le gondolement s'annule aux
	// extrémités de la feuille, là où elle est tenue.
	float across = clamp((ul - half_seam) / max(seam_spacing - seam_width, 0.0001), 0.0, 1.0);
	float along = vl / sheet_length;
	float held = smoothstep(0.0, 0.14, to_joint) * (1.0 - cap);
	float bulge = sin(3.14159 * across) * (0.55 + 0.45 * sin(6.28318 * (along * (1.0 + 2.0 * h_sheet2) + h_sheet3)));
	float waves = pc_fbm2(p * 2.6 + h_sheet * 31.0, 2, fw * 2.6) - 0.5;
	float micro = pc_fbm2(p * 140.0, 2, fw * 140.0);
	float soft_height = oil_canning * held * ((h_sheet - 0.5) * 0.006 * bulge + waves * 0.003) + (micro - 0.5) * 0.0002;

	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	vec3 normal_soft = pc_bump(normalize(NORMAL), VERTEX, soft_height);
	NORMAL = pc_slope_normal(normal_soft, normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);

	// --- Couleur -------------------------------------------------------------
	vec3 patina_tint = pc_color_in(patina_color);
	vec3 col = pc_color_in(zinc_color) * (1.0 + (h_sheet - 0.5) * 0.3 * sheet_variation);
	col = mix(col, col * vec3(0.95, 0.99, 1.05), h_sheet2 * sheet_variation);
	col = mix(col, col * vec3(1.04, 1.0, 0.95), h_sheet3 * sheet_variation * 0.6);

	// Patine : un niveau par feuille, plus un voile doux étiré dans la pente.
	float veil = pc_fbm2(vec2(u * 5.5, v * 1.3) + h_sheet * 17.0, 4, max(fu * 5.5, fv * 1.3));
	float patina_mask = patina * clamp(0.25 + 0.55 * h_sheet3 + 0.9 * (veil - 0.5), 0.0, 1.0);
	col = mix(col, patina_tint, patina_mask * 0.75);

	// Coulures dans le sens de la pente. Elles partent des agrafures : l'eau entraîne
	// la saleté du pli et la dépose sur la feuille du dessous.
	float run = pc_fbm2(vec2(u * 16.0, v * 0.3) + h_strip * 9.0, 4, max(fu * 16.0, fv * 0.3));
	float run2 = pc_fbm2(vec2(u * 41.0, v * 0.7) + 3.0, 3, max(fu * 41.0, fv * 0.7));
	float below_joint = exp(-(sheet_length - vl) / 0.55);
	float light_run = streaks * smoothstep(0.52, 0.85, run) * (0.35 + 0.65 * run2) * (0.35 + 0.65 * below_joint);
	float dark_run = streaks * smoothstep(0.55, 0.9, 1.0 - run) * (0.35 + 0.65 * (1.0 - run2)) * (0.25 + 0.75 * below_joint);
	col = mix(col, patina_tint * 1.05, light_run * 0.55);
	col = mix(col, col * 0.66, dark_run * 0.6);

	// Encrassement au pied des tasseaux et de part et d'autre des agrafures.
	float foot = exp(-max(ds - half_seam, 0.0) / 0.03) * (1.0 - cap);
	float joint = exp(-to_joint / 0.035);
	float grime_noise = pc_fbm2(p * 9.0 + 50.0, 3, fw * 9.0);
	float broad = smoothstep(0.5, 0.85, pc_fbm2(p * 0.55 + 23.0, 3, fw * 0.55));
	float dirt_mask = clamp(dirt * ((foot * 0.85 + joint * 0.7) * (0.3 + 0.7 * grime_noise) + 0.35 * broad), 0.0, 1.0);
	col = mix(col, pc_color_in(dirt_color), dirt_mask * 0.7);

	// Le dessus du couvre-joint, plus exposé, est un peu plus clair.
	col *= 1.0 + 0.06 * cap;
	col *= 1.0 + (micro - 0.5) * 0.05;

	ALBEDO = pc_color_out(min(col * brightness, vec3(1.0)));
	ROUGHNESS = clamp(roughness_base + 0.2 * patina_mask + 0.3 * dirt_mask + (h_sheet2 - 0.5) * 0.16 * sheet_variation + (micro - 0.5) * 0.08, 0.12, 0.97);
	METALLIC = clamp(metallic_base * (1.0 - 0.6 * patina_mask) * (1.0 - 0.8 * dirt_mask), 0.0, 1.0);
	SPECULAR = 0.5;
	AO = 1.0 - 0.35 * foot;
	AO_LIGHT_AFFECT = 0.25;
}
