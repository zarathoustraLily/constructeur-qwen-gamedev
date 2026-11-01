shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

// Un flipbook sur un plan tourné vers la caméra. Entre deux images, on mélange : sans cela, on voit les images se suivre.

// La planche : une opacité par pixel.
uniform sampler2D flipbook : repeat_disable, filter_linear;
// Le nombre d'images sur une ligne.
uniform int columns = 4;
// Le nombre de lignes.
uniform int rows = 4;
// L'image à montrer : sa partie entière est l'image, sa partie fractionnaire le mélange avec la suivante (Flipbook.frame_at).
uniform float frame = 0.0;
// La couleur de la fumée.
uniform vec3 smoke_color : source_color = vec3(0.8);

// Le plan garde sa place et sa taille, mais prend l'orientation de la caméra.
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

// L'opacité de l'image `index` au point `uv` du plan (Flipbook.uv_rect).
float opacity_of(float index, vec2 uv) {
	vec2 cell = vec2(mod(index, float(columns)), floor(index / float(columns)));
	return texture(flipbook, (cell + uv) / vec2(float(columns), float(rows))).r;
}

void fragment() {
	float first = floor(frame);
	float second = mod(first + 1.0, float(columns * rows));
	ALBEDO = smoke_color;
	ALPHA = mix(opacity_of(first, UV), opacity_of(second, UV), fract(frame));
}
