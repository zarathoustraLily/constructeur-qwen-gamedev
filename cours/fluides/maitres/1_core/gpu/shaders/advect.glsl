#[compute]
#version 450

// Le transport sur la carte : chaque case reçoit la valeur de `source` à l'endroit d'où vient le courant, `delta` secondes plus tôt.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D source;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D speed_x;
layout(r32f, set = 0, binding = 3) uniform restrict readonly image2D speed_y;

layout(push_constant, std430) uniform Constants {
	float delta;
} constants;

// La valeur de `source` dans la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float source_at(ivec2 cell) {
	return imageLoad(source, clamp(cell, ivec2(0), imageSize(source) - 1)).r;
}

// La valeur de `source` au point `point`, entre quatre cases : un mélange bilinéaire. Une image ne se filtre pas toute seule.
float source_sample(vec2 point) {
	ivec2 corner = ivec2(floor(point));
	vec2 part = point - vec2(corner);
	float upper = mix(source_at(corner), source_at(corner + ivec2(1, 0)), part.x);
	float lower = mix(source_at(corner + ivec2(0, 1)), source_at(corner + ivec2(1, 1)), part.x);
	return mix(upper, lower, part.y);
}

// Une invocation par case, en remontant le courant. Les groupes débordent d'une grille qui n'est pas un multiple de 8 : on s'y arrête.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	vec2 speed = vec2(imageLoad(speed_x, cell).r, imageLoad(speed_y, cell).r);
	imageStore(target, cell, vec4(source_sample(vec2(cell) - constants.delta * speed)));
}
