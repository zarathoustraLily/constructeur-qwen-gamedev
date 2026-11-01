#[compute]
#version 450

// Le confinement en 3D : la direction où la rotation grandit, croisée avec la rotation, pousse vers le centre du tourbillon.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image3D velocity;
layout(rgba32f, set = 0, binding = 1) uniform restrict readonly image3D spin;

layout(push_constant, std430) uniform Constants {
	float strength;
	float delta;
} constants;

// La force de la rotation dans la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
float spin_size(ivec3 cell) {
	return length(imageLoad(spin, clamp(cell, ivec3(0), imageSize(spin) - 1)).xyz);
}

// Une invocation par case.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(spin)))) {
		return;
	}
	vec3 toward = vec3(spin_size(cell + ivec3(1, 0, 0)) - spin_size(cell - ivec3(1, 0, 0)),
			spin_size(cell + ivec3(0, 1, 0)) - spin_size(cell - ivec3(0, 1, 0)),
			spin_size(cell + ivec3(0, 0, 1)) - spin_size(cell - ivec3(0, 0, 1)));
	if (dot(toward, toward) < 0.000001) {
		return;
	}
	vec3 push = constants.strength * cross(normalize(toward), imageLoad(spin, cell).xyz) * constants.delta;
	imageStore(velocity, cell, vec4(imageLoad(velocity, cell).xyz + push, 0.0));
}
