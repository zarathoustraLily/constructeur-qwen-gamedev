#[compute]
#version 450

// Arrête la vitesse contre les six faces du volume : une case du bord ne garde aucune vitesse qui la ferait sortir.
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(rgba32f, set = 0, binding = 0) uniform restrict image3D velocity;

// Une invocation par case : chaque axe regarde la face vers laquelle il va.
void main() {
	ivec3 cell = ivec3(gl_GlobalInvocationID);
	ivec3 last = imageSize(velocity) - 1;
	if (any(greaterThan(cell, last))) {
		return;
	}
	vec3 speed = imageLoad(velocity, cell).xyz;
	bvec3 at_low = equal(cell, ivec3(0));
	bvec3 at_high = equal(cell, last);
	bvec3 leaving = bvec3(at_low.x && speed.x < 0.0 || at_high.x && speed.x > 0.0, at_low.y && speed.y < 0.0 || at_high.y && speed.y > 0.0,
			at_low.z && speed.z < 0.0 || at_high.z && speed.z > 0.0);
	imageStore(velocity, cell, vec4(mix(speed, vec3(0.0), leaving), 0.0));
}
