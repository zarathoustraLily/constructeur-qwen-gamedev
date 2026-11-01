shader_type canvas_item;

// Une crue vue du ciel : la texture ne contient qu'une profondeur par case ; le sol vient d'une image, et l'eau le recouvre.

// La hauteur du sol.
uniform sampler2D ground_map : repeat_disable, filter_linear;
// La hauteur du sol qui donne la couleur la plus claire.
uniform float highest = 2.0;
// La profondeur à laquelle on ne voit plus le fond.
uniform float deepest = 0.6;
// La couleur des terres basses.
uniform vec3 low_color : source_color = vec3(0.2, 0.3, 0.12);
// La couleur des sommets.
uniform vec3 high_color : source_color = vec3(0.6, 0.55, 0.45);
// La couleur de l'eau.
uniform vec3 water_color : source_color = vec3(0.05, 0.22, 0.4);

void fragment() {
	float water = texture(TEXTURE, UV).r;
	float land = clamp(texture(ground_map, UV).r / highest, 0.0, 1.0);
	vec3 color = mix(low_color, high_color, land);
	COLOR = vec4(mix(color, water_color, clamp(water / deepest, 0.0, 0.9)), 1.0);
}
