#[compute]
#version 450

// La combustion : là où la température atteint `ignition`, le carburant se change en chaleur et en suie, et le gaz brûlé prend
// de la place. Toutes les images sont écrites sur place, case par case.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D fuel;
layout(r32f, set = 0, binding = 1) uniform restrict image2D temperature;
layout(r32f, set = 0, binding = 2) uniform restrict image2D soot;
layout(r32f, set = 0, binding = 3) uniform restrict writeonly image2D expansion;

layout(push_constant, std430) uniform Constants {
	float ignition;
	float burn_rate;
	float heat;
	float soot_yield;
	float expansion_rate;
	float delta;
} constants;

// Le carburant brûlé dans une case : rien sous `ignition`, jamais plus qu'il n'en reste.
float burned_in(float left, float hot) {
	return hot >= constants.ignition ? min(left, constants.burn_rate * constants.delta) : 0.0;
}

// Une invocation par case.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(fuel)))) {
		return;
	}
	float left = imageLoad(fuel, cell).r;
	float hot = imageLoad(temperature, cell).r;
	float burned = burned_in(left, hot);
	imageStore(fuel, cell, vec4(left - burned));
	imageStore(temperature, cell, vec4(hot + burned * constants.heat));
	imageStore(soot, cell, vec4(imageLoad(soot, cell).r + burned * constants.soot_yield));
	imageStore(expansion, cell, vec4(burned * constants.expansion_rate / constants.delta));
}
