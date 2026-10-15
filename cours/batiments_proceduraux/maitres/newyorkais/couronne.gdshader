// Les matières du couronnement : cuivre vert-de-grisé, acier inoxydable, ventelles de métal,
// bois du château d'eau. Un seul shader, quatre jeux de nombres : « finish » choisit la matière.
// {STATUS}
//
// Ce que le shader dessine, d'après la position du pixel, en mètres, comme la brique :
//   - le cuivre : des bandes de tôle à joints debout, et le vert-de-gris, la patine verte que
//     le cuivre prend à l'air avec les années, plus épais en coulures sous les joints ;
//   - l'acier inoxydable : des côtes verticales qui accrochent la lumière ;
//   - les ventelles : des lames horizontales inclinées, qui cachent les machines du toit et
//     laissent passer l'air ;
//   - le bois du château d'eau : des douelles verticales, serrées par des cerclages d'acier.
// La nuit, des projecteurs éclairent les métaux du couronnement depuis sa base.
//
// Les cotes sont plausibles ; elles ne sont pas relevées sur une tour réelle.
shader_type spatial;

#include "res://6_assets/Shader/Procedural/procedural_commun.gdshaderinc"

const int FINISH_COPPER = 0;
const int FINISH_STEEL = 1;
const int FINISH_LOUVRES = 2;
const int FINISH_WOOD = 3;

group_uniforms finish_settings;
/** La matière : cuivre, acier, ventelles ou bois. */
uniform int finish : hint_enum("Cuivre", "Acier", "Ventelles", "Bois") = 0;
uniform vec3 base_color : source_color = vec3(0.70, 0.42, 0.22);
/** Écart entre deux joints debout, deux côtes, deux lames ou deux douelles. */
uniform float pitch : hint_range(0.05, 1.0, 0.005) = 0.45;
/** Cuivre : part de vert-de-gris, de 0 (cuivre neuf) à 1 (tout vert). */
uniform float patina : hint_range(0.0, 1.0, 0.01) = 0.75;
uniform vec3 patina_color : source_color = vec3(0.36, 0.62, 0.52);
/** Bois : rayon de la cuve, pour compter les douelles sur son tour, et hauteur de son fond. */
uniform float tank_radius : hint_range(0.5, 6.0, 0.01) = 2.5;
uniform float tank_base = 0.0;

group_uniforms lighting;
/** 0 : jour. 1 : nuit. */
uniform float night : hint_range(0.0, 1.0, 0.01) = 0.0;
/** Force des projecteurs, la nuit. 0 : pas de projecteurs. */
uniform float flood_energy : hint_range(0.0, 4.0, 0.01) = 0.0;
uniform vec3 flood_color : source_color = vec3(1.0, 0.86, 0.62);
/** Hauteur du pied du couronnement (là où sont les projecteurs), et hauteur qu'ils éclairent. */
uniform float flood_base = 0.0;
uniform float flood_reach : hint_range(1.0, 200.0, 0.5) = 40.0;

varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	v_pos = VERTEX;
	v_nrm = NORMAL;
}

