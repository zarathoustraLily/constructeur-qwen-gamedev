#[compute]
#version 450

// La fumée vue de face : chaque case de l'image dit quelle part de la lumière la colonne de fumée derrière elle arrête. Le haut de
// l'image est le haut du volume : dans un volume y monte, dans une image les lignes descendent.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image3D source;

layout(push_constant, std430) uniform Constants {
	float absorption;
	float spacing;
} constants;

// Une invocation par case de l'image.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	ivec3 size = imageSize(source);
	if (any(greaterThanEqual(cell, size.xy))) {
		return;
	}
	float matter = 0.0;
	for (int z = 0; z < size.z; z++) {
		matter += imageLoad(source, ivec3(cell.x, size.y - 1 - cell.y, z)).r;
	}
	imageStore(target, cell, vec4(1.0 - exp(-constants.absorption * matter * constants.spacing)));
}
