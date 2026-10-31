//@ 20-23
// La marque d'un éclair au sol : un cercle fixe, à la limite de la zone de coup, et un second cercle qui se referme vers
// le centre à mesure que le coup approche ; le fond se remplit de lumière. `progress` va de 0 (l'annonce) à 1 (le coup).
// Le plan est posé juste au-dessus du sol. Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur de la marque.
uniform vec3 ring_color : source_color = vec3(0.45, 0.6, 1.0);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 20.0) = 3.0;
// L'avancée de l'annonce, de 0 à 1.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// L'épaisseur des cercles, en part du rayon.
uniform float thickness : hint_range(0.005, 0.3) = 0.05;

void fragment() {
	float radius = length(UV * 2.0 - 1.0);
	float rim = 1.0 - smoothstep(0.0, thickness, abs(radius - (1.0 - thickness)));
	float closing = 1.0 - smoothstep(0.0, thickness, abs(radius - (1.0 - progress) * (1.0 - thickness)));
	float fill = (1.0 - smoothstep(0.7, 1.0, radius)) * 0.14 * progress;
	float light = rim * (0.5 + 0.5 * progress) + closing + fill;
	ALBEDO = ring_color * intensity;
	ALPHA = clamp(light, 0.0, 1.0);
}
//@ 24+
// La marque d'un éclair : le sol se charge. Un bord irrégulier, et des filaments d'électricité qui rampent à l'intérieur, depuis le bord
// vers le centre à mesure que le coup approche (`progress`, de 0 à 1) ; ils vacillent de plus en plus vite. La forme reste un cercle : le
// joueur doit lire où ne pas rester. Mélange additif, sur un plan posé au ras du sol.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// La couleur de la charge.
uniform vec3 ring_color : source_color = vec3(0.45, 0.6, 1.0);
// La couleur des filaments, plus blanche.
uniform vec3 filament_color : source_color = vec3(0.75, 0.85, 1.0);
// L'éclat : au-dessus de 1, il nourrit la lueur de l'écran (glow).
uniform float intensity : hint_range(0.0, 30.0) = 3.0;
// De 0 (posée) à 1 (le coup part).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// L'épaisseur du bord, en part du rayon.
uniform float thickness : hint_range(0.0, 0.5) = 0.05;
uniform sampler2D noise : repeat_enable, filter_linear;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) / TAU;
	float t = TIME * (0.6 + progress * 1.6);
	float wobble = texture(noise, vec2(a * 3.0 + t * 0.13, t * 0.2)).r - 0.5;
	float edge = smoothstep(thickness, 0.0, abs(r - 0.92 - wobble * 0.1));
	float f1 = texture(noise, p * 0.9 + vec2(t * 0.17, -t * 0.23)).r;
	float f2 = texture(noise, p * 2.1 + vec2(-t * 0.29, t * 0.13)).r;
	float filaments = pow(clamp(1.0 - abs(f1 + f2 - 1.0) * 26.0, 0.0, 1.0), 3.0);
	float reach = smoothstep(0.95 - progress * 1.05, 1.0 - progress * 0.9, r) * smoothstep(1.0, 0.92, r);
	float flicker = 0.75 + 0.25 * sin(TIME * 73.0 + a * 40.0);
	vec3 field = ring_color * reach * (0.015 + 0.05 * progress) * (0.6 + 0.8 * f1);
	ALBEDO = (ring_color * edge * (0.5 + progress * 1.5) * flicker + filament_color * filaments * reach * (0.8 + progress * 3.0) * flicker + field) * intensity;
	ALPHA = clamp(edge + filaments * reach + reach * 0.3, 0.0, 1.0) * smoothstep(1.02, 0.97, r);
}
//@ all
