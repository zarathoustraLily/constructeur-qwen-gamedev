#[compute]
#version 450

// Une moitié d'une passe rouge-noir en 3D : le damier devient un jeu de cubes, chaque case a six voisines, toutes de l'autre couleur.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(r32f, set = 0, binding = 0) uniform restrict image3D pressure;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image3D divergence;

layout(push_constant, std430) uniform Constants {
	float relaxation;
	float color;
} constants;

// La pression vue depuis une case voisine : celle de `cell`, ou `here` hors de la grille, où la vitesse est nulle.
float seen(ivec3 cell, float here) {
	if (any(lessThan(cell, ivec3(0))) || any(greaterThanEqual(cell, imageSize(pressure)))) {
		return here;
	}
	return imageLoad(pressure, cell).r;
}

// Une invocation par case de la couleur : vise la moyenne des six voisines moins la divergence, et va au-delà de `relaxation`.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (((cell.x + cell.y + cell.z + int(constants.color)) & 1) != 0 || any(greaterThanEqual(cell, imageSize(pressure)))) {
		return;
	}
	float here = imageLoad(pressure, cell).r;
	float around = seen(cell - ivec3(1, 0, 0), here) + seen(cell + ivec3(1, 0, 0), here)
			+ seen(cell - ivec3(0, 1, 0), here) + seen(cell + ivec3(0, 1, 0), here)
			+ seen(cell - ivec3(0, 0, 1), here) + seen(cell + ivec3(0, 0, 1), here);
	float settled = (around - imageLoad(divergence, cell).r) / 6.0;
	imageStore(pressure, cell, vec4(mix(here, settled, constants.relaxation)));
}
