// La traîne d'un spectre : une bande de lumière bleue, comme lui, qui se défait en volutes vers son bout. La couleur
// des sommets porte l'âge (alpha 1 : à l'instant, 0 : effacé) ; UV.x va de la tête (0) au bout (1), UV.y d'un bord à
// l'autre. Un bruit qui défile le long de la bande la découpe en lambeaux, d'autant plus que la traîne vieillit. Elle
// s'allume progressivement à sa tête (pas de bord net dans le linceul) et s'efface tout près de la caméra.
// Mélange additif : elle ajoute de la lumière, sans rien cacher.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La couleur de la lueur (celle du spectre).
uniform vec3 glow_color : source_color = vec3(0.35, 0.65, 1.0);
// L'éclat : celui du spectre, qui monte quand il annonce sa plongée.
uniform float intensity : hint_range(0.0, 10.0) = 1.6;
// La part de l'éclat du spectre que garde la traîne.
uniform float strength : hint_range(0.0, 2.0) = 0.8;
// Le bruit des volutes.
uniform sampler2D noise : repeat_enable;
// La vitesse à laquelle les volutes défilent le long de la traîne.
uniform float flow_speed : hint_range(0.0, 5.0) = 1.2;
// La part de la longueur, depuis la tête, sur laquelle la traîne s'allume.
uniform float head_fade : hint_range(0.01, 0.5) = 0.15;
// Les distances à la caméra (en mètres) entre lesquelles elle passe d'effacée à pleine.
uniform float near_fade_start : hint_range(0.0, 5.0) = 0.8;
uniform float near_fade_end : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	float fresh = COLOR.a;
	float edge = sin(clamp(UV.y, 0.0, 1.0) * 3.14159);
	float n = texture(noise, vec2(UV.x * 1.6 - TIME * flow_speed, UV.y * 0.5 + TIME * 0.1)).r;
	float tatters = smoothstep(0.3, 0.7, n + fresh * 0.45);
	float glow = fresh * fresh * edge * edge * tatters;
	// VERTEX est ici la position du pixel vue de la caméra : -VERTEX.z, sa distance devant elle.
	glow *= smoothstep(0.0, head_fade, UV.x) * smoothstep(near_fade_start, near_fade_end, -VERTEX.z);
	ALBEDO = glow_color * intensity * strength * glow;
	ALPHA = clamp(glow, 0.0, 1.0);
}
