#[compute]
#version 450

// Range les particules dans leurs cases, toutes en même temps. Sur le processeur, on lit la tête de la liste puis on l'écrit. Ici, deux
// invocations pourraient lire la même tête et perdre une particule : `atomicExchange` fait les deux d'un seul geste.
layout(local_size_x = 64) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Positions {
	vec2 data[];
} positions;

layout(set = 0, binding = 1, std430) restrict buffer Heads {
	int data[];
} heads;

layout(set = 0, binding = 2, std430) restrict writeonly buffer Links {
	int data[];
} links;

layout(push_constant, std430) uniform Constants {
	float radius;
	float columns;
	float rows;
} constants;

// La case de la grille de voisinage où tombe le point `place`.
ivec2 cell_of(vec2 place) {
	return clamp(ivec2(floor(place / constants.radius)), ivec2(0), ivec2(constants.columns, constants.rows) - 1);
}

// Une invocation par particule : elle devient la tête de sa case, et l'ancienne tête devient sa suivante.
void main() {
	uint i = gl_GlobalInvocationID.x;
	if (i >= positions.data.length()) {
		return;
	}
	ivec2 cell = cell_of(positions.data[i]);
	int slot = cell.y * int(constants.columns) + cell.x;
	links.data[i] = atomicExchange(heads.data[slot], int(i));
}
