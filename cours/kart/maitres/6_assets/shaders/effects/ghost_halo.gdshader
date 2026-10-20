shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_front, shadows_disabled;

// Halo des fantômes (seconde passe de ghost.gdshader) : coque légèrement agrandie dont on ne dessine
// que les faces arrière, en additif. Lumineux au ras de la silhouette, il s'estompe vers l'extérieur.
// Mêmes couleur et fondu que le fantôme, donnés à son matériau par GhostTrail.
uniform vec4 ghost_color : source_color = vec4(1.0, 0.3, 0.9, 1.0);
uniform float ghost_fade = 1.0;

// Taille du halo (agrandissement relatif de la coque)
uniform float halo_size = 0.07;
// Au-dessus de 1, le halo lui-même déclenche le glow de l'environnement
uniform float halo_brightness = 1.6;
uniform float halo_opacity : hint_range(0.0, 1.0) = 0.35;
// Plus grand = halo plus serré autour de la silhouette
uniform float halo_softness = 2.0;

void vertex() {
	VERTEX *= 1.0 + halo_size;
}

void fragment() {
	// Faces arrière : |N.V| vaut 1 derrière le fantôme et 0 au bord extérieur du halo
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = ghost_color.rgb * halo_brightness;
	ALPHA = clamp(pow(facing, halo_softness) * halo_opacity * ghost_fade, 0.0, 1.0);
}
