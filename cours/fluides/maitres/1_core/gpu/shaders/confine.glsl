#[compute]
#version 450

// Le confinement : pousse chaque case vers le centre de sa rotation, pour rendre les tourbillons que la grille efface.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D speed_x;
layout(r32f, set = 0, binding = 1) uniform restrict image2D speed_y;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D spin;

layout(push_constant, std430) uniform Constants {
	float strength;
	float delta;
} constants;

// La taille de la rotation dans la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float spin_size(ivec2 cell) {
	return abs(imageLoad(spin, clamp(cell, ivec2(0), imageSize(spin) - 1)).r);
}

// Une invocation par case : la direction où la rotation grandit, tournée d'un quart de tour, donne la poussée.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(spin)))) {
		return;
	}
	vec2 toward = vec2(spin_size(cell + ivec2(1, 0)) - spin_size(cell - ivec2(1, 0)),
			spin_size(cell + ivec2(0, 1)) - spin_size(cell - ivec2(0, 1)));
	if (dot(toward, toward) < 0.000001) {
		return;
	}
	toward = normalize(toward);
	float push = constants.strength * imageLoad(spin, cell).r * constants.delta;
	imageStore(speed_x, cell, vec4(imageLoad(speed_x, cell).r + toward.y * push));
	imageStore(speed_y, cell, vec4(imageLoad(speed_y, cell).r - toward.x * push));
}
