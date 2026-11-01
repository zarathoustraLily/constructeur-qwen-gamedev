#[compute]
#version 450

// Pousse la vitesse verticale d'un volume : la chaleur monte, la fumée pèse. Dans un volume, y monte, comme dans la scène 3D.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image3D velocity;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image3D temperature;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image3D density;

layout(push_constant, std430) uniform Constants {
	float buoyancy;
	float weight;
	float delta;
} constants;

// Une invocation par case, sur place.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	if (any(greaterThanEqual(cell, imageSize(velocity)))) {
		return;
	}
	float push = constants.buoyancy * imageLoad(temperature, cell).r - constants.weight * imageLoad(density, cell).r;
	vec3 speed = imageLoad(velocity, cell).xyz;
	imageStore(velocity, cell, vec4(speed.x, speed.y + push * constants.delta, speed.z, 0.0));
}
