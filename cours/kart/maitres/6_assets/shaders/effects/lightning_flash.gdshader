shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Éclat de l'impact : disque lumineux face caméra qui s'estompe vers le bord.
instance uniform float flash_strength = 1.0;
uniform vec4 flash_color : source_color = vec4(0.3, 0.55, 1.0, 1.0);
uniform float intensity = 1.8;

void vertex() {
	// Toujours face à la caméra, en gardant l'échelle du nœud
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float disc = pow(clamp(1.0 - r, 0.0, 1.0), 2.0);
	ALBEDO = mix(flash_color.rgb, vec3(1.0), disc * disc) * intensity;
	ALPHA = clamp(disc * flash_strength, 0.0, 1.0);
}
