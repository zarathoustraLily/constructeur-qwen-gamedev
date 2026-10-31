// Une étincelle : un trait fin le long de sa vitesse (transform_align du GPUParticles3D), sa couleur dans sa particule (rampe en valeurs
// fortes : blanche, puis orangée, puis rouge). Le trait s'allonge avec la vitesse : il raccourcit quand elle freine. Il ne descend jamais
// sous un pixel de large, sinon les étincelles lointaines clignotent.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// La longueur du trait à la naissance et à la mort, en mètres.
uniform vec2 length_range = vec2(0.5, 0.08);
// Sa largeur, en mètres ; sa largeur au moins, en part de la distance à la caméra.
uniform float width = 0.018;
uniform float min_width = 0.0013;
uniform float energy = 1.0;

void vertex() {
	float age = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	float away = length((MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	VERTEX.y *= mix(length_range.x, length_range.y, sqrt(age));
	VERTEX.x *= max(width, away * min_width);
}

void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	// La tête du trait (V = 0) est vive, sa queue s'efface.
	float along = smoothstep(0.0, 0.08, UV.y) * (1.0 - UV.y) * (1.0 - UV.y);
	ALBEDO = COLOR.rgb * energy;
	ALPHA = across * across * along * COLOR.a;
}
