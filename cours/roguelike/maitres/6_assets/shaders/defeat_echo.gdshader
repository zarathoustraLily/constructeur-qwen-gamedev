shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx, unshaded;

// Écho de défaite, posé en surcouche (material_overlay) sur le modèle d'un ennemi vaincu : une silhouette
// blanche, sans éclairage, qui gagne le corps par plaques de bruit quand dissolve_amount monte de 0 (rien) à 1
// (tout blanc). Réécriture en code du VisualShader du jeu d'origine (defeat_echo.tres), même suite de calculs ;
// le jeu d'origine le fournissait sans s'en servir.

// Avancée de l'écho : 0, invisible ; 1, tout le corps.
uniform float dissolve_amount : hint_range(0.0, 1.0);
uniform sampler2D noise_texture;

void fragment() {
	ALBEDO = vec3(1.0);
	// Un point apparaît dès que 1 - dissolve_amount passe sous la valeur du bruit en ce point.
	ALPHA = step(1.0 - dissolve_amount, texture(noise_texture, UV).r);
}
