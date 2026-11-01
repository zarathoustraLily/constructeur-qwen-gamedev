#[compute]
#version 450

// Vide la grille de voisinage : aucune case n'a encore de première particule.
layout(local_size_x = 64) in;

layout(set = 0, binding = 0, std430) restrict writeonly buffer Heads {
	int data[];
} heads;

// Une invocation par case.
void main() {
	uint slot = gl_GlobalInvocationID.x;
	if (slot < heads.data.length()) {
		heads.data[slot] = -1;
	}
}
