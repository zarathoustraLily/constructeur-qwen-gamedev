shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_disabled, diffuse_lambert, specular_schlick_ggx, depth_prepass_alpha, unshaded;

// Colonne de lumière de la sortie : un dégradé du haut vers le bas, auquel s'ajoute un bruit qui monte avec le
// temps ; ne reste que ce qui dépasse cutoff. L'animation « Exit » descend cutoff de 0,41 à 0 : la colonne se
// remplit. Réécriture en code du VisualShader du jeu d'origine (spawn_point.tres), même suite de calculs (son
// paramètre s'appelait « Cuttoff »).

// Seuil : plus il est haut, moins la colonne se voit.
uniform float cutoff;
uniform sampler2D gradient_texture : source_color;
uniform sampler2D noise_texture;

void fragment() {
	vec4 gradient = texture(gradient_texture, UV);
	// Le bruit monte d'une demi-hauteur de texture par seconde.
	vec2 noise_uv = vec2(0.0, TIME) * vec2(0.5) + UV;
	vec4 noise = texture(noise_texture, noise_uv);
	ALPHA = step(cutoff, (gradient + noise).x);
}
