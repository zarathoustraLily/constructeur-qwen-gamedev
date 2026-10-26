shader_type spatial;
// Vent dans l'herbe : le haut du brin se balance, le pied reste planté. Le déplacement croît avec la hauteur du sommet
// (1 - UV.y : sur un QuadMesh, UV.y vaut 0 en haut) et suit la position du brin dans le monde, pour que les brins
// voisins ne bougent pas tous ensemble.
render_mode cull_disabled;

uniform vec4 couleur_pied : source_color = vec4(0.1, 0.35, 0.08, 1.0);
uniform vec4 couleur_pointe : source_color = vec4(0.55, 0.85, 0.3, 1.0);
uniform float force = 0.3;
uniform float vitesse = 2.0;

void vertex() {
	float haut = 1.0 - UV.y;
	vec3 monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * vitesse + monde.x * 0.8 + monde.z * 0.6) * force * haut * haut;
}

void fragment() {
	ALBEDO = mix(couleur_pied.rgb, couleur_pointe.rgb, 1.0 - UV.y);
}
