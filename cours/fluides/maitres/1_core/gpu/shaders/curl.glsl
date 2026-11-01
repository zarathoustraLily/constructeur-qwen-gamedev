#[compute]
#version 450

// La rotation de la vitesse : positive quand le fluide tourne dans le sens de x vers y.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D speed_x;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D speed_y;

// La vitesse horizontale de la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float x_at(ivec2 cell) {
	return imageLoad(speed_x, clamp(cell, ivec2(0), imageSize(speed_x) - 1)).r;
}

// La vitesse verticale de la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float y_at(ivec2 cell) {
	return imageLoad(speed_y, clamp(cell, ivec2(0), imageSize(speed_y) - 1)).r;
}

// Une invocation par case : comment `y` change le long de x, moins comment `x` change le long de y.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	float along_x = y_at(cell + ivec2(1, 0)) - y_at(cell - ivec2(1, 0));
	float along_y = x_at(cell + ivec2(0, 1)) - x_at(cell - ivec2(0, 1));
	imageStore(target, cell, vec4(0.5 * (along_x - along_y)));
}
