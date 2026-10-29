// Le spectre : un squelette bleu, lumineux et transparent. Les bords vus de biais brillent plus que le cœur (effet de
// Fresnel, comme le bouclier d'énergie du RAG) ; il scintille ; son linceul ondule, s'étire derrière lui quand il
// plonge et se dissout en lambeaux. Mélange additif : le spectre ajoute de la lumière, il ne cache rien. Les couleurs
// des sommets sont des poids posés par son générateur : r, l'ondulation ; g, la dissolution ; b, l'éclat (0,5
// l'ordinaire).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

// La couleur de la lueur.
uniform vec3 glow_color : source_color = vec3(0.35, 0.65, 1.0);
// L'éclat : il monte pendant l'annonce d'une plongée et retombe quand le spectre se dissipe.
uniform float intensity : hint_range(0.0, 10.0) = 1.6;
// La part de lueur gardée au cœur de la silhouette (face à la caméra), de 0 à 1.
uniform float core : hint_range(0.0, 1.0) = 0.18;
// La finesse du bord lumineux.
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
// Le bruit des volutes et du scintillement.
uniform sampler2D noise : repeat_enable;
// La vitesse du scintillement.
uniform float flicker_speed : hint_range(0.0, 20.0) = 3.0;
// L'ondulation du linceul : son ampleur (en mètres, là où le poids vaut 1), sa vitesse, ses vagues par mètre.
uniform float sway : hint_range(0.0, 0.5) = 0.07;
uniform float sway_speed : hint_range(0.0, 10.0) = 2.2;
uniform float sway_waves : hint_range(0.0, 10.0) = 3.0;
// L'étirement du linceul vers le bas de la pièce (en mètres, là où le poids vaut 1) : penché pour plonger, le spectre
// le traîne derrière lui.
uniform float trail : hint_range(0.0, 2.0) = 0.0;
// La dissolution : au-delà de ce poids, le linceul s'efface en volutes.
uniform float fade_start : hint_range(0.0, 1.0) = 0.45;

varying vec3 local;
varying vec3 weights;

void vertex() {
	float w = COLOR.r;
	float phase = TIME * sway_speed + VERTEX.y * sway_waves;
	VERTEX.x += sin(phase + VERTEX.z * 4.0) * sway * w;
	VERTEX.z += cos(phase * 0.8 + VERTEX.x * 4.0) * sway * w;
	VERTEX.y -= trail * w;
	local = VERTEX;
	weights = COLOR.rgb;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float n = texture(noise, local.xy * 1.3 + local.zy * 0.7 + vec2(TIME * 0.15, TIME * 0.4)).r;
	float flicker = 0.8 + 0.2 * sin(TIME * flicker_speed + n * 6.2832);
	float tatters = 1.0 - smoothstep(fade_start, 1.0, weights.g + (n - 0.5) * 0.5);
	float glow = (core + (1.0 - core) * fresnel) * flicker * tatters * weights.b * 2.0;
	ALBEDO = glow_color * intensity * glow;
	ALPHA = clamp(glow, 0.0, 1.0);
}
