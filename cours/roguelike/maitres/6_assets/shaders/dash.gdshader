shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_disabled, diffuse_lambert, specular_schlick_ggx;

// Traînée de l'esquive, sur un quad posé derrière le joueur : un bruit défile le long du quad, un dégradé le
// colore, et la traînée s'efface quand threshold monte de 0 à 1 (l'animation « dash » le fait en 0,5 s).
// Réécriture en code du VisualShader du jeu d'origine (Dash.tres), même suite de calculs.

// Vitesse de défilement du bruit, en largeurs de quad par seconde.
uniform float speed = 2.0;
uniform sampler2D noise_texture : source_color, filter_linear_mipmap;
// Couleur selon l'éclat : de gauche (faible) à droite (fort).
uniform sampler2D gradient_texture : source_color;
// Effacement : 0, traînée entière ; 1, plus rien.
uniform float threshold : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Le bruit défile en u avec le temps ; on lui retranche u : la traînée s'amincit vers son bout (u = 1).
	vec2 scrolled_uv = UV + vec2(UV.x - TIME * speed, 0.0);
	float trail = texture(noise_texture, scrolled_uv).r - UV.x;
	// Près du joueur (u = 0), (1 - u)^5 ajoute de l'éclat.
	float glow = pow(1.0 - UV.x, 5.0) + trail;
	vec3 color = texture(gradient_texture, vec2(smoothstep(0.0, 2.0, glow))).rgb;
	ALBEDO = color;
	EMISSION = color;
	// Ne reste que le bruit au-dessus du seuil d'effacement.
	ALPHA = step(threshold, trail);
}
