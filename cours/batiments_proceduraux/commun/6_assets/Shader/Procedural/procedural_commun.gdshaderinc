// Fonctions communes à tous les shaders procéduraux du cours.
//
// Un fichier « .gdshaderinc » ne dessine rien : c'est une boîte à outils que chaque shader
// recopie chez lui avec « #include ». Il vit dans « 6_assets/Shader/Procedural », un cran
// au-dessus des dossiers DECORS/Building, parce qu'il sert à tous les décors.
//
// Dans l'ordre où le cours s'en sert :
//   étape 002 : espace de couleur, filtrage des motifs, repère de face ;
//   étape 003 : hachage, bruit de valeur, bruit fractal, relief sans carte de normales ;
//   étape 010 : bruit en volume (le bois).
// Aucune texture n'est nécessaire : tout est calculé. Le préfixe « pc_ » veut dire
// « procédural commun » et évite les collisions de noms avec le shader qui inclut.

// ---------------------------------------------------------------------------
// ÉTAPE 002 — Espace de couleur.
//
// Les shaders mélangent les teintes en sRGB : c'est l'espace où un assombrissement
// de 30 % paraît valoir 30 % à l'œil. La conversion vers l'espace du moteur est
// faite une seule fois, en sortie.
//
// Sans cela, le même shader ne donne pas la même image selon le moteur de rendu :
//   - Forward+ et Mobile calculent en linéaire. Les uniformes « source_color » y
//     arrivent déjà convertis, ALBEDO et EMISSION sont lus comme du linéaire ;
//   - Compatibilité laisse le code du shader en sRGB et convertit après coup.
// La constante OUTPUT_IS_SRGB du moteur dit dans quel cas on se trouve.
// ---------------------------------------------------------------------------
vec3 pc_srgb_to_linear(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
}

vec3 pc_linear_to_srgb(vec3 c) {
	c = max(c, vec3(0.0));
	return mix(1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, c * 12.92, lessThan(c, vec3(0.0031308)));
}

// Uniforme « source_color » vers l'espace de travail (sRGB).
vec3 pc_color_in(vec3 c) {
	return OUTPUT_IS_SRGB ? c : pc_linear_to_srgb(c);
}

// Espace de travail vers ALBEDO ou EMISSION.
vec3 pc_color_out(vec3 c) {
	return OUTPUT_IS_SRGB ? max(c, vec3(0.0)) : pc_srgb_to_linear(c);
}

// ---------------------------------------------------------------------------
// ÉTAPE 003 — Hachage entier (mélange final de MurmurHash3, domaine public).
//
// Un hachage transforme un nombre en un autre nombre qui a l'air tiré au hasard, mais
// qui est toujours le même pour la même entrée. C'est le dé de tout le procédural :
// « le bloc numéro 12 de l'assise 7 » donne toujours la même teinte.
// Celui-ci travaille sur des entiers : il est stable d'une carte graphique à l'autre,
// contrairement aux hachages en sin() qu'on trouve partout.
// ---------------------------------------------------------------------------
uint pc_mix(uint h) {
	h ^= h >> 16u;
	h *= 2246822507u;
	h ^= h >> 13u;
	h *= 3266489909u;
	h ^= h >> 16u;
	return h;
}

float pc_unit(uint h) {
	return float(pc_mix(h) >> 8u) * (1.0 / 16777216.0);
}

float pc_hash1(float p) {
	return pc_unit(uint(int(floor(p))) * 2654435761u + 374761393u);
}

float pc_hash2(vec2 p) {
	ivec2 i = ivec2(floor(p));
	return pc_unit(uint(i.x) * 2654435761u ^ pc_mix(uint(i.y) + 2246822519u));
}

float pc_hash3(vec3 p) {
	ivec3 i = ivec3(floor(p));
	return pc_unit(uint(i.x) * 2654435761u ^ pc_mix(uint(i.y) * 2246822519u ^ pc_mix(uint(i.z) + 3266489917u)));
}

