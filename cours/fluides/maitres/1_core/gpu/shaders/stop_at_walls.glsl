#[compute]
#version 450

// Arrête la vitesse contre les murs : une case ne garde aucune vitesse qui la ferait entrer dans un mur voisin.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict image2D speed_x;
layout(r32f, set = 0, binding = 1) uniform restrict image2D speed_y;
layout(r8, set = 0, binding = 2) uniform restrict readonly image2D walls;

// Vrai si la case `cell` est pleine, ou hors de la grille.
bool is_solid(ivec2 cell) {
	if (any(lessThan(cell, ivec2(0))) || any(greaterThanEqual(cell, imageSize(walls)))) {
		return true;
	}
	return imageLoad(walls, cell).r > 0.0;
}

// Une invocation par case : chaque axe regarde le voisin vers lequel il va.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(walls)))) {
		return;
	}
	float across = imageLoad(speed_x, cell).r;
	float down = imageLoad(speed_y, cell).r;
	if ((across > 0.0 && is_solid(cell + ivec2(1, 0))) || (across < 0.0 && is_solid(cell - ivec2(1, 0)))) {
		imageStore(speed_x, cell, vec4(0.0));
	}
	if ((down > 0.0 && is_solid(cell + ivec2(0, 1))) || (down < 0.0 && is_solid(cell - ivec2(0, 1)))) {
		imageStore(speed_y, cell, vec4(0.0));
	}
}
