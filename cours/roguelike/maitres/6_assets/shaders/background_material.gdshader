shader_type canvas_item;
render_mode blend_mix;

// Fond de la boutique : un tourbillon de bruit lu en coordonnées polaires (distance au centre, angle), qui respire
// (un zoom qui va et vient), éclairé vers les bords par un second bruit qui défile lentement ; un dégradé du bleu
// nuit au bleu clair le colore. Réécriture en code du VisualShader du jeu d'origine (background_material.tres),
// même suite de calculs.

uniform sampler2D noise_texture;
// Couleur selon l'intensité : de gauche (faible) à droite (forte).
uniform sampler2D gradient_texture;

void fragment() {
	float slow_time = TIME * 0.2;
	// Le zoom va de 0,5 à 1,5 et revient, autour du centre de l'image.
	float zoom = sin(slow_time) * 0.5 + 1.0;
	vec2 zoomed_uv = (UV - vec2(0.5)) * vec2(zoom) + vec2(0.5);
	// Coordonnées polaires : x, la distance au centre (1 au bord) ; y, l'angle en tours.
	vec2 direction = zoomed_uv - vec2(0.5);
	float radius = length(direction) * 2.0;
	float angle = atan(direction.y, direction.x) * 1.0 / (PI * 2.0);
	vec2 polar_uv = mod(vec2(radius * 1.0, angle * 1.0), 1.0);
	float swirl = texture(noise_texture, polar_uv).r;
	// Plus fort vers les bords, et selon un bruit qui défile avec le temps.
	float edge = distance(UV, vec2(0.5)) * texture(noise_texture, vec2(slow_time)).r;
	float glow = smoothstep(0.0, 0.3, swirl * edge);
	COLOR.rgb = vec3(0.0) + texture(gradient_texture, vec2(glow)).rgb;
}
