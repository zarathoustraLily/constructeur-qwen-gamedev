#[compute]
#version 450

// Ajoute `amount` dans un disque : le plus au centre, rien au bord du rayon.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D field;

layout(push_constant, std430) uniform Constants {
	float center_x;
	float center_y;
	float radius;
	float amount;
} constants;

// Une invocation par case de la grille, même loin du disque : le shader ne sait pas d'avance lesquelles comptent.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(field)))) {
		return;
	}
	float away = length(vec2(cell) - vec2(constants.center_x, constants.center_y));
	if (away < constants.radius) {
		float added = constants.amount * (1.0 - away / constants.radius);
		imageStore(field, cell, vec4(imageLoad(field, cell).r + added));
	}
}
