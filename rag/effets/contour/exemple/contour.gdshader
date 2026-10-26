shader_type spatial;
// Contour (« coque inversée ») : une seconde passe du maillage, gonflée le long des normales et dessinée de dos,
// d'une couleur unie. Seul le bord dépasse derrière l'objet : on voit un trait autour de sa silhouette.
render_mode unshaded, cull_front;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float thickness = 0.05;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
