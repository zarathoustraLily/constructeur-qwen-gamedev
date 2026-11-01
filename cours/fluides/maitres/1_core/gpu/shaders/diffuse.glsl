#[compute]
#version 450

// Une moitié d'une passe de diffusion, en rouge-noir : le processeur parcourait les cases dans l'ordre, ce qu'une carte ne peut pas
// faire ; le damier résout la même équation.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D source;

layout(push_constant, std430) uniform Constants {
	float exchange;
	float color;
} constants;

// La valeur de `target` dans la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float target_at(ivec2 cell) {
	return imageLoad(target, clamp(cell, ivec2(0), imageSize(target) - 1)).r;
}

// Une invocation par case de la couleur : ce qu'elle était, plus ce qu'elle échange avec ses quatre voisines.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (((cell.x + cell.y + int(constants.color)) & 1) != 0 || any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	float around = target_at(cell - ivec2(1, 0)) + target_at(cell + ivec2(1, 0))
			+ target_at(cell - ivec2(0, 1)) + target_at(cell + ivec2(0, 1));
	float value = (imageLoad(source, cell).r + constants.exchange * around) / (1.0 + 4.0 * constants.exchange);
	imageStore(target, cell, vec4(value));
}
