// Une boule de feu : un disque tourné vers la caméra, où deux couches de bruit filent du centre vers le bord, en
// coordonnées polaires : les langues de feu sortent du cœur. Le cœur est blanc-jaune, le corps orange, le bord rouge
// sombre. La taille vient de l'échelle du nœud. Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Le bruit des flammes (sans raccord).
uniform sampler2D noise : repeat_enable;
// La couleur du cœur.
uniform vec3 core_color : source_color = vec3(1.0, 0.9, 0.62);
// La couleur du corps.
uniform vec3 body_color : source_color = vec3(1.0, 0.42, 0.06);
// La couleur du bord.
uniform vec3 edge_color : source_color = vec3(0.65, 0.06, 0.01);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 1.5;
// La vitesse des flammes.
uniform float flow_speed : hint_range(0.0, 10.0) = 1.3;
// Combien le bruit ronge le bord.
uniform float tongues : hint_range(0.0, 2.0) = 0.95;

void vertex() {
	float size = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	VERTEX *= size;
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float radius = length(centered);
	float turn = atan(centered.y, centered.x) / 6.28318;
	float wide = texture(noise, vec2(turn * 2.0, radius * 0.6 - TIME * flow_speed)).r;
	float fine = texture(noise, vec2(turn * 5.0, radius * 1.2 - TIME * flow_speed * 1.7)).r;
	float flame = wide * 0.65 + fine * 0.35;
	float body = 1.0 - radius + (flame - 0.5) * tongues * radius;
	vec3 color = mix(edge_color, body_color, smoothstep(0.0, 0.4, body));
	ALBEDO = mix(color, core_color, smoothstep(0.55, 0.9, body)) * intensity;
	ALPHA = smoothstep(0.0, 0.22, body);
}