void fragment() {
	// --- Coordonnées de face, comme pour la brique ------------------------------------------
	vec3 n = normalize(v_nrm);
	vec3 t;
	vec3 b;
	pc_face_frame(n, t, b);
	float u = dot(v_pos, t);
	float v = dot(v_pos, b);
	float fu = fwidth(u);
	float fv = fwidth(v);
	float fw = max(fu, fv);
	vec3 col = pc_color_in(base_color);
	float metallic = 0.0;
	float roughness = 0.6;
	// Pente du relief le long de u : de quoi pencher la normale aux joints et aux côtes.
	float slope_u = 0.0;
	float slope_v = 0.0;

	if (finish == FINISH_COPPER) {
		// Joints debout : une ligne en relief toutes les « pitch » mètres.
		float to_seam = abs(fract(u / pitch + 0.5) - 0.5) * pitch;
		float seam = pc_band(to_seam, 0.012, fu);
		// Le vert-de-gris : un bruit étiré vers le bas, plus fort sous les joints, où l'eau
		// coule. Seuillé, il fait des plaques ; « patina » décale le seuil.
		float drip = pc_fbm2(vec2(u * 3.0, v * 0.35), 4, max(fu * 3.0, fv * 0.35));
		float near_seam = exp(-to_seam / 0.06);
		float green = smoothstep(0.45, 0.6, drip + 0.25 * near_seam + patina - 0.6);
		col = mix(col, pc_color_in(patina_color), green);
		col *= 1.0 - 0.25 * seam;
		metallic = mix(0.75, 0.0, green);
		roughness = mix(0.35, 0.8, green);
		slope_u = 0.6 * seam * sign(fract(u / pitch + 0.5) - 0.5);
	} else if (finish == FINISH_STEEL) {
		// Côtes : un profil en dents de scie très doux ; chaque côte renvoie la lumière un peu
		// autrement que sa voisine.
		float k = fract(u / pitch);
		float rib = smoothstep(0.0, 0.5, k) - smoothstep(0.5, 1.0, k);
		float fade = 1.0 - smoothstep(0.2, 0.6, fu / pitch);
		col *= 0.92 + 0.12 * rib * fade;
		metallic = 0.65;
		roughness = 0.4;
		slope_u = 0.5 * (k < 0.5 ? 1.0 : -1.0) * fade;
	} else if (finish == FINISH_LOUVRES) {
		// Ventelles : une lame tous les « pitch » mètres, inclinée vers le bas. Le haut de chaque
		// lame est clair, l'interstice dessous est sombre.
		float k = fract(v / pitch);
		float fade = 1.0 - smoothstep(0.25, 0.7, fv / pitch);
		float gap = (1.0 - smoothstep(0.0, 0.18, k)) * fade;
		col *= mix(1.0, 0.25, gap) * (0.85 + 0.15 * k);
		metallic = 0.6;
		roughness = 0.45;
		slope_v = -0.8 * fade;
	} else {
		// Bois du château d'eau. Ses facettes ont des normales rayonnantes : leur angle autour de
		// l'axe vertical donne le numéro de la douelle, sans connaître le centre de la cuve.
		float angle = atan(n.z, n.x);
		float around = angle * tank_radius / pitch;
		float stave = floor(around);
		float hs = pc_hash2(vec2(stave, 3.0));
		float stave_fade = 1.0 - smoothstep(0.3, 0.8, fwidth(around));
		col *= mix(1.0, 0.82 + 0.3 * hs, stave_fade);
		// Le grain du bois, étiré le long de la douelle.
		col *= 0.9 + 0.2 * pc_fbm2(vec2(around * 4.0, v_pos.y * 0.6), 3, fw * 4.0);
		// Le joint entre deux douelles : un trait sombre.
		float to_joint = 0.5 - abs(fract(around) - 0.5);
		col = mix(col, col * 0.6, pc_band(to_joint, 0.03, fwidth(around)) * stave_fade);
		// Les cerclages : une bande d'acier sombre tous les 40 cm, plus serrés en bas, là où
		// l'eau pousse le plus fort.
		float y = v_pos.y - tank_base;
		float hoop_pitch = mix(0.3, 0.55, clamp(y / 5.0, 0.0, 1.0));
		float hoop = pc_band(abs(fract(y / hoop_pitch + 0.5) - 0.5) * hoop_pitch, 0.02, fwidth(y));
		col = mix(col, vec3(0.12, 0.11, 0.10), hoop);
		metallic = 0.6 * hoop;
		roughness = mix(0.85, 0.5, hoop);
	}

	// --- Relief, sorties ---------------------------------------------------------------
	mat3 to_view = mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX);
	NORMAL = pc_slope_normal(normalize(NORMAL), normalize(to_view * t), normalize(to_view * b), slope_u, slope_v);
	ALBEDO = pc_color_out(col);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	// La nuit, les projecteurs posés au pied du couronnement l'éclairent par en dessous : la
	// lumière faiblit en montant.
	float rise = clamp((v_pos.y - flood_base) / flood_reach, 0.0, 1.0);
	float flood = flood_energy * night * (1.0 - 0.75 * rise);
	EMISSION = pc_color_out(col * pc_color_in(flood_color) * flood);
}
