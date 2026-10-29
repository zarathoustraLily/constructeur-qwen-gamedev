// La brume de repli, sans brouillard volumétrique (qualité basse) : des nappes horizontales posées au ras du plancher,
// où un bruit qui dérive dessine des volutes. Elles s'effacent au contact du décor (profondeur de l'écran : pas de ligne
// dure là où une nappe coupe un pied de table) et vers leurs bords. Les nappes sont éclairées par les lumières de la
// salle, comme le décor : une brume qui ne prendrait pas la lumière brillerait dans le noir. Bien moins cher qu'un
// brouillard volumétrique : quelques grands plans transparents.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur de la brume.
uniform vec4 mist_color : source_color = vec4(0.42, 0.44, 0.5, 1.0);
// L'opacité d'une nappe là où ses volutes sont les plus denses.
uniform float opacity : hint_range(0.0, 1.0) = 0.3;
// Le bruit des volutes.
uniform sampler2D noise : repeat_enable;
// La taille des volutes : le bruit est lu à cette fraction de la position, en mètres.
uniform float noise_scale : hint_range(0.001, 1.0) = 0.07;
// La dérive des volutes, en unités du bruit par seconde.
uniform vec2 drift = vec2(0.02, 0.008);
// Les creux et les volutes : le bruit est ramené entre ces deux seuils.
uniform float wisp_low : hint_range(0.0, 1.0) = 0.35;
uniform float wisp_high : hint_range(0.0, 1.0) = 0.75;
// Sur cette épaisseur, en mètres, la nappe s'efface au contact du décor.
uniform float contact_fade : hint_range(0.01, 5.0) = 0.6;
// La part de la nappe, vers ses bords, où elle s'efface.
uniform float edge_fade : hint_range(0.0, 0.5) = 0.08;
// La profondeur de l'écran.
uniform sampler2D depth_texture : hint_depth_texture, filter_linear;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = texture(noise, world_position.xz * noise_scale + drift * TIME + vec2(world_position.y * 0.37)).r;
	float wisps = smoothstep(wisp_low, wisp_high, n);
	float depth = texture(depth_texture, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
	vec4 scene = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float scene_distance = -scene.z / scene.w;
	float contact = clamp((scene_distance + VERTEX.z) / contact_fade, 0.0, 1.0);
	vec2 border = min(UV, 1.0 - UV);
	float edges = smoothstep(0.0, edge_fade, min(border.x, border.y));
	ALBEDO = mist_color.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = opacity * wisps * contact * edges;
}
