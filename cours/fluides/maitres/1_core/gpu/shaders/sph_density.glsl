#[compute]
#version 450

// La densité et la pression de chaque particule, d'après ses voisines des neuf cases autour d'elle.
layout(local_size_x = 64) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Positions {
	vec2 data[];
} positions;

layout(set = 0, binding = 1, std430) restrict readonly buffer Heads {
	int data[];
} heads;

layout(set = 0, binding = 2, std430) restrict readonly buffer Links {
	int data[];
} links;

layout(set = 0, binding = 3, std430) restrict writeonly buffer Densities {
	float data[];
} densities;

layout(set = 0, binding = 4, std430) restrict writeonly buffer Pressures {
	float data[];
} pressures;

layout(push_constant, std430) uniform Constants {
	float radius;
	float columns;
	float rows;
	float mass;
	float rest_density;
	float stiffness;
} constants;

// Une boucle sur la carte doit avoir une fin : au-delà, une liste abîmée bloquerait toute la machine.
const int MAX_IN_CELL = 128;
const float PI = 3.14159265359;

// La case de la grille de voisinage où tombe le point `place`.
ivec2 cell_of(vec2 place) {
	return clamp(ivec2(floor(place / constants.radius)), ivec2(0), ivec2(constants.columns, constants.rows) - 1);
}

// Le poids d'une voisine à distance² `squared`.
float density_weight(float squared) {
	float gap = constants.radius * constants.radius - squared;
	return gap > 0.0 ? 4.0 / (PI * pow(constants.radius, 8.0)) * gap * gap * gap : 0.0;
}

// Ce que les particules de la case numéro `slot` ajoutent à la densité au point `place`.
float density_from(int slot, vec2 place) {
	float density = 0.0;
	int j = heads.data[slot];
	for (int count = 0; count < MAX_IN_CELL && j != -1; count++) {
		vec2 offset = place - positions.data[j];
		density += constants.mass * density_weight(dot(offset, offset));
		j = links.data[j];
	}
	return density;
}

// Une invocation par particule. La pression ne devient jamais négative : elle agglutinerait les particules.
void main() {
	uint i = gl_GlobalInvocationID.x;
	if (i >= positions.data.length()) {
		return;
	}
	vec2 place = positions.data[i];
	ivec2 center = cell_of(place);
	ivec2 low = max(center - 1, ivec2(0));
	ivec2 high = min(center + 1, ivec2(constants.columns, constants.rows) - 1);
	float density = 0.0;
	for (int y = low.y; y <= high.y; y++) {
		for (int x = low.x; x <= high.x; x++) {
			density += density_from(y * int(constants.columns) + x, place);
		}
	}
	densities.data[i] = density;
	pressures.data[i] = max(constants.stiffness * (density - constants.rest_density), 0.0);
}
