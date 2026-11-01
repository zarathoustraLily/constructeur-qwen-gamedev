#[compute]
#version 450

// La divergence de la vitesse : ce qui sort de chaque case, moins ce qui y entre. Un mur compte pour une vitesse nulle.
layout(local_size_x = 8, local_size_y = 8) in;

layout(r32f, set = 0, binding = 0) uniform restrict writeonly image2D target;
layout(r32f, set = 0, binding = 1) uniform restrict readonly image2D speed_x;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image2D speed_y;
layout(r8, set = 0, binding = 3) uniform restrict readonly image2D walls;

// Vrai si la case `cell` est pleine, ou hors de la grille.
bool is_solid(ivec2 cell) {
	if (any(lessThan(cell, ivec2(0))) || any(greaterThanEqual(cell, imageSize(walls)))) {
		return true;
	}
	return imageLoad(walls, cell).r > 0.0;
}

// La vitesse horizontale de la case `cell`, nulle dans un mur.
float x_at(ivec2 cell) {
	return is_solid(cell) ? 0.0 : imageLoad(speed_x, cell).r;
}

// La vitesse verticale de la case `cell`, nulle dans un mur.
float y_at(ivec2 cell) {
	return is_solid(cell) ? 0.0 : imageLoad(speed_y, cell).r;
}

// Une invocation par case : l'écart entre droite et gauche, plus l'écart entre bas et haut.
void main() {
	ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
	if (any(greaterThanEqual(cell, imageSize(target)))) {
		return;
	}
	float across = x_at(cell + ivec2(1, 0)) - x_at(cell - ivec2(1, 0));
	float down = y_at(cell + ivec2(0, 1)) - y_at(cell - ivec2(0, 1));
	imageStore(target, cell, vec4(0.5 * (across + down)));
}
