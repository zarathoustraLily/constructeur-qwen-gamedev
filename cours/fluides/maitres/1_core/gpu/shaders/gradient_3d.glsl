#[compute]
#version 450

// Retire à la vitesse la pente de la pression, sur les trois axes.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image3D velocity;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image3D pressure;

// La pression vue depuis une case voisine : celle de `cell`, ou `here` hors de la grille.
float seen(ivec3 cell, float here) {
	if (any(lessThan(cell, ivec3(0))) || any(greaterThanEqual(cell, imageSize(pressure)))) {
		return here;
	}
	return imageLoad(pressure, cell).r;
}

// Une invocation par case, sur place.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(velocity)))) {
		return;
	}
	float here = imageLoad(pressure, cell).r;
	vec3 slope = 0.5 * vec3(seen(cell + ivec3(1, 0, 0), here) - seen(cell - ivec3(1, 0, 0), here),
			seen(cell + ivec3(0, 1, 0), here) - seen(cell - ivec3(0, 1, 0), here),
			seen(cell + ivec3(0, 0, 1), here) - seen(cell - ivec3(0, 0, 1), here));
	imageStore(velocity, cell, vec4(imageLoad(velocity, cell).xyz - slope, 0.0));
}
