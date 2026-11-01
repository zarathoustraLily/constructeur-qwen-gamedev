#[compute]
#version 450

// Un pas des particules (Tracer.moved) : chacune lit le courant à mi-chemin. Une particule sortie de la grille revient à son départ, et une
// partie d'entre elles y revient à chaque pas : chacune vit ainsi `lifetime` pas, sans qu'aucune ne tienne le compte de son âge.
layout(local_size_x = 64) in;

layout(std430, set = 0, binding = 0) restrict buffer Positions {
	vec2 values[];
} positions;

layout(std430, set = 0, binding = 1) restrict readonly buffer Origins {
	vec2 values[];
} origins;

layout(set = 0, binding = 2) uniform sampler2D u_field;
layout(set = 0, binding = 3) uniform sampler2D v_field;

layout(push_constant, std430) uniform Constants {
	float delta;
	float width;
	float height;
	float lifetime;
	float turn;
} constants;

// Le courant au point `point`. Le centre d'une case est à 0,5 dans une texture, et sur les entiers ici.
vec2 current_at(vec2 point) {
	vec2 uv = (point + 0.5) / vec2(constants.width, constants.height);
	return vec2(texture(u_field, uv).r, texture(v_field, uv).r);
}

// Une invocation par particule.
void main() {
	uint index = gl_GlobalInvocationID.x;
	if (index >= positions.values.length()) {
		return;
	}
	vec2 here = positions.values[index];
	vec2 there = here + current_at(here + current_at(here) * constants.delta * 0.5) * constants.delta;
	bool outside = any(lessThan(there, vec2(0.0))) || there.x > constants.width - 1.0 || there.y > constants.height - 1.0;
	bool expired = constants.lifetime > 0.0 && mod(float(index), constants.lifetime) == constants.turn;
	positions.values[index] = outside || expired ? origins.values[index] : there;
}
