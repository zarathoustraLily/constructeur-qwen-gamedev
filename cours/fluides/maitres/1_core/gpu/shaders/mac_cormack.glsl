#[compute]
#version 450

// La correction de MacCormack : à partir du transport en avant (`forward`) et du retour (`backward`), retire la moitié de l'erreur,
// lue là d'où vient le courant.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D source;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D forward;
layout(r32f, set = 0, binding = 3) uniform restrict readonly image2D backward;
layout(r32f, set = 0, binding = 4) uniform restrict readonly image2D speed_x;
layout(r32f, set = 0, binding = 5) uniform restrict readonly image2D speed_y;

layout(push_constant, std430) uniform Constants {
	float delta;
} constants;

// La valeur de `source` dans la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float source_at(ivec2 cell) {
	return imageLoad(source, clamp(cell, ivec2(0), imageSize(source) - 1)).r;
}

// La valeur de `backward` dans la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float backward_at(ivec2 cell) {
	return imageLoad(backward, clamp(cell, ivec2(0), imageSize(backward) - 1)).r;
}

// La valeur de `source` au point `point` : un mélange bilinéaire.
float source_sample(vec2 point) {
	ivec2 corner = ivec2(floor(point));
	vec2 part = point - vec2(corner);
	float upper = mix(source_at(corner), source_at(corner + ivec2(1, 0)), part.x);
	float lower = mix(source_at(corner + ivec2(0, 1)), source_at(corner + ivec2(1, 1)), part.x);
	return mix(upper, lower, part.y);
}

// La valeur de `backward` au point `point` : un mélange bilinéaire.
float backward_sample(vec2 point) {
	ivec2 corner = ivec2(floor(point));
	vec2 part = point - vec2(corner);
	float upper = mix(backward_at(corner), backward_at(corner + ivec2(1, 0)), part.x);
	float lower = mix(backward_at(corner + ivec2(0, 1)), backward_at(corner + ivec2(1, 1)), part.x);
	return mix(upper, lower, part.y);
}

// `value` ramenée entre la plus petite et la plus grande des quatre cases de `source` autour de `point` : sans cette borne, la
// correction crée des valeurs qui n'existaient pas, et le calcul s'emballe.
float limited(float value, vec2 point) {
	ivec2 corner = ivec2(floor(point));
	float a = source_at(corner);
	float b = source_at(corner + ivec2(1, 0));
	float c = source_at(corner + ivec2(0, 1));
	float d = source_at(corner + ivec2(1, 1));
	return clamp(value, min(min(a, b), min(c, d)), max(max(a, b), max(c, d)));
}

// Une invocation par case : le transport en avant, plus la moitié de l'erreur, bornée.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	vec2 speed = vec2(imageLoad(speed_x, cell).r, imageLoad(speed_y, cell).r);
	vec2 origin = vec2(cell) - constants.delta * speed;
	float corrected = imageLoad(forward, cell).r + 0.5 * (source_sample(origin) - backward_sample(origin));
	imageStore(target, cell, vec4(limited(corrected, origin)));
}
