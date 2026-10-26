shader_type spatial;
// Bouclier : plus la surface est vue de biais (bords de la sphère), plus elle brille ; le centre reste transparent.
// C'est l'effet de Fresnel : 1 - dot(NORMAL, VIEW), élevé à une puissance.
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 shield_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform float power = 3.0;
uniform float intensity = 1.5;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	ALBEDO = shield_color.rgb * fresnel * intensity;
	ALPHA = fresnel;
}
