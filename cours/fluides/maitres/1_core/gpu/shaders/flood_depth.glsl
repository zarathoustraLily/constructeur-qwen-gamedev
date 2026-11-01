#[compute]
#version 450

// Chaque case reçoit ce que ses voisines lui envoient, et perd ce qu'elle leur donne (FloodSolver).
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D depth;
layout(rgba32f, set = 0, binding = 2) uniform restrict readonly image2D flow;

layout(push_constant, std430) uniform Constants {
	float delta;
} constants;

// Les débits de la case `cell` ; rien hors de la grille.
vec4 flow_at(ivec2 cell) {
	if (any(lessThan(cell, ivec2(0))) || any(greaterThanEqual(cell, imageSize(flow)))) {
		return vec4(0.0);
	}
	return imageLoad(flow, cell);
}

// Une invocation par case de la grille.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(depth)))) {
		return;
	}
	vec4 own = imageLoad(flow, cell);
	float arriving = flow_at(cell + ivec2(-1, 0)).r + flow_at(cell + ivec2(1, 0)).g + flow_at(cell + ivec2(0, -1)).b + flow_at(cell + ivec2(0, 1)).a;
	float leaving = own.r + own.g + own.b + own.a;
	imageStore(target, cell, vec4(imageLoad(depth, cell).r + constants.delta * (arriving - leaving)));
}
