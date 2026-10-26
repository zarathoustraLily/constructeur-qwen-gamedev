shader_type spatial;
// Eau stylisée : deux houles (des sinus qui avancent avec TIME) soulèvent les sommets ; les crêtes sont plus claires
// que les creux. Le plan doit être subdivisé : seules ses sommets bougent.

uniform vec4 couleur_creux : source_color = vec4(0.02, 0.2, 0.4, 1.0);
uniform vec4 couleur_crete : source_color = vec4(0.5, 0.85, 0.95, 1.0);
uniform float amplitude = 0.15;
uniform float longueur_onde = 2.0;
uniform float vitesse = 1.5;

varying float hauteur;

void vertex() {
	float k = 6.2832 / longueur_onde;
	float phase_x = VERTEX.x * k + TIME * vitesse;
	float phase_z = VERTEX.z * k * 0.7 + TIME * vitesse * 1.3;
	hauteur = sin(phase_x) * 0.6 + sin(phase_z) * 0.4;
	VERTEX.y += hauteur * amplitude;
	// La pente de la surface donne la normale : sans elle, l'éclairage resterait celui du plan plat.
	float pente_x = cos(phase_x) * 0.6 * k * amplitude;
	float pente_z = cos(phase_z) * 0.4 * k * 0.7 * amplitude;
	NORMAL = normalize(vec3(-pente_x, 1.0, -pente_z));
}

void fragment() {
	ALBEDO = mix(couleur_creux.rgb, couleur_crete.rgb, hauteur * 0.5 + 0.5);
	ROUGHNESS = 0.25;
}
