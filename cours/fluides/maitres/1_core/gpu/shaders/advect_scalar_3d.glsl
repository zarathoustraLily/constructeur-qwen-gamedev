#[compute]
#version 450

// Le transport en 3D : chaque case reçoit la valeur de `source` d'où vient le courant. Entre huit cases, le mélange coûterait huit
// lectures : un `sampler3D` le fait en une seule, par le filtre de la carte, avec des coordonnées entre 0 et 1.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image3D target;
layout(set = 0, binding = 1) uniform sampler3D source;
layout(set = 0, binding = 2) uniform sampler3D velocity;

layout(push_constant, std430) uniform Constants {
	float delta;
} constants;

// Une invocation par case. Le centre d'une case est à 0,5 dans une texture : il faut l'ajouter pour lire au bon endroit.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	ivec3 size = imageSize(target);
	if (any(greaterThanEqual(cell, size))) {
		return;
	}
	vec3 speed = texelFetch(velocity, cell, 0).xyz;
	vec3 origin = vec3(cell) + 0.5 - constants.delta * speed;
	imageStore(target, cell, vec4(texture(source, origin / vec3(size)).r));
}
