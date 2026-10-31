// De la fumée, et du feu qui devient fumée, qui reçoivent la lumière du niveau : « six-way lighting ». Les atlas tiennent ce que le
// volume renvoie d'une lumière venue de chacune des six directions du plan ; light() les mêle selon la direction de chaque lumière, et
// le volume reste un volume : éclairé par une torche à sa gauche, il garde son ombre à droite et sa lueur au bord.
// Mélange prémultiplié : la fumée cache ce qu'il y a derrière, le feu ajoute de la lumière, tous deux dans la même image.
shader_type spatial;
render_mode blend_premul_alpha, depth_draw_never, cull_disabled, specular_disabled, ambient_light_disabled, fog_disabled;

#include "res://6_assets/Shader/VFX/flipbook.gdshaderinc"

// R droite, G haut, B derrière ; A alpha.
uniform sampler2D atlas_a : source_color, filter_linear_mipmap, repeat_disable;
// R gauche, G bas, B devant ; A chaleur (sa racine carrée).
uniform sampler2D atlas_b : source_color, filter_linear_mipmap, repeat_disable;
// La couleur de la fumée.
uniform vec3 smoke_color : source_color = vec3(0.2, 0.19, 0.18);
// Un peu de lumière ambiante, quelle que soit la direction.
uniform vec3 ambient_color : source_color = vec3(0.1, 0.11, 0.14);
// De combien l'atlas a réduit les lumières (lumiere_max du .json).
uniform float light_scale = 1.0;
// La rampe de l'émission, de la braise au blanc ; sa force.
uniform sampler2D fire_ramp : filter_linear, repeat_disable;
uniform float fire_gain = 1.0;

varying mat2 sprite_turn;
varying vec3 lit_plus;
varying vec3 lit_minus;

void vertex() {
	MODELVIEW_MATRIX = flipbook_modelview(MODEL_MATRIX, VIEW_MATRIX, INV_VIEW_MATRIX, INSTANCE_CUSTOM.x);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	float c = cos(INSTANCE_CUSTOM.x);
	float s = sin(INSTANCE_CUSTOM.x);
	sprite_turn = mat2(vec2(c, -s), vec2(s, c));
	float blend = 0.0;
	frame_uv = flipbook_frames(INSTANCE_CUSTOM.z, UV, blend);
	frame_blend = blend;
}

void fragment() {
	vec4 uv = flipbook_pushed();
	vec4 a = mix(texture(atlas_a, uv.xy), texture(atlas_a, uv.zw), frame_blend);
	vec4 b = mix(texture(atlas_b, uv.xy), texture(atlas_b, uv.zw), frame_blend);
	lit_plus = a.rgb * light_scale;
	lit_minus = b.rgb * light_scale;
	float soft = flipbook_soft(SCREEN_UV, VERTEX, INV_PROJECTION_MATRIX);
	float alpha = a.a * COLOR.a * soft;
	ALBEDO = smoke_color * COLOR.rgb * alpha;
	ALPHA = alpha;
	float heat = b.a * b.a;
	float around = (a.r + a.g + a.b + b.r + b.g + b.b) / 6.0 * light_scale;
	EMISSION = texture(fire_ramp, vec2(heat, 0.5)).rgb * fire_gain * COLOR.a * soft + ALBEDO * ambient_color * around * 3.0;
}

void light() {
	vec2 side = sprite_turn * LIGHT.xy;
	vec3 weight = vec3(side * side, LIGHT.z * LIGHT.z);
	vec3 from = vec3(side.x > 0.0 ? lit_plus.r : lit_minus.r, side.y > 0.0 ? lit_plus.g : lit_minus.g, LIGHT.z > 0.0 ? lit_minus.b : lit_plus.b);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * dot(weight, from) / PI;
}
