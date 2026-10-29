// L'onde de poussière d'un impact : un anneau posé sur le plancher, qui part du point d'impact et s'étend quand
// `progress` monte de 0 à 1, en s'effaçant ; un éclair chaud au centre, au tout début. Le bord de l'anneau est déchiré
// par un bruit qui tourne avec lui. Le plan fait deux unités de côté : le bord du plan, c'est le rayon de l'onde.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur de la poussière et son opacité.
uniform vec4 dust_color : source_color = vec4(0.62, 0.55, 0.45, 0.85);
// La couleur de l'éclair du centre.
uniform vec4 flash_color : source_color = vec4(1.0, 0.72, 0.42, 1.0);
// L'avancée de l'onde, de 0 (l'impact) à 1 (finie).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// L'épaisseur de l'anneau, en part du rayon.
uniform float thickness : hint_range(0.01, 0.6) = 0.18;
// Le bruit qui déchire le bord.
uniform sampler2D noise : repeat_enable;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float band = smoothstep(progress - thickness, progress, d) * (1.0 - smoothstep(progress, progress + thickness * 0.35, d));
	float n = texture(noise, vec2(atan(p.y, p.x) / 6.2832 * 4.0, d * 1.5 - progress * 0.5)).r;
	float dust = band * (1.0 - progress) * (0.45 + 0.55 * n) * dust_color.a;
	float flash = (1.0 - smoothstep(0.0, 0.3, progress)) * (1.0 - smoothstep(0.0, 0.3, d));
	ALBEDO = mix(dust_color.rgb, flash_color.rgb, clamp(flash * 2.0, 0.0, 1.0));
	ALPHA = clamp(dust + flash, 0.0, 1.0);
}
