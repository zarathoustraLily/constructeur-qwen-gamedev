#[compute]
#version 450

// La force sur chaque particule : la pression pousse ses voisines, la viscosité rapproche leurs vitesses.
layout(local_size_x = 64) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Positions {
	vec2 data[];
} positions;

layout(set = 0, binding = 1, std430) restrict readonly buffer Velocities {
	vec2 data[];
} velocities;

layout(set = 0, binding = 2, std430) restrict readonly buffer Densities {
	float data[];
} densities;

layout(set = 0, binding = 3, std430) restrict readonly buffer Pressures {
	float data[];
} pressures;

layout(set = 0, binding = 4, std430) restrict readonly buffer Heads {
	int data[];
} heads;

layout(set = 0, binding = 5, std430) restrict readonly buffer Links {
	int data[];
} links;

layout(set = 0, binding = 6, std430) restrict writeonly buffer Forces {
	vec2 data[];
} forces;

layout(push_constant, std430) uniform Constants {
	float radius;
	float columns;
	float rows;
	float mass;
	float viscosity;
} constants;

// Une boucle sur la carte doit avoir une fin : au-delà, une liste abîmée bloquerait toute la machine.
const int MAX_IN_CELL = 128;
const float PI = 3.14159265359;

// La case de la grille de voisinage où tombe le point `place`.
ivec2 cell_of(vec2 place) {
	return clamp(ivec2(floor(place / constants.radius)), ivec2(0), ivec2(constants.columns, constants.rows) - 1);
}

// La pente du noyau de pression à la distance `distance_apart`.
float pressure_slope(float distance_apart) {
	float gap = constants.radius - distance_apart;
	return gap > 0.0 ? -30.0 / (PI * pow(constants.radius, 5.0)) * gap * gap : 0.0;
}

// Le laplacien du noyau de viscosité à la distance `distance_apart`.
float viscosity_curve(float distance_apart) {
	float gap = constants.radius - distance_apart;
	return gap > 0.0 ? 40.0 / (PI * pow(constants.radius, 5.0)) * gap : 0.0;
}

// La force que `j` exerce sur `i` : symétrique, elle conserve la quantité de mouvement.
vec2 force_between(uint i, int j) {
	vec2 offset = positions.data[i] - positions.data[j];
	float apart = max(length(offset), 0.0001);
	float mass_squared = constants.mass * constants.mass;
	float shared_pressure = (pressures.data[i] + pressures.data[j]) / (2.0 * densities.data[i] * densities.data[j]);
	vec2 push = -mass_squared * shared_pressure * pressure_slope(apart) * offset / apart;
	float pull = constants.viscosity * mass_squared / (densities.data[i] * densities.data[j]) * viscosity_curve(apart);
	return push + pull * (velocities.data[j] - velocities.data[i]);
}

// Ce que les particules de la case numéro `slot` exercent sur `i`.
vec2 force_from(int slot, uint i) {
	vec2 force = vec2(0.0);
	int j = heads.data[slot];
	for (int count = 0; count < MAX_IN_CELL && j != -1; count++) {
		if (uint(j) != i) {
			force += force_between(i, j);
		}
		j = links.data[j];
	}
	return force;
}

// Une invocation par particule.
void main() {
	uint i = gl_GlobalInvocationID.x;
	if (i >= positions.data.length()) {
		return;
	}
	ivec2 center = cell_of(positions.data[i]);
	ivec2 low = max(center - 1, ivec2(0));
	ivec2 high = min(center + 1, ivec2(constants.columns, constants.rows) - 1);
	vec2 force = vec2(0.0);
	for (int y = low.y; y <= high.y; y++) {
		for (int x = low.x; x <= high.x; x++) {
			force += force_from(y * int(constants.columns) + x, i);
		}
	}
	forces.data[i] = force;
}
