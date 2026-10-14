// Béton brut de décoffrage, entièrement calculé : aucune image.
// {STATUS}
//
// Ce que le shader dessine :
//   - l'empreinte des panneaux de coffrage : un quadrillage de joints fins, et un gris un peu
//     différent d'un panneau à l'autre ;
//   - les trous d'écarteur : les petits cônes laissés par les tiges qui tenaient le coffrage ;
//   - les reprises de bétonnage : une ligne à chaque étage, là où une coulée s'est arrêtée ;
//   - des salissures : voile, coulures sous les arêtes, rejaillissement en pied de mur.
//@ 11+ quiet
// Avec « formwork » à 0, il n'y a plus ni joints ni trous : c'est un enduit peint, uni.
//@ 13+ quiet
//
// Trois finesses de calcul (« quality »), comme le carrelage.
//@ all
//
// Mêmes recettes que le carrelage : une grille par floor(), une distance au motif, un
// filtrage par fwidth(). Seuls les nombres et le dessin changent. C'est le sens de cette
// étape : un deuxième matériau ne demande pas d'idée nouvelle.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms formwork;
/** Taille d'un panneau de coffrage : largeur, hauteur. */
uniform vec2 panel_size = vec2(1.8, 0.9);
/** Force de l'empreinte du coffrage : joints, trous, écarts de gris. 0 : mur lisse. */
uniform float formwork : hint_range(0.0, 1.0, 0.01) = 1.0;
/** Entraxe des trous d'écarteur : en largeur, en hauteur. */
uniform vec2 tie_spacing = vec2(0.6, 0.45);
/** Rayon d'un trou d'écarteur. */
uniform float tie_radius : hint_range(0.005, 0.04, 0.001) = 0.016;
/** Hauteur d'une coulée : une reprise de bétonnage tous les tant de mètres. 0 : aucune. */
uniform float lift_height : hint_range(0.0, 6.0, 0.05) = 3.0;

group_uniforms colour;
uniform vec3 concrete_color : source_color = vec3(0.62, 0.62, 0.60);
/** Écart de gris d'un panneau à l'autre. */
uniform float panel_variation : hint_range(0.0, 1.0, 0.01) = 0.4;

group_uniforms weathering;
/** Voile de crasse, par grandes plages. */
uniform float grime : hint_range(0.0, 1.0, 0.01) = 0.35;
/** Coulures de pluie. */
uniform float streaks : hint_range(0.0, 1.0, 0.01) = 0.5;
/** Salissure de rejaillissement en pied de mur. */
uniform float ground_dirt : hint_range(0.0, 1.0, 0.01) = 0.4;
//@ 11+
/** Décalage du motif, en mètres : deux immeubles voisins n'ont pas les mêmes taches. */
uniform vec2 pattern_offset = vec2(0.0, 0.0);
//@ 13+

group_uniforms performance;
/** Finesse du calcul. Basse : panneaux et grandes plages. Moyenne : en plus, coulures. Haute : tout. */
uniform int quality : hint_enum("Basse", "Moyenne", "Haute") = 2;
//@ all

varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	// Position et normale dans le repère de l'objet, en mètres, comme pour le carrelage.
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

