#[compute]
#version 450

// Applique les forces et la gravité, déplace les particules, et les fait rebondir sur les parois de la cuve.
layout(local_size_x = 64) in;

layout(set = 0, binding = 0, std430) restrict buffer Positions {
	vec2 data[];
} positions;

layout(set = 0, binding = 1, std430) restrict buffer Velocities {
	vec2 data[];
} velocities;

layout(set = 0, binding = 2, std430) restrict readonly buffer Forces {
	vec2 data[];
} forces;

layout(push_constant, std430) uniform Constants {
	float delta;
	float mass;
	float gravity;
	float bounce;
	float width;
	float height;
} constants;

// Une invocation par particule : elle ne touche que la sienne.
void main() {
	uint i = gl_GlobalInvocationID.x;
	if (i >= positions.data.length()) {
		return;
	}
	vec2 speed = velocities.data[i] + constants.delta * (forces.data[i] / constants.mass + vec2(0.0, constants.gravity));
	vec2 place = positions.data[i] + constants.delta * speed;
	vec2 limit = vec2(constants.width, constants.height);
	if (place.x < 0.0 || place.x > limit.x) {
		speed.x *= -constants.bounce;
	}
	if (place.y < 0.0 || place.y > limit.y) {
		speed.y *= -constants.bounce;
	}
	velocities.data[i] = speed;
	positions.data[i] = clamp(place, vec2(0.0), limit);
}
