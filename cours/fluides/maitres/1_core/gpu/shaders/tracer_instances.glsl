#[compute]
#version 450

// Écrit la place de chaque particule dans le tampon d'une MultiMesh en deux dimensions : huit flottants par instance, rangés comme le dit
// `RenderingServer.multimesh_set_buffer` : deux lignes de quatre, la position en quatrième.
layout(local_size_x = 64) in;

layout(std430, set = 0, binding = 0) restrict readonly buffer Positions {
	vec2 values[];
} positions;

layout(std430, set = 0, binding = 1) restrict writeonly buffer Instances {
	float values[];
} instances;

// Une invocation par particule.
void main() {
	uint index = gl_GlobalInvocationID.x;
	if (index >= positions.values.length()) {
		return;
	}
	vec2 point = positions.values[index];
	uint first = index * 8;
	instances.values[first] = 1.0;
	instances.values[first + 1] = 0.0;
	instances.values[first + 2] = 0.0;
	instances.values[first + 3] = point.x;
	instances.values[first + 4] = 0.0;
	instances.values[first + 5] = 1.0;
	instances.values[first + 6] = 0.0;
	instances.values[first + 7] = point.y;
}
