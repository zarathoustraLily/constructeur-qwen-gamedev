// L'air chaud : le plan ne dessine rien, il décale l'image déjà rendue derrière lui. `ring` : une onde de choc, un anneau qui grandit
// (COLOR.a porte l'âge, 1 à la naissance) ; sinon une brume de chaleur, un disque flou. Il passe avant les autres effets (render_priority
// négatif) : l'image relue ne contient pas les objets transparents, il ne doit pas les effacer.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D noise : repeat_enable, filter_linear;
uniform float strength = 0.02;
uniform float noise_scale = 1.0;
uniform vec2 scroll = vec2(0.0, 0.4);
uniform bool ring = false;
// La largeur de l'anneau, en part du rayon.
uniform float ring_width = 0.16;

void vertex() {
	mat4 world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * world * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float age = 1.0 - COLOR.a;
	vec2 push;
	float mask;
	if (ring) {
		float front = sqrt(age);
		mask = smoothstep(ring_width, 0.0, abs(r - front)) * (1.0 - age) * step(r, 1.0);
		push = normalize(p + vec2(0.0001)) * mask;
	} else {
		mask = smoothstep(1.0, 0.25, r) * COLOR.a;
		vec2 n = texture(noise, UV * noise_scale + TIME * scroll).rg - 0.5;
		push = n * 2.0 * mask;
	}
	vec2 uv = SCREEN_UV + push * strength;
	ALBEDO = textureLod(screen, uv, 0.0).rgb;
	ALPHA = clamp(mask * 4.0, 0.0, 1.0);
}
