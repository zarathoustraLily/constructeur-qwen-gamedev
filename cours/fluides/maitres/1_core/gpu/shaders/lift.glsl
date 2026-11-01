#[compute]
#version 450

// Pousse la vitesse verticale : la chaleur monte (vers les y négatifs), la suie pèse.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D speed_y;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D temperature;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D soot;

layout(push_constant, std430) uniform Constants {
	float soot_weight;
	float buoyancy;
	float delta;
} constants;

// Une invocation par case, sur place.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(speed_y)))) {
		return;
	}
	float push = constants.soot_weight * imageLoad(soot, cell).r - constants.buoyancy * imageLoad(temperature, cell).r;
	imageStore(speed_y, cell, vec4(imageLoad(speed_y, cell).r + push * constants.delta));
}
