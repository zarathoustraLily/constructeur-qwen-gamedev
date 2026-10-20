const int CASCADE_COUNT = 3;


group_uniforms Internal;
/******************************************************************************/
// Réglés pendant le jeu : une valeur posée dans l'éditeur risque d'être écrasée.

// Pour retourner les normales de la surface (vue sous l'eau)
uniform float normal_factor = 1.0;

// Échelles UV de chaque cascade.
// Données une fois, à la préparation de la simulation (OceanFFTWaves).
uniform float cascade_uv_scales[CASCADE_COUNT];

// Échelle UV commune à toutes les cascades.
// Donnée une fois, à la préparation de la simulation (OceanFFTWaves).
uniform float uv_scale = 0.001953125;

// Décalage UV accumulé par le vent, pour le défilement des vagues.
// Mis à jour à chaque OceanFFTWaves.simulate().
uniform vec2 wind_uv_offset = vec2(0.0, 0.0);

// Cartes de déplacement des cascades, calculées par les shaders de calcul.
// Données à la préparation de la simulation : ce sont les textures mêmes où calcule la carte graphique.
uniform sampler2D cascade_displacements[CASCADE_COUNT];

// Distance maximale (m) à laquelle un fragment est visible ; au-delà, ALPHA = 0.
// Donnée une fois, à la préparation de l'arbre de niveaux de détail (QuadTree3DView, caméra.far).
uniform float view_distance_max = 16000.0;


group_uniforms Internal.DomainWarp;
/******************************************************************************/
// Déforme les UV de lecture des cartes de déplacement avec une texture fixe, pour casser la
// répétition visible de loin.
// Une déformation fixe, ni animée ni centrée sur le joueur, évite que les sommets et les UV
// « nagent ».

// Étirement horizontal de domain_warp_texture : plus la valeur est petite, plus la texture s'étire.
// Pour qu'elle couvre X mètres, donner 1.0 / X.
uniform float domain_warp_uv_scale : hint_range(0.0, 1.0, 0.00000001) = 0.0000625;

// Force de la déformation des UV de lecture des cartes de déplacement
uniform float domain_warp_strength = 1500.0;

// Bruit qui déforme les UV de lecture des cartes de déplacement, pour casser la répétition
// au loin.
uniform sampler2D domain_warp_texture;

group_uniforms;


// Déplacement total d'un sommet : la somme des cascades.
vec3 get_displacement(vec2 uv) {
	vec3 displacement = vec3(0.0);

	for (int i = 0; i < CASCADE_COUNT; i++) {
		displacement += texture(cascade_displacements[i],
				uv * uv_scale * (1.0 / cascade_uv_scales[i]) + wind_uv_offset * cascade_uv_scales[i]).rgb;
	}

	return displacement;
}


// Normale de la surface et déterminant jacobien en une coordonnée : la normale dans XYZ,
// le jacobien dans W.
vec4 get_normals_jacobian(vec2 uv, vec3 displacement) {
	// Normale de la surface
	float offset = 1.0;

	vec3 right = (vec3(offset, get_displacement(uv + vec2(offset, 0.0)).y, 0.0)) - displacement;
	vec3 left = (vec3(-offset, get_displacement(uv + vec2(-offset, 0.0)).y, 0.0)) - displacement;
	vec3 bottom = (vec3(0.0, get_displacement(uv + vec2(0.0, offset)).y, offset)) - displacement;
	vec3 top = (vec3(0.0, get_displacement(uv + vec2(0.0, -offset)).y, -offset)) - displacement;

	vec3 top_right = cross(right, top);
	vec3 top_left = cross(top, left);
	vec3 bottom_left = cross(left, bottom);
	vec3 bottom_right = cross(bottom, right);

	vec3 normal = normalize(top_right + top_left + bottom_left + bottom_right) * normal_factor;

	// Déterminant jacobien
	// Sert à l'écume des crêtes
	float jxx = right.x / offset;
	float jxy = right.y / offset;
	float jyx = bottom.x / offset;
	float jyy = bottom.y / offset;
	float jacobian_determinant = (jxx * jyy) - (jxy * jyx);

	return vec4(normal, jacobian_determinant);
}


// Déforme la coordonnée donnée : sans effet à distance 0, de plus en plus fort avec la distance,
// complètement à view_distance_max.
vec2 domain_warp(vec2 uv, float linear_dist) {
	return uv;
	vec2 domain_warp = vec2(
			texture(domain_warp_texture, uv * domain_warp_uv_scale).r,
			texture(domain_warp_texture, -uv * domain_warp_uv_scale).r);

	domain_warp *= domain_warp_strength * (linear_dist / view_distance_max);

	return uv + domain_warp;
}
