#[compute]
#version 450

// Les débits sortants de chaque case : droite, gauche, bas, haut (FloodSolver). Une case ne donne pas plus d'eau qu'elle n'en a.
layout(local_size_x = 8, local_size_y = 8) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(rgba32f, set = 0, binding = 1) uniform restrict readonly image2D flow;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D depth;
layout(r32f, set = 0, binding = 3) uniform restrict readonly image2D ground;

layout(push_constant, std430) uniform Constants {
	float delta;
	float pull;
	float friction;
} constants;

// Le niveau de l'eau en `cell` : c'est lui qui fait couler, pas le sol.
float level_at(ivec2 cell) {
	return imageLoad(depth, cell).r + imageLoad(ground, cell).r;
}

// Le débit vers la voisine `neighbor` : il garde son élan, et l'écart des niveaux le pousse. Rien ne sort de la grille.
float pushed(float kept, float here, ivec2 neighbor) {
	if (any(lessThan(neighbor, ivec2(0))) || any(greaterThanEqual(neighbor, imageSize(depth)))) {
		return 0.0;
	}
	return max(0.0, kept * constants.friction + constants.delta * constants.pull * (here - level_at(neighbor)));
}

// Une invocation par case de la grille.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(depth)))) {
		return;
	}
	vec4 kept = imageLoad(flow, cell);
	float here = level_at(cell);
	vec4 flows = vec4(pushed(kept.r, here, cell + ivec2(1, 0)), pushed(kept.g, here, cell + ivec2(-1, 0)),
			pushed(kept.b, here, cell + ivec2(0, 1)), pushed(kept.a, here, cell + ivec2(0, -1)));
	float leaving = (flows.r + flows.g + flows.b + flows.a) * constants.delta;
	float water = imageLoad(depth, cell).r;
	if (leaving > water) {
		flows *= water / leaving;
	}
	imageStore(target, cell, flows);
}
