#[compute]
#version 450

// Multiplie toutes les cases d'une image par `factor` : ce qu'un champ perd à chaque pas.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D field;

layout(push_constant, std430) uniform Constants {
	float factor;
} constants;

// Une invocation par case, sur place : chacune ne touche que la sienne.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(field)))) {
		return;
	}
	imageStore(field, cell, imageLoad(field, cell) * constants.factor);
}
