#[compute]
#version 450

// Ce que le volume renvoie vers la caméra pour une lumière venue de chacune des six directions. La caméra regarde depuis les z grands.
// Chaque case vue éclaire le pixel d'autant que la lumière lui parvient : pour chaque direction, on compte la fumée qui l'en sépare.
layout(local_size_x = 8, local_size_y = 8) in;

// Droite, haut, arrière, et l'opacité.
layout(rgba32f, set = 0, binding = 0) uniform restrict writeonly image2D first;
// Gauche, bas, avant, et l'opacité.
layout(rgba32f, set = 0, binding = 1) uniform restrict writeonly image2D second;
layout(r32f, set = 0, binding = 2) uniform restrict readonly image3D source;

layout(push_constant, std430) uniform Constants {
	float absorption;
	float spacing;
} constants;

// La part de lumière qui arrive à `cell` depuis `direction`, en s'arrêtant au bord du volume.
float light_from(ivec3 cell, ivec3 direction, ivec3 size) {
	float matter = 0.0;
	for (ivec3 point = cell + direction; all(greaterThanEqual(point, ivec3(0))) && all(lessThan(point, size)); point += direction) {
		matter += imageLoad(source, point).r;
	}
	return exp(-constants.absorption * matter * constants.spacing);
}

// Une invocation par case de l'image. On descend la colonne depuis la caméra : ce qu'une case renvoie compte d'autant que le regard
// arrive jusqu'à elle.
void main() {
	ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
	ivec3 size = imageSize(source);
	if (any(greaterThanEqual(pixel, size.xy))) {
		return;
	}
	float passing = 1.0;
	vec3 lit_first = vec3(0.0);
	vec3 lit_second = vec3(0.0);
	for (int z = size.z - 1; z >= 0; z--) {
		ivec3 cell = ivec3(pixel.x, size.y - 1 - pixel.y, z);
		float matter = imageLoad(source, cell).r;
		if (matter <= 0.0) {
			continue;
		}
		float taken = 1.0 - exp(-constants.absorption * matter * constants.spacing);
		float seen = passing * taken;
		lit_first += seen * vec3(light_from(cell, ivec3(1, 0, 0), size), light_from(cell, ivec3(0, 1, 0), size), light_from(cell, ivec3(0, 0, -1), size));
		lit_second += seen * vec3(light_from(cell, ivec3(-1, 0, 0), size), light_from(cell, ivec3(0, -1, 0), size), light_from(cell, ivec3(0, 0, 1), size));
		passing *= 1.0 - taken;
	}
	imageStore(first, pixel, vec4(lit_first, 1.0 - passing));
	imageStore(second, pixel, vec4(lit_second, 1.0 - passing));
}
