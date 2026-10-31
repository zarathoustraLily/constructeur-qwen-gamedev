// Du feu cuit : il ne reçoit pas de lumière, il en donne. L'atlas n'a que deux canaux : R la chaleur (sa racine carrée), G l'alpha.
// L'alpha de la particule baisse sa chaleur : en vieillissant, le feu rougit avant de s'éteindre.
shader_type spatial;
render_mode blend_premul_alpha, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://6_assets/Shader/VFX/flipbook.gdshaderinc"

uniform sampler2D atlas_f : filter_linear_mipmap, repeat_disable;
// La rampe de l'émission, de la braise au blanc ; sa force.
uniform sampler2D fire_ramp : filter_linear, repeat_disable;
uniform float fire_gain = 1.0;
// La part du fond que le feu cache : un peu, sinon il paraît collé sur le décor.
uniform float cover = 0.5;
// Hors particules : les tours de boucle par seconde.
uniform float time_rate = 0.0;

void vertex() {
	MODELVIEW_MATRIX = flipbook_modelview(MODEL_MATRIX, VIEW_MATRIX, INV_VIEW_MATRIX, INSTANCE_CUSTOM.x);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	float blend = 0.0;
	frame_uv = flipbook_frames(INSTANCE_CUSTOM.z + TIME * time_rate, UV, blend);
	frame_blend = blend;
}

void fragment() {
	vec4 uv = flipbook_pushed();
	vec2 f = mix(texture(atlas_f, uv.xy).rg, texture(atlas_f, uv.zw).rg, frame_blend);
	float soft = flipbook_soft(SCREEN_UV, VERTEX, INV_PROJECTION_MATRIX);
	float heat = f.r * f.r * COLOR.a;
	ALBEDO = texture(fire_ramp, vec2(heat, 0.5)).rgb * fire_gain * COLOR.rgb * soft;
	ALPHA = f.g * cover * COLOR.a * soft;
}
