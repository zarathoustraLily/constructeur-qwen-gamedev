shader_type canvas_item;
// Vignette de dégâts : un voile rouge sur les bords de l'écran, d'autant plus fort que `force` est grande (santé
// basse, coup reçu). Le centre reste libre. À poser sur un ColorRect plein écran, au-dessus du jeu.

uniform vec4 tint : source_color = vec4(0.8, 0.0, 0.0, 1.0);
uniform float force : hint_range(0.0, 1.0) = 0.0;
uniform float softness = 0.45;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float voile = smoothstep(0.5 - softness, 0.75, d) * force;
	COLOR = vec4(tint.rgb, voile);
}