// Deuxième et troisième valeurs indépendantes à partir d'une première.
float pc_rehash(float h, float salt) {
	return pc_unit(uint(h * 16777216.0) ^ (uint(int(salt * 977.0)) * 2654435761u + 668265263u));
}

// ---------------------------------------------------------------------------
// ÉTAPE 003 — Bruit de valeur et bruit fractal.
//
// Bruit de valeur : on tire une valeur au hasard à chaque coin d'une grille et on fond
// de l'une à l'autre. Résultat : des taches douces, de la taille d'une case.
// Bruit fractal (fbm) : on additionne plusieurs bruits de plus en plus fins et de moins
// en moins forts (les « octaves »). Résultat : des taches qui ont du détail.
// ---------------------------------------------------------------------------
float pc_noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = p - i;
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = pc_hash2(i);
	float b = pc_hash2(i + vec2(1.0, 0.0));
	float c = pc_hash2(i + vec2(0.0, 1.0));
	float d = pc_hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Bruit fractal 2D. Chaque octave est tournée pour casser l'alignement sur la grille.
// « footprint » est la taille d'un pixel dans l'unité de p : les octaves plus fines
// que le pixel sont éteintes, ce qui évite le scintillement au loin. Une octave éteinte
// n'est pas calculée : de loin, le bruit coûte moins cher sans que l'image change.
float pc_fbm2(vec2 p, int octaves, float footprint) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	float freq = 1.0;
	for (int o = 0; o < octaves; o++) {
		float fade = 1.0 - smoothstep(0.3, 0.8, footprint * freq);
		if (fade > 0.0) {
			sum += amp * fade * (pc_noise2(p * freq) - 0.5);
		}
		norm += amp;
		p = vec2(p.x * 0.8 - p.y * 0.6, p.x * 0.6 + p.y * 0.8) + vec2(17.3, 9.1);
		freq *= 2.03;
		amp *= 0.5;
	}
	return 0.5 + sum / max(norm, 0.0001);
}

// ---------------------------------------------------------------------------
// ÉTAPE 010 — Bruit en volume.
//
// Les mêmes bruits, avec une dimension de plus : on tire une valeur à chaque coin d'une
// grille de cubes. Ils servent aux matières qui existent dans l'épaisseur, comme le bois :
// la veine qu'on voit sur une face se prolonge sur la face voisine.
// ---------------------------------------------------------------------------
float pc_noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = p - i;
	vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float n000 = pc_hash3(i);
	float n100 = pc_hash3(i + vec3(1.0, 0.0, 0.0));
	float n010 = pc_hash3(i + vec3(0.0, 1.0, 0.0));
	float n110 = pc_hash3(i + vec3(1.0, 1.0, 0.0));
	float n001 = pc_hash3(i + vec3(0.0, 0.0, 1.0));
	float n101 = pc_hash3(i + vec3(1.0, 0.0, 1.0));
	float n011 = pc_hash3(i + vec3(0.0, 1.0, 1.0));
	float n111 = pc_hash3(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
		mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y),
		u.z);
}

float pc_fbm3(vec3 p, int octaves, float footprint) {
	float sum = 0.0;
	float amp = 0.5;
	float norm = 0.0;
	float freq = 1.0;
	for (int o = 0; o < octaves; o++) {
		float fade = 1.0 - smoothstep(0.3, 0.8, footprint * freq);
		if (fade > 0.0) {
			sum += amp * fade * (pc_noise3(p * freq) - 0.5);
		}
		norm += amp;
		p = vec3(p.y * 0.8 + p.z * 0.6, p.z * 0.8 - p.y * 0.6, p.x) + vec3(11.7, 5.3, 23.9);
		freq *= 2.03;
		amp *= 0.5;
	}
	return 0.5 + sum / max(norm, 0.0001);
}

