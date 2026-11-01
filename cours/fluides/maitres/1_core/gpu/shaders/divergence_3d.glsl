#[compute]
#version 450

// La divergence d'une vitesse en 3D : ce qui sort de chaque case, moins ce qui y entre, sur les trois axes. Le bord est un mur.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image3D target;
layout(rgba32f, set = 0, binding = 1) uniform restrict readonly image3D velocity;

// La vitesse de la case `cell`, nulle hors de la grille.
vec3 speed_at(ivec3 cell) {
	if (any(lessThan(cell, ivec3(0))) || any(greaterThanEqual(cell, imageSize(velocity)))) {
		return vec3(0.0);
	}
	return imageLoad(velocity, cell).xyz;
}

// Une invocation par case : l'écart sur chaque axe, de la composante de cet axe.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	float across = speed_at(cell + ivec3(1, 0, 0)).x - speed_at(cell - ivec3(1, 0, 0)).x;
	float up = speed_at(cell + ivec3(0, 1, 0)).y - speed_at(cell - ivec3(0, 1, 0)).y;
	float deep = speed_at(cell + ivec3(0, 0, 1)).z - speed_at(cell - ivec3(0, 0, 1)).z;
	imageStore(target, cell, vec4(0.5 * (across + up + deep)));
}