void fragment() {
	// --- 1. Coordonnées de face ----------------------------------------------
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
//@ 13+
	bool medium = quality >= 1;
	bool high = quality >= 2;
//@ all

	// --- 2. Panneaux de coffrage -------------------------------------------------
	// Une grille, comme les carreaux, mais sans décalage : les joints s'alignent dans les
	// deux sens, et les trous d'écarteur avec eux.
	vec2 panel = floor(p / panel_size);
	vec2 in_panel = p - panel * panel_size;
	float dx = min(in_panel.x, panel_size.x - in_panel.x);
	float dy = min(in_panel.y, panel_size.y - in_panel.y);
	// Le joint entre deux panneaux laisse une fine balèvre, plus sombre.
	float joint_mask = max(pc_band(dx, 0.002, fu), pc_band(dy, 0.002, fv)) * formwork;
	float hp = pc_hash2(panel + vec2(5.0, 23.0));

	// --- 3. Trous d'écarteur -------------------------------------------------------
	// Le trou le plus proche : on ramène le pixel dans une cellule de la grille des trous, et
	// on mesure sa distance au centre de la cellule.
	vec2 to_tie = (fract(p / tie_spacing) - 0.5) * tie_spacing;
	float tie_distance = length(to_tie) - tie_radius;
	// De loin, un trou de 3 cm est plus petit que le pixel : il s'efface.
	float tie_fade = formwork * (1.0 - smoothstep(0.4, 1.5, fw / tie_radius));
	float tie_mask = (1.0 - pc_step(0.0, tie_distance, fw)) * tie_fade;
	// Le bord du trou est un cône : la normale penche vers son centre.
	float tie_slope = (1.0 - smoothstep(0.0, 0.006, abs(tie_distance + 0.004))) * 0.8 * tie_fade;
	vec2 tie_dir = to_tie / max(length(to_tie), 0.0001);

	// --- 4. Reprises de bétonnage ----------------------------------------------------
	float lift_mask = 0.0;
	float lift_tone = 0.0;
	if (lift_height > 0.0) {
		float lift = floor(v_pos.y / lift_height);
		float to_lift = abs(v_pos.y - (lift + 0.5) * lift_height);
		// Sur une face horizontale, la hauteur ne change pas : pas de ligne de reprise.
		lift_mask = pc_band(0.5 * lift_height - to_lift, 0.006, fv) * formwork * step(abs(n.y), 0.5);
		// Deux coulées n'ont jamais tout à fait le même gris.
		lift_tone = (pc_hash1(lift * 13.0 + 7.0) - 0.5) * formwork;
	}

	// --- 5. Relief ---------------------------------------------------------------------
	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	NORMAL = pc_slope_normal(normalize(NORMAL), normalize(to_view * t), normalize(to_view * b), tie_dir.x * tie_slope, tie_dir.y * tie_slope);

	// --- 6. Couleur ----------------------------------------------------------------------
	vec3 col = pc_color_in(concrete_color);
	// Chaque panneau de coffrage a bu l'eau du béton à sa façon : un gris par panneau.
	col *= 1.0 + ((hp - 0.5) * 0.14 * panel_variation + lift_tone * 0.08) * formwork;
//@ 9-12
	// Nuages : le béton n'est jamais uni.
	float broad = pc_fbm2(p * 0.7, 4, fw * 0.7);
	col *= 0.9 + 0.2 * broad;
	float fine = pc_fbm2(p * 22.0, 3, fw * 22.0);
	col *= 1.0 + (fine - 0.5) * 0.10;

	// --- 7. Salissures -----------------------------------------------------------------
	float veil = smoothstep(0.38, 0.75, pc_fbm2(p * 0.25 + vec2(11.0, 47.0), 4, fw * 0.25));
	float film = grime * (0.12 + 0.5 * veil);
	// Coulures : le béton est poreux, la pluie y laisse de longues traînées sombres.
	float runs = 0.0;
	if (streaks > 0.0) {
		float run = pc_fbm2(vec2(u * 7.0, v * 0.3), 4, max(fu * 7.0, fv * 0.3));
		float run_zone = smoothstep(0.3, 0.7, pc_fbm2(p * vec2(0.5, 0.25) + 31.0, 3, fw * 0.5));
		runs = streaks * smoothstep(0.48, 0.85, run) * run_zone;
	}
	float splash = exp(-max(v_pos.y, 0.0) / 0.4) * (0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2)));
//@ 13+
	// Nuages : le béton n'est jamais uni. Moins d'octaves en finesse basse ; le grain fin
	// seulement à partir de la finesse moyenne.
	float broad = pc_fbm2(p * 0.7, 2 + quality, fw * 0.7);
	col *= 0.9 + 0.2 * broad;
	float fine = 0.5;
	if (medium) {
		fine = pc_fbm2(p * 22.0, high ? 3 : 2, fw * 22.0);
	}
	col *= 1.0 + (fine - 0.5) * 0.10;

	// --- 7. Salissures -----------------------------------------------------------------
	float veil = smoothstep(0.38, 0.75, pc_fbm2(p * 0.25 + vec2(11.0, 47.0), 2 + quality, fw * 0.25));
	float film = grime * (0.12 + 0.5 * veil);
	// Coulures : le béton est poreux, la pluie y laisse de longues traînées sombres.
	float runs = 0.0;
	if (streaks > 0.0 && medium) {
		float run = pc_fbm2(vec2(u * 7.0, v * 0.3), 2 + quality, max(fu * 7.0, fv * 0.3));
		float run_zone = smoothstep(0.3, 0.7, pc_fbm2(p * vec2(0.5, 0.25) + 31.0, 1 + quality, fw * 0.5));
		runs = streaks * smoothstep(0.48, 0.85, run) * run_zone;
	}
	float splash = exp(-max(v_pos.y, 0.0) / 0.4);
	if (splash > 0.004 && medium) {
		splash *= 0.55 + 0.45 * pc_noise2(p * vec2(3.0, 1.2));
	}
//@ all
	float dirt = clamp(film + runs, 0.0, 1.0);
	col = mix(col, col * vec3(0.52, 0.51, 0.49), clamp(film, 0.0, 1.0));
	col = mix(col, col * vec3(0.50, 0.50, 0.50), clamp(runs, 0.0, 1.0));
	col = mix(col, col * vec3(0.50, 0.48, 0.43), ground_dirt * splash);

	// --- 8. Joints, trous et sorties -------------------------------------------------
	col *= 1.0 - 0.22 * joint_mask - 0.3 * lift_mask;
	col = mix(col, col * 0.25, tie_mask);
	ALBEDO = pc_color_out(col);
	ROUGHNESS = clamp(0.82 + 0.12 * dirt + 0.1 * (fine - 0.5), 0.0, 1.0);
	SPECULAR = 0.3;
	AO = 1.0 - 0.5 * tie_mask;
	AO_LIGHT_AFFECT = 0.35;
}
