// La traçante d'un tir : un seul plan étiré derrière le projectile, sa tête à l'origine du nœud (Z = 0), sa queue à
// Z = 1, la longueur portée par l'échelle Z du nœud. Le plan pivote autour de son axe pour toujours faire face à la
// caméra : il est tourné sommet par sommet, parce que de près, le regard change beaucoup le long de la traçante. Un fil
// blanc-jaune dans un halo orangé, en pointe et vif à la tête, effacé à la queue, un peu plus large au loin pour ne pas
// clignoter, éteint tout près de la caméra. Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

// La couleur du fil, au centre.
uniform vec3 core_color : source_color = vec3(1.0, 0.92, 0.72);
// La couleur du halo.
uniform vec3 halo_color : source_color = vec3(1.0, 0.42, 0.08);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 7.0;
// La largeur de la traçante, en mètres.
uniform float width : hint_range(0.01, 2.0) = 0.26;
// La largeur gagnée par mètre de distance à la caméra, en part de la largeur.
uniform float far_widening : hint_range(0.0, 0.2) = 0.03;
// La part de la largeur occupée par le fil.
uniform float core_width : hint_range(0.01, 1.0) = 0.22;
// La part de la longueur sur laquelle la tête s'affine en pointe.
uniform float head_taper : hint_range(0.001, 0.5) = 0.06;
// Plus c'est grand, plus la queue s'efface tôt.
uniform float tail_fade : hint_range(0.1, 8.0) = 1.8;
// Les distances à la caméra (en mètres) entre lesquelles elle passe d'éteinte à pleine.
uniform float near_fade_start : hint_range(0.0, 5.0) = 0.8;
uniform float near_fade_end : hint_range(0.0, 10.0) = 2.5;

varying float along;

void vertex() {
	along = VERTEX.z;
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, VERTEX.z, 1.0)).xyz;
	vec3 axis = normalize(MODELVIEW_MATRIX[2].xyz);
	vec3 side = normalize(cross(axis, center));
	VERTEX = center + side * VERTEX.x * width * (1.0 + length(center) * far_widening);
}

void fragment() {
	float across = abs(UV.x * 2.0 - 1.0) / max(sqrt(clamp(along / head_taper, 0.0, 1.0)), 0.001);
	across = min(across, 1.0);
	float halo = (1.0 - across) * (1.0 - across);
	float core = smoothstep(core_width, 0.0, across);
	float body = pow(clamp(1.0 - along, 0.0, 1.0), tail_fade);
	ALBEDO = (halo_color * halo + core_color * core) * intensity;
	ALPHA = clamp(body * (halo + core), 0.0, 1.0) * smoothstep(near_fade_start, near_fade_end, -VERTEX.z);
}
