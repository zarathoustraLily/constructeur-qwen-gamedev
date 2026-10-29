// La carboglace : une nappe de brume dense au ras du sol, sur une faible hauteur, découpée en volutes par un bruit 3D
// qui dérive lentement avec le temps. Elle s'efface aux bords du volume pour ne pas montrer de mur de brume.
shader_type fog;

// La couleur de la brume : elle prend la lumière des lampes et de la lune.
uniform vec3 albedo : source_color = vec3(0.78, 0.82, 0.9);
// La densité au ras du sol : forte, car la nappe est mince (moins d'un mètre) et la salle sombre.
uniform float density : hint_range(0.0, 20.0) = 8.0;
// La hauteur de la nappe au-dessus du bas du volume, en mètres : la densité y retombe à zéro.
uniform float layer_height : hint_range(0.1, 5.0) = 0.9;
// Le bruit qui fait les volutes (une texture 3D sans couture).
uniform sampler3D noise : repeat_enable;
// La taille des volutes : nombre de motifs du bruit par mètre.
uniform float noise_scale : hint_range(0.01, 1.0) = 0.12;
// La dérive des volutes, en mètres par seconde.
uniform vec3 drift = vec3(0.35, 0.0, 0.15);
// Les seuils du bruit entre un creux de la nappe et une volute pleine.
uniform float wisp_low : hint_range(0.0, 1.0) = 0.35;
uniform float wisp_high : hint_range(0.0, 1.0) = 0.7;
// La densité gardée dans les creux, de 0 à 1 : la nappe ne se troue jamais tout à fait.
uniform float hollow : hint_range(0.0, 1.0) = 0.3;
// La largeur du fondu aux bords du volume, en mètres.
uniform float edge_fade : hint_range(0.0, 10.0) = 2.0;
// La lueur propre de la nappe : elle se lit même là où aucune lampe n'éclaire.
uniform float glow : hint_range(0.0, 1.0) = 0.04;

void fog() {
	float bottom = OBJECT_POSITION.y - SIZE.y * 0.5;
	float above = clamp((WORLD_POSITION.y - bottom) / layer_height, 0.0, 1.0);
	float profile = (1.0 - above) * (1.0 - above);
	float n = texture(noise, (WORLD_POSITION - drift * TIME) * noise_scale).r;
	float wisps = mix(hollow, 1.0, smoothstep(wisp_low, wisp_high, n));
	vec2 to_edge = min(UVW.xz, vec2(1.0) - UVW.xz) * SIZE.xz;
	float edges = clamp(min(to_edge.x, to_edge.y) / max(edge_fade, 0.001), 0.0, 1.0);
	float nappe = profile * wisps * edges;
	DENSITY = density * nappe;
	ALBEDO = albedo;
	EMISSION = albedo * glow * nappe;
}
