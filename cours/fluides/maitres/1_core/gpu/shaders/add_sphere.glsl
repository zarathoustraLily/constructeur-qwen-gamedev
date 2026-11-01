#[compute]
#version 450

// Ajoute `amount` dans une boule : le plus au centre, rien au bord du rayon.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(r32f, set = 0, binding = 0) uniform restrict image3D field;

layout(push_constant, std430) uniform Constants {
	float center_x;
	float center_y;
	float center_z;
	float radius;
	float amount;
} constants;

// Une invocation par case de la grille.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(field)))) {
		return;
	}
	float away = length(vec3(cell) - vec3(constants.center_x, constants.center_y, constants.center_z));
	if (away < constants.radius) {
		float added = constants.amount * (1.0 - away / constants.radius);
		imageStore(field, cell, vec4(imageLoad(field, cell).r + added));
	}
}
