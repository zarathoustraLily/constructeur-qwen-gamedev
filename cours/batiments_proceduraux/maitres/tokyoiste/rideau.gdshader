// Rideau métallique d'une devanture : un simple rectangle devient un rideau à lames.
// {STATUS}
//
// Ce que le shader dessine :
//   - des lames horizontales bombées, avec l'ombre du joint entre deux lames ;
//   - la barre de seuil en bas et les deux coulisses sur les côtés ;
//   - la crasse : des coulures, et les traces de mains à hauteur d'homme.
//
// Comme la fenêtre, il part des UV et sert sur des rectangles instanciés. La teinte de la
// peinture vient de la couleur de l'instance : chaque boutique a la sienne, avec un seul
// matériau pour tout l'immeuble. Toutes les longueurs sont en mètres.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

group_uniforms slats;
/** Hauteur d'une lame. */
uniform float slat_height : hint_range(0.03, 0.15, 0.005) = 0.075;
/** Bombé d'une lame. */
uniform float slat_bulge : hint_range(0.0, 0.02, 0.001) = 0.006;
/** Largeur d'une coulisse, de chaque côté. */
uniform float guide_width : hint_range(0.02, 0.12, 0.005) = 0.05;

group_uniforms weathering;
/** Crasse et coulures. */
uniform float grime : hint_range(0.0, 1.0, 0.01) = 0.45;

varying flat vec2 v_size;
varying flat vec3 v_axis_x;
varying flat vec3 v_axis_y;
varying flat vec3 v_tint;
varying flat vec3 v_key;

void vertex() {
	// Taille du rideau en mètres : l'échelle de son instance.
	v_size = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz));
	// Ses axes, dans l'espace de la caméra : il en faut pour pencher la normale.
	v_axis_x = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz);
	v_axis_y = normalize((VIEW_MATRIX * vec4(MODEL_MATRIX[1].xyz, 0.0)).xyz);
	// La teinte de la peinture : la couleur que le script a donnée à l'instance.
	v_tint = COLOR.rgb;
	// Sa position : la clé des tirages, pour que deux rideaux n'aient pas les mêmes taches.
	v_key = MODEL_MATRIX[3].xyz;
}

void fragment() {
	vec2 size = v_size;
	vec2 q = vec2(UV.x * size.x, (1.0 - UV.y) * size.y);
	float fw = max(fwidth(q.x), fwidth(q.y));
	vec2 offset = vec2(pc_hash3(v_key * 3.0), pc_hash3(v_key * 3.0 + 9.0)) * 40.0;

	// --- Lames -------------------------------------------------------------------
	// Les lames se comptent depuis le haut : c'est de là que le rideau se déroule.
	float from_top = size.y - q.y;
	float slat = floor(from_top / slat_height);
	float in_slat = fract(from_top / slat_height);
	// Profil d'une lame : un arc. Sa pente est la dérivée de l'arc, et c'est elle qui penche
	// la normale. De loin, une lame est plus fine que le pixel : le relief s'efface.
	float relief_fade = 1.0 - smoothstep(0.2, 0.7, fw / slat_height);
	float slope = -slat_bulge * PI * cos(PI * in_slat) / slat_height * relief_fade;
	// Ombre du joint : le bas de chaque lame recouvre le haut de la suivante.
	float joint = (1.0 - smoothstep(0.0, 0.12, in_slat)) * relief_fade;

	// --- Barre de seuil et coulisses -------------------------------------------------
	float bottom_bar = 1.0 - pc_step(0.09, q.y, fw);
	float guides = 1.0 - pc_step(guide_width, min(q.x, size.x - q.x), fw);
	float flat_part = max(bottom_bar, guides);

	// --- Couleur ---------------------------------------------------------------------
	vec3 col = v_tint;
	// Chaque lame a pris la peinture un peu différemment.
	col *= 1.0 + (pc_hash1(slat * 3.0 + offset.x) - 0.5) * 0.06 * relief_fade;
	col *= 1.0 - 0.35 * joint;
	// Coulures : un bruit étiré vers le bas, comme sur les murs.
	float run = pc_fbm2(vec2((q.x + offset.x) * 9.0, (q.y + offset.y) * 0.5), 3, max(fw * 9.0, fw * 0.5));
	float veil = pc_fbm2((q + offset) * 0.8, 3, fw * 0.8);
	// Les mains et les épaules salissent le rideau entre 0,8 m et 1,6 m du sol.
	float touched = exp(-pow((q.y - 1.2) / 0.45, 2.0)) * 0.5;
	float dirt = clamp(grime * (0.5 * smoothstep(0.45, 0.8, run) + 0.5 * veil + touched * veil), 0.0, 1.0);
	col = mix(col, col * vec3(0.45, 0.44, 0.42), dirt);
	// La pluie rejaillit sur le bas.
	col = mix(col, col * vec3(0.5, 0.48, 0.44), 0.5 * exp(-q.y / 0.3));
	// Coulisses et barre de seuil : de l'aluminium nu.
	col = mix(col, vec3(0.55, 0.56, 0.57), guides);
	col = mix(col, col * 0.85, bottom_bar * (1.0 - guides));

	NORMAL = pc_slope_normal(normalize(NORMAL), v_axis_x, v_axis_y, 0.0, slope * (1.0 - flat_part));
	ALBEDO = pc_color_out(col);
	ROUGHNESS = clamp(0.5 + 0.35 * dirt, 0.0, 1.0);
	METALLIC = mix(0.25, 0.6, guides);
	SPECULAR = 0.5;
}
