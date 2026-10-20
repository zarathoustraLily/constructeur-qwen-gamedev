#ifndef RAIN_RIPPLES
#define RAIN_RIPPLES

// Impacts de gouttes de pluie procéduraux (inspiré du « Rain Drop Shader » de Kasper Frandsen) :
// la surface est découpée en cellules, chaque cellule reçoit une goutte à une position et un
// instant aléatoires, et un anneau s'élargit autour du point d'impact avant de s'estomper.
// Plusieurs couches décalées évitent l'effet de grille.

// Pilotés par RainController (environment/weather/rain_controller.gd)
global uniform float rain_intensity; // 0 = pas de pluie, 1 = averse
global uniform float rain_wetness;   // 0 = sec, 1 = détrempé (suit la pluie avec du retard)

float rain_hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 rain_hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// Une couche de gouttes. xy = pente de la surface (axes x / z du monde), z = masque de l'anneau.
vec3 rain_ripple_layer(vec2 pos, float time, float density) {
	vec2 cell = floor(pos);
	if (rain_hash12(cell + 7.31) > density) {
		return vec3(0.0);
	}
	// Point d'impact assez centré pour que l'anneau ne déborde pas de sa cellule
	vec2 center = 0.35 + 0.3 * rain_hash22(cell);
	float life = fract(time + rain_hash12(cell + 3.7));
	vec2 to_pixel = fract(pos) - center;
	float dist = length(to_pixel);

	const float max_radius = 0.27;
	const float ring_width = 0.07;
	float s = (dist - life * max_radius) / ring_width;
	float fade = (1.0 - life) * (1.0 - life);

	vec3 result = vec3(0.0);
	if (abs(s) < 1.0) {
		// Profil en sinus : creux à l'intérieur de l'anneau, crête à l'extérieur
		vec2 dir = to_pixel / max(dist, 1e-4);
		result.xy = dir * cos(s * PI) * fade;
		result.z = (1.0 - abs(s)) * fade;
	}
	// Petit éclat au moment de l'impact
	result.z += 0.6 * (1.0 - smoothstep(0.0, 0.035, dist)) * (1.0 - smoothstep(0.0, 0.1, life));
	return result;
}

float rain_value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = rain_hash12(i);
	float b = rain_hash12(i + vec2(1.0, 0.0));
	float c = rain_hash12(i + vec2(0.0, 1.0));
	float d = rain_hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Masque de flaques (0..1) : taches aux bords nets de quelques mètres. amount = part de la surface couverte.
float rain_puddle_mask(vec2 pos, float amount) {
	vec2 p = pos * 0.2;
	float n = rain_value_noise(p) * 0.65 + rain_value_noise(p * 2.7 + 13.1) * 0.35;
	float threshold = 1.0 - amount;
	return smoothstep(threshold, threshold + 0.05, n);
}

// pos : position monde (x, z) en mètres. drops_per_meter : taille des cellules (2 = cellules de 50 cm).
// Retourne xy = pente à ajouter à la normale monde (x, z), z = masque des anneaux (0..1).
// Doit être appelé depuis fragment() (utilise fwidth pour s'estomper au loin et éviter le scintillement).
vec3 rain_ripples(vec2 pos, float time, float intensity, float drops_per_meter) {
	if (intensity <= 0.001) {
		return vec3(0.0);
	}
	vec2 p = pos * drops_per_meter;
	float footprint = length(fwidth(p));
	float lod = 1.0 - smoothstep(0.06, 0.2, footprint);
	if (lod <= 0.0) {
		return vec3(0.0);
	}
	float t = time * 1.6;
	float density = clamp(intensity, 0.0, 1.0);
	vec3 r = rain_ripple_layer(p, t, density);
	r += rain_ripple_layer(p * 1.37 + vec2(17.3, 41.9), t + 0.33, density * 0.9);
	r += rain_ripple_layer(p * 0.83 + vec2(-8.1, 5.7), t * 0.87 + 0.66, density * 0.8);
	return r * lod;
}

#endif
