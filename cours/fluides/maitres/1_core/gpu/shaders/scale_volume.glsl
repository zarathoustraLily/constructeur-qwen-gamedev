#[compute]
#version 450

// Multiplie toutes les cases d'un volume par `factor` : ce qu'un champ perd à chaque pas.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(r32f, set = 0, binding = 0) uniform restrict image3D field;

layout(push_constant, std430) uniform Constants {
	float factor;
} constants;

// Une invocation par case, sur place.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(field)))) {
		return;
	}
	imageStore(field, cell, imageLoad(field, cell) * constants.factor);
}
