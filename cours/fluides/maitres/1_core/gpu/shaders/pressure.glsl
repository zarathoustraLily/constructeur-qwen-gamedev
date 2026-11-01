#[compute]
#version 450

// Une moitié d'une passe rouge-noir : seules les cases de la couleur `color` bougent. Elles ne se lisent pas entre elles : toutes
// peuvent tourner en même temps, sur la même image, sans se gêner.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D pressure;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D divergence;
layout(r8, set = 0, binding = 2) uniform restrict readonly image2D walls;

layout(push_constant, std430) uniform Constants {
	float relaxation;
	float color;
} constants;

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

// Une invocation par case de la couleur : vise la moyenne des voisines moins la divergence, et va au-delà de `relaxation`.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (((cell.x + cell.y + int(constants.color)) & 1) != 0 || is_solid(cell)) {
		return;
	}
	float here = imageLoad(pressure, cell).r;
	float around = seen(cell - ivec2(1, 0), here) + seen(cell + ivec2(1, 0), here)
			+ seen(cell - ivec2(0, 1), here) + seen(cell + ivec2(0, 1), here);
	float settled = (around - imageLoad(divergence, cell).r) * 0.25;
	imageStore(pressure, cell, vec4(mix(here, settled, constants.relaxation)));
}
