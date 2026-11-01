shader_type spatial;
render_mode blend_premul_alpha, depth_draw_never, specular_disabled, ambient_light_disabled;

// Une fumée cuite qui reçoit la lumière du jeu. `fragment()` lit les six réponses, `light()` les mêle pour chaque lumière (SixWay.lit).
// Le mélange est prémultiplié : les images cuites tiennent déjà compte de l'opacité.

// Droite, haut, arrière, et l'opacité.
uniform sampler2D first_lights : repeat_disable, filter_linear;
// Gauche, bas, avant.
uniform sampler2D second_lights : repeat_disable, filter_linear;
// La couleur de la fumée.
uniform vec3 smoke_color : source_color = vec3(0.8);

varying vec3 first_seen;
varying vec3 second_seen;

// Le plan garde sa place et sa taille, mais prend l'orientation de la caméra : les axes du plan sont ceux de LIGHT.
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 first = texture(first_lights, UV);
	first_seen = first.rgb;
	second_seen = texture(second_lights, UV).rgb;
	ALBEDO = smoke_color;
	ALPHA = first.a;
}

// Une fois par lumière : chaque axe prend l'image de son côté, et les poids sont les carrés de LIGHT.
void light() {
	float side = LIGHT.x > 0.0 ? first_seen.r : second_seen.r;
	float height = LIGHT.y > 0.0 ? first_seen.g : second_seen.g;
	float depth = LIGHT.z > 0.0 ? second_seen.b : first_seen.b;
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * dot(LIGHT * LIGHT, vec3(side, height, depth)) / PI;
}
