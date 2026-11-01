shader_type spatial;
// Bobine : un seul lot de dessin pour le bois, le tissu et le métal. La couleur du sommet donne le ton, son alpha la
// matière : 1 le bois, 0,5 le tissu, 0 le métal. La texture ne donne que le veinage, en valeur : le ton reste celui du
// sommet. Les faces arrière se dessinent : la jupe et la cape n'ont qu'une épaisseur.
render_mode cull_disabled;

// Une texture de bois : sa luminosité devient le veinage.
uniform sampler2D grain : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
// La luminosité moyenne de `grain` : le veinage éclaircit au-dessus, assombrit en dessous.
uniform float grain_mean = 0.3;
// La force du veinage sur le bois.
uniform float wood_grain = 0.75;
// La force du veinage sur le tissu : une trame à peine visible.
uniform float cloth_grain = 0.3;

void fragment() {
	float wood = smoothstep(0.6, 0.9, COLOR.a);
	float metal = 1.0 - smoothstep(0.1, 0.4, COLOR.a);
	float vein = dot(texture(grain, UV).rgb, vec3(0.299, 0.587, 0.114)) / grain_mean;
	float strength = mix(mix(cloth_grain, wood_grain, wood), 0.0, metal);
	ALBEDO = COLOR.rgb * clamp(mix(1.0, vein, strength), 0.3, 1.8);
	// Moitié métal : dans une pièce sombre, un métal entier ne reflète que du noir.
	METALLIC = metal * 0.55;
	ROUGHNESS = mix(mix(0.92, 0.6, wood), 0.42, metal);
}
