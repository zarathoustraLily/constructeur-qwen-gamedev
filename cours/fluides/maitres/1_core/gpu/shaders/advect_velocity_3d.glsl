#[compute]
#version 450

// Le transport de la vitesse par elle-même : le même calcul que pour un champ, mais les trois composantes d'un coup.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict writeonly image3D target;
layout(set = 0, binding = 1) uniform sampler3D velocity;

layout(push_constant, std430) uniform Constants {
	float delta;
} constants;

// Une invocation par case.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	ivec3 size = imageSize(target);
	if (any(greaterThanEqual(cell, size))) {
		return;
	}
	vec3 speed = texelFetch(velocity, cell, 0).xyz;
	vec3 origin = vec3(cell) + 0.5 - constants.delta * speed;
	imageStore(target, cell, vec4(texture(velocity, origin / vec3(size)).xyz, 0.0));
}
