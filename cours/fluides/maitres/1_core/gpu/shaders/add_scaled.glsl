#[compute]
#version 450

// Ajoute à `target` l'image `source` multipliée par `factor`.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D source;

layout(push_constant, std430) uniform Constants {
	float factor;
} constants;

// Une invocation par case, sur place.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	imageStore(target, cell, imageLoad(target, cell) + constants.factor * imageLoad(source, cell));
}
