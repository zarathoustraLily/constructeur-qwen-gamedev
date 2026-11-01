shader_type canvas_item;

// Les couleurs du feu : la texture ne contient qu'une température par case ; le dégradé `ramp` la change en couleur, à l'écran.

// Du noir au blanc, en passant par le rouge.
uniform sampler2D ramp : repeat_disable, filter_linear;
// La température qui donne la couleur la plus claire.
uniform float brightest = 3.0;

void fragment() {
	float heat = clamp(texture(TEXTURE, UV).r / brightest, 0.0, 1.0);
	COLOR = texture(ramp, vec2(heat, 0.5));
}
