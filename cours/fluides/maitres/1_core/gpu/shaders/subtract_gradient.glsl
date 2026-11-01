#[compute]
#version 450

// Retire à la vitesse la pente de la pression : il reste un écoulement sans divergence. Un mur compte pour la pression de la case.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D speed_x;
layout(r32f, set = 0, binding = 1) uniform restrict image2D speed_y;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D pressure;
layout(r8, set = 0, binding = 3) uniform restrict readonly image2D walls;

// Vrai si la case `cell` est pleine, ou hors de la grille.
bool is_solid(ivec2 cell) {
	if (any(lessThan(cell, ivec2(0))) || any(greaterThanEqual(cell, imageSize(walls)))) {
		return true;
	}
	return imageLoad(walls, cell).r > 0.0;
}

// La pression vue depuis une case voisine : celle de `cell`, ou `here` si c'est un mur.
float seen(ivec2 cell, float here) {
	return is_solid(cell) ? here : imageLoad(pressure, cell).r;
}

// Une invocation par case libre : la pente sur les deux axes, retirée de la vitesse.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (is_solid(cell)) {
		return;
	}
	float here = imageLoad(pressure, cell).r;
	float across = seen(cell + ivec2(1, 0), here) - seen(cell - ivec2(1, 0), here);
	float down = seen(cell + ivec2(0, 1), here) - seen(cell - ivec2(0, 1), here);
	imageStore(speed_x, cell, vec4(imageLoad(speed_x, cell).r - 0.5 * across));
	imageStore(speed_y, cell, vec4(imageLoad(speed_y, cell).r - 0.5 * down));
}