// ---------------------------------------------------------------------------
// ÉTAPE 002 — Filtrage des motifs.
//
// Un motif calculé n'a pas de « mipmaps » comme une texture : de loin, une ligne plus
// fine qu'un pixel scintille. On la filtre donc à la main. « fw » est l'empreinte du
// pixel dans l'unité de la distance mesurée : on l'obtient avec fwidth().
// ---------------------------------------------------------------------------

// Couverture d'une bande de demi-largeur w centrée sur d = 0 (filtre boîte).
// Une ligne plus fine que le pixel s'atténue au lieu de scintiller.
float pc_band(float d, float w, float fw) {
	fw = max(fw, 0.00001);
	float lo = max(d - 0.5 * fw, -w);
	float hi = min(d + 0.5 * fw, w);
	return clamp((hi - lo) / fw, 0.0, 1.0);
}

// Échelon adouci sur la largeur d'un pixel.
float pc_step(float edge, float x, float fw) {
	return clamp((x - edge) / max(fw, 0.00001) + 0.5, 0.0, 1.0);
}

// Rampe de 0 à 1 entre a et b, jamais plus raide qu'un pixel.
float pc_ramp(float a, float b, float x, float fw) {
	float w = max(b - a, fw);
	float mid = 0.5 * (a + b);
	return smoothstep(mid - 0.5 * w, mid + 0.5 * w, x);
}

// Même rampe, avec sa dérivée par rapport à x (pour calculer une pente exacte).
float pc_ramp_d(float a, float b, float x, float fw, out float slope) {
	float w = max(b - a, fw);
	float start = 0.5 * (a + b) - 0.5 * w;
	float k = clamp((x - start) / w, 0.0, 1.0);
	slope = 6.0 * k * (1.0 - k) / w;
	return k * k * (3.0 - 2.0 * k);
}

// ---------------------------------------------------------------------------
// ÉTAPE 002 — Repère d'une face plane : t horizontal le long de la face, b vers le
// haut (murs) ou vers le faîte (toits). n est la normale de la face.
//
// Les maillages du cours n'ont pas d'UV. Pour poser un motif sur une face, on fabrique
// deux axes à partir de sa normale : la position du pixel, projetée sur ces axes,
// donne des coordonnées en mètres, quelle que soit l'orientation de la face.
// ---------------------------------------------------------------------------
void pc_face_frame(vec3 n, out vec3 t, out vec3 b) {
	if (abs(n.y) > 0.9995) {
		t = vec3(1.0, 0.0, 0.0);
		b = vec3(0.0, 0.0, -sign(n.y));
	} else {
		t = normalize(cross(vec3(0.0, 1.0, 0.0), n));
		b = cross(n, t);
	}
}

// ---------------------------------------------------------------------------
// ÉTAPE 003 — Relief à partir d'une hauteur (en mètres), sans tangentes ni carte de normales.
// Méthode de Mikkelsen, « Bump Mapping Unparametrized Surfaces on the GPU ».
// n et p sont en espace vue (NORMAL et VERTEX dans fragment()).
// ---------------------------------------------------------------------------
vec3 pc_bump(vec3 n, vec3 p, float height) {
	vec3 dpdx = dFdx(p);
	vec3 dpdy = dFdy(p);
	float dhdx = dFdx(height);
	float dhdy = dFdy(height);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
	return normalize(abs(det) * n - grad);
}

// Relief à partir de pentes connues : slope_t et slope_b sont les dérivées de la
// hauteur le long de t et de b (sans unité). t et b sont en espace vue.
// Plus net et plus stable que pc_bump pour les arêtes franches (joints, tasseaux).
vec3 pc_slope_normal(vec3 n, vec3 t, vec3 b, float slope_t, float slope_b) {
	return normalize(n - slope_t * t - slope_b * b);
}

// Luminance approchée d'une couleur de l'espace de travail.
float pc_luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}
