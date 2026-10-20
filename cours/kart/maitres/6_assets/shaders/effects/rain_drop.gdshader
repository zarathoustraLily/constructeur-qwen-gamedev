shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Trait de pluie : quad fin étiré dans l'axe de la vitesse (GPUParticles3D.transform_align = Y_TO_VELOCITY)
uniform vec4 drop_color : source_color = vec4(0.78, 0.84, 0.92, 0.32);

void fragment() {
	// Opaque au centre, transparent sur les bords et effilé aux deux extrémités
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float along = sin(UV.y * PI);
	ALBEDO = drop_color.rgb;
	ALPHA = drop_color.a * across * along * COLOR.a;
}
