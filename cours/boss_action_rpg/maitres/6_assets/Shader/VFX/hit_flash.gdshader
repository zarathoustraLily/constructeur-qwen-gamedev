// Le flash d'un personnage touché, posé par-dessus son matériau (material_overlay) : la recette du flash d'impact du
// RAG, en couche additive. Quand `flash` monte vers 1, la silhouette s'éclaire de la couleur du flash ; à 0, la couche
// n'ajoute rien. Les bords vus de biais s'éclairent plus (Fresnel) : le contour se lit même dans l'ombre.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

// La couleur du flash.
uniform vec4 flash_color : source_color = vec4(1.0, 0.35, 0.25, 1.0);
// Le flash, de 0 (rien) à 1 (au coup).
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float rim = 0.35 + 0.65 * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = flash_color.rgb * flash * rim;
	ALPHA = clamp(flash * rim, 0.0, 1.0);
}
