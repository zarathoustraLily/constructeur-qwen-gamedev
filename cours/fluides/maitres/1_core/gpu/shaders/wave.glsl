#[compute]
#version 450

// Un pas de la surface de l'eau : chaque case garde sa vitesse, amortie, et accélère vers ses voisines (WaveSolver).
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D surface;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D previous;

layout(push_constant, std430) uniform Constants {
	float courant_squared;
	float damping;
} constants;

// La hauteur en `cell`. Au-delà du bord, c'est celle du bord : l'onde repart.
float height_at(ivec2 cell) {
	return imageLoad(surface, clamp(cell, ivec2(0), imageSize(surface) - 1)).r;
}

// Une invocation par case de la grille.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(surface)))) {
		return;
	}
	float here = height_at(cell);
	float around = height_at(cell + ivec2(-1, 0)) + height_at(cell + ivec2(1, 0))
			+ height_at(cell + ivec2(0, -1)) + height_at(cell + ivec2(0, 1)) - 4.0 * here;
	float moved = here + (here - imageLoad(previous, cell).r) * constants.damping + constants.courant_squared * around;
	imageStore(target, cell, vec4(moved));
}
