// La braise des jointures de l'armure, posée par-dessus son matériau (material_overlay) : n'éclaire que les lignes les
// plus claires de la carte d'émission de l'armure (au-dessus de `threshold`), pas ses plages grises. Allumer
// l'émission du matériau lui-même éclairait toute l'armure : la carte est grise presque partout. Mélange additif.
//@ 20+
// La même couche porte son aura : un liseré de feu sur sa silhouette, là où la surface fuit le regard (Fresnel).
//@ all
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

// La couleur de la braise.
uniform vec4 ember_color : source_color = vec4(1.0, 0.36, 0.08, 1.0);
// L'éclat (0 : rien).
uniform float glow : hint_range(0.0, 8.0) = 0.0;
// La carte d'émission de l'armure : ses lignes claires sont les jointures. Lue telle qu'elle est stockée (sans
// source_color) : le seuil se compare aux valeurs de l'image, pas à leur conversion en couleurs linéaires.
uniform sampler2D lines : filter_linear_mipmap, repeat_enable;
// Seules les lignes plus claires que ce seuil s'allument ; elles brillent pleinement à `threshold + softness`. Vues de
// loin, les lignes fines se mêlent à leur entourage sombre dans les niveaux réduits de la texture : un seuil bas et
// une montée douce les gardent visibles, moins vives.
uniform float threshold : hint_range(0.0, 1.0) = 0.25;
// La montée de l'éclat au-dessus du seuil.
uniform float softness : hint_range(0.01, 1.0) = 0.35;
//@ 20+
// La couleur de l'aura.
uniform vec3 aura_color : source_color = vec3(1.0, 0.3, 0.05);
// L'éclat de l'aura (0 : rien).
uniform float aura : hint_range(0.0, 8.0) = 0.0;
// Plus c'est grand, plus le liseré est fin.
uniform float aura_power : hint_range(0.5, 8.0) = 2.2;
//@ all

void fragment() {
	float joint = smoothstep(threshold, threshold + softness, texture(lines, UV).r);
//@ 13-19
	ALBEDO = ember_color.rgb * glow * joint;
	ALPHA = clamp(joint * glow, 0.0, 1.0);
//@ 20+
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), aura_power) * aura;
	ALBEDO = ember_color.rgb * glow * joint + aura_color * rim;
	ALPHA = clamp(joint * glow + rim, 0.0, 1.0);
//@ all
}
