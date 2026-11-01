#[compute]
#version 450

// Met à zéro un champ dans les cases pleines : ni vitesse ni matière dans un mur.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D field;
layout(r8, set = 0, binding = 1) uniform restrict readonly image2D walls;

// Une invocation par case : seules les cases pleines sont écrites.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(walls)))) {
		return;
	}
	if (imageLoad(walls, cell).r > 0.0) {
		imageStore(field, cell, vec4(0.0));
	}
}
