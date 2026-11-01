shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_front;

// La fumée d'un volume, rayon par rayon. La boîte n'est qu'une silhouette : chaque pixel lance un rayon dans le volume, le parcourt à
// petits pas et additionne ce qu'il y trouve. On dessine le dos de la boîte : la caméra peut ainsi entrer dans le volume.

// La fumée, un flottant par case.
uniform sampler3D volume : repeat_disable, filter_linear;
// La lumière retirée par unité de fumée et par longueur de boîte.
uniform float absorption = 8.0;
// La couleur de la fumée en pleine lumière.
uniform vec3 lit_color : source_color = vec3(0.9);
// La couleur de la fumée dans sa propre ombre.
uniform vec3 shadow_color : source_color = vec3(0.2, 0.22, 0.28);
// D'où vient la lumière, dans le repère de la boîte.
uniform vec3 light_direction = vec3(0.5, 1.0, 0.3);
// Le nombre de pas d'un rayon.
uniform int steps = 48;
// Le nombre de pas de chaque petit rayon vers la lumière.
uniform int light_steps = 6;

varying vec3 ray_origin;
varying vec3 ray_end;

// La caméra et le point de la boîte, dans le repère de la boîte, qui va de -0,5 à 0,5.
void vertex() {
	ray_origin = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	ray_end = VERTEX;
}

// Où le rayon entre dans la boîte et où il en sort : deux distances le long de `direction` (RayMarch.box_hits).
vec2 box_hits(vec3 origin, vec3 direction) {
	vec3 first = (-0.5 - origin) / direction;
	vec3 second = (0.5 - origin) / direction;
	vec3 near_planes = min(first, second);
	vec3 far_planes = max(first, second);
	return vec2(max(max(near_planes.x, max(near_planes.y, near_planes.z)), 0.0), min(far_planes.x, min(far_planes.y, far_planes.z)));
}

// La part de lumière qui arrive à `point`, à travers la fumée qui le sépare de la lumière.
float light_reaching(vec3 point, vec3 direction) {
	float spacing = box_hits(point, direction).y / float(light_steps);
	float matter = 0.0;
	for (int i = 0; i < light_steps; i++) {
		matter += texture(volume, point + direction * (float(i) + 0.5) * spacing + 0.5).r;
	}
	return exp(-absorption * matter * spacing);
}

// Le rayon, de l'entrée à la sortie : chaque pas retire une part de la lumière qui passe, et ajoute celle que la fumée renvoie.
void fragment() {
	vec3 direction = normalize(ray_end - ray_origin);
	vec3 to_light = normalize(light_direction);
	vec2 hits = box_hits(ray_origin, direction);
	float spacing = (hits.y - hits.x) / float(steps);
	float passing = 1.0;
	vec3 gathered = vec3(0.0);
	for (int i = 0; i < steps; i++) {
		vec3 point = ray_origin + direction * (hits.x + (float(i) + 0.5) * spacing);
		float matter = texture(volume, point + 0.5).r;
		if (matter > 0.0) {
			float taken = 1.0 - exp(-absorption * matter * spacing);
			gathered += passing * taken * mix(shadow_color, lit_color, light_reaching(point, to_light));
			passing *= 1.0 - taken;
		}
	}
	float opacity = 1.0 - passing;
	ALPHA = opacity;
	ALBEDO = gathered / max(opacity, 0.001);
}
