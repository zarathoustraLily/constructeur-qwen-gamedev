// L'éclat d'un tir ou d'une explosion, une ou deux images à l'écran : l'une des seize images de son atlas (R la chaleur, G l'alpha),
// tirée au sort par la particule (anim_offset). Deux façons de le poser :
// - `along_axis` : le jet, de profil, sur un plan qui s'étire vers -Z du nœud et pivote autour de cet axe pour faire face à la caméra ;
// - sinon : l'étoile, sur un plan tourné vers la caméra.
// Un plan vu par sa tranche ne doit pas se voir : le jet s'efface quand il pointe vers la caméra, et l'étoile quand il passe de profil.
shader_type spatial;
render_mode blend_premul_alpha, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform sampler2D atlas_f : filter_linear_mipmap, repeat_disable;
uniform vec2 grid = vec2(4.0, 4.0);
uniform sampler2D fire_ramp : filter_linear, repeat_disable;
uniform float fire_gain = 1.0;
uniform float cover = 0.3;
uniform bool along_axis = false;
// La taille du plan, en mètres (l'échelle de la particule s'y ajoute).
uniform float size = 1.0;
// L'origine du jet sur son image, de gauche à droite.
uniform float origin = 0.1;
// L'effacement selon l'angle de vue : 0 aucun.
uniform float view_fade = 1.0;

varying vec2 atlas_uv;
varying float view_factor;

void vertex() {
	float index = floor(clamp(INSTANCE_CUSTOM.z, 0.0, 0.999) * grid.x * grid.y);
	atlas_uv = (UV + vec2(mod(index, grid.x), floor(index / grid.x))) / grid;
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float scale = length(MODELVIEW_MATRIX[0].xyz) * size;
	vec3 axis = -normalize(MODELVIEW_MATRIX[2].xyz);
	float facing = abs(dot(axis, normalize(center)));
	if (along_axis) {
		vec3 side = normalize(cross(axis, center));
		VERTEX = center + axis * (UV.x - origin) * scale + side * (UV.y - 0.5) * scale;
		view_factor = 1.0 - pow(facing, 4.0) * view_fade;
	} else {
		float c = cos(INSTANCE_CUSTOM.x);
		float s = sin(INSTANCE_CUSTOM.x);
		vec2 p = (UV - 0.5) * scale;
		VERTEX = center + vec3(p.x * c - p.y * s, p.x * s + p.y * c, 0.0);
		view_factor = mix(1.0, facing * facing, view_fade);
	}
	NORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 f = texture(atlas_f, atlas_uv).rg;
	float heat = f.r * f.r * COLOR.a * view_factor;
	ALBEDO = texture(fire_ramp, vec2(heat, 0.5)).rgb * fire_gain * COLOR.rgb;
	ALPHA = f.g * cover * COLOR.a * view_factor;
}
