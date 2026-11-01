#[compute]
#version 450

// La rotation en 3D : un vecteur, dont l'axe est celui du tourbillon et la longueur sa force.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict writeonly image3D target;
layout(rgba32f, set = 0, binding = 1) uniform restrict readonly image3D velocity;

// La vitesse de la case `cell` ; hors de la grille, celle de la case du bord la plus proche.
vec3 speed_at(ivec3 cell) {
	return imageLoad(velocity, clamp(cell, ivec3(0), imageSize(velocity) - 1)).xyz;
}

// Une invocation par case : les écarts de vitesse sur chaque axe, croisés.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	vec3 along_x = speed_at(cell + ivec3(1, 0, 0)) - speed_at(cell - ivec3(1, 0, 0));
	vec3 along_y = speed_at(cell + ivec3(0, 1, 0)) - speed_at(cell - ivec3(0, 1, 0));
	vec3 along_z = speed_at(cell + ivec3(0, 0, 1)) - speed_at(cell - ivec3(0, 0, 1));
	vec3 turn = 0.5 * vec3(along_y.z - along_z.y, along_z.x - along_x.z, along_x.y - along_y.x);
	imageStore(target, cell, vec4(turn, 0.0));
}
