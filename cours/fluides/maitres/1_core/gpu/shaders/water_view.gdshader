shader_type spatial;

// Une surface d'eau : la texture de la carte soulève les sommets du plan, et ses écarts donnent la pente de chaque pixel.

// La hauteur de l'eau, une valeur par case.
uniform sampler2D surface : repeat_disable, filter_linear;
// La hauteur à l'écran d'une unité de `surface`.
uniform float height_scale = 0.15;
// Le nombre de cases de la texture.
uniform vec2 cells = vec2(256.0);
// La taille d'une case à l'écran.
uniform float cell_size = 0.03;
// La couleur de l'eau.
uniform vec3 water_color : source_color = vec3(0.04, 0.2, 0.3);

void vertex() {
	VERTEX.y += texture(surface, UV).r * height_scale;
}

// La pente vient de l'écart entre les cases voisines : les mailles du plan sont trop grandes pour donner un reflet net.
void fragment() {
	vec2 step_size = 1.0 / cells;
	float left = texture(surface, UV - vec2(step_size.x, 0.0)).r;
	float right = texture(surface, UV + vec2(step_size.x, 0.0)).r;
	float above = texture(surface, UV - vec2(0.0, step_size.y)).r;
	float below = texture(surface, UV + vec2(0.0, step_size.y)).r;
	vec3 slope = normalize(vec3((left - right) * height_scale, 2.0 * cell_size, (above - below) * height_scale));
	NORMAL = normalize((VIEW_MATRIX * vec4(slope, 0.0)).xyz);
	ALBEDO = water_color;
	ROUGHNESS = 0.1;
}
