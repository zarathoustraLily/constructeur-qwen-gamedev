// Un flipbook de fluide cuit (outils/cuire_flipbooks.py) sur un plan tourné vers la caméra : deux images voisines, chacune poussée
// le long de ses vecteurs de mouvement, se fondent l'une dans l'autre : 36 images suffisent à une explosion lente et lisse.
//
// Sur le plan : INSTANCE_CUSTOM.x l'angle de la particule, .z son instant dans l'animation (ParticleProcessMaterial : anim_offset,
// anim_speed). Hors particules, tout vaut 0.

// Les vecteurs de mouvement de l'atlas.
uniform sampler2D atlas_v : filter_linear_mipmap, repeat_disable;
// Colonnes et lignes de l'atlas ; le nombre d'images.
uniform vec2 grid = vec2(6.0, 6.0);
uniform float frames = 36.0;
// La poussée des vecteurs : vecteur_max du .json de l'atlas (fraction d'image par image du flipbook).
uniform float flow = 0.02;
// Faux : l'animation ne boucle pas, et s'arrête sur sa dernière image.
uniform bool looping = false;
// La vitesse de l'animation sur la vie de la particule : 1 régulière ; au-dessous, vive puis lente.
uniform float pace = 1.0;
// Là où le plan rencontre le décor, il s'efface sur cette distance, en mètres : pas d'arête droite dans le sol.
uniform float soft_distance = 0.6;

uniform sampler2D depth_buffer : hint_depth_texture, filter_nearest, repeat_disable;

varying vec4 frame_uv;
varying float frame_blend;

// Le plan tourné vers la caméra, à la taille de la particule, tourné de son angle.
mat4 flipbook_modelview(mat4 model, mat4 view, mat4 inv_view, float angle) {
	mat4 world = mat4(normalize(inv_view[0]), normalize(inv_view[1]), normalize(inv_view[2]), model[3]);
	float c = cos(angle);
	float s = sin(angle);
	world = world * mat4(vec4(c, -s, 0.0, 0.0), vec4(s, c, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	vec3 size = vec3(length(model[0].xyz), length(model[1].xyz), length(model[2].xyz));
	return view * world * mat4(vec4(size.x, 0.0, 0.0, 0.0), vec4(0.0, size.y, 0.0, 0.0), vec4(0.0, 0.0, size.z, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

// Les deux images voisines de l'instant `clock` (de 0 à 1) : leurs UV ; `blend`, le chemin déjà fait de l'une à l'autre.
vec4 flipbook_frames(float clock, vec2 uv, out float blend) {
	float t = looping ? fract(clock) * frames : pow(clamp(clock, 0.0, 1.0), pace) * (frames - 1.001);
	float first = floor(t);
	float second = looping ? mod(first + 1.0, frames) : first + 1.0;
	blend = t - first;
	vec2 cell = 1.0 / grid;
	return vec4((uv + vec2(mod(first, grid.x), floor(first / grid.x))) * cell, (uv + vec2(mod(second, grid.x), floor(second / grid.x))) * cell);
}

// Les UV de l'image d'avant, poussés en avant, et ceux de l'image d'après, poussés en arrière : les volutes glissent au lieu de se
// fondre.
vec4 flipbook_pushed() {
	vec2 cell = 1.0 / grid;
	vec2 first = (texture(atlas_v, frame_uv.xy).rg * 2.0 - 1.0) * flow * cell;
	vec2 second = (texture(atlas_v, frame_uv.zw).rg * 2.0 - 1.0) * flow * cell;
	return vec4(frame_uv.xy - first * frame_blend, frame_uv.zw + second * (1.0 - frame_blend));
}

// L'effacement contre le décor.
float flipbook_soft(vec2 screen_uv, vec3 vertex, mat4 inv_projection) {
	float depth = texture(depth_buffer, screen_uv).r;
//@ 24+
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	depth = depth * 2.0 - 1.0;
#endif
//@ all
	vec4 scene = inv_projection * vec4(screen_uv * 2.0 - 1.0, depth, 1.0);
	return clamp((vertex.z - scene.z / scene.w) / soft_distance, 0.0, 1.0);
}
