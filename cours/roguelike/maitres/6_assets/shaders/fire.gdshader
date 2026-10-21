shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_back, diffuse_lambert, specular_schlick_ggx;

// Flamme d'une particule : un quad toujours tourné vers la caméra (billboard), tourné aussi de l'angle de sa
// particule, où un bruit qui monte avec le temps, éteint vers les bords, dessine une flamme. Chaque particule
// décale son bruit selon son numéro : deux flammes ne se ressemblent pas. Réécriture en code du VisualShader du
// jeu d'origine (Fire.tres), même suite de calculs ; le jeu d'origine le fournissait sans s'en servir.

// Le numéro de la particule, du sommet au fragment ; « flat » : sans interpolation.
varying flat int particle_id;

// Vitesse de montée du bruit, en hauteurs de quad par seconde (la moitié de cette valeur, voir fragment()).
uniform float speed = 2.0;
uniform sampler2D noise_texture : source_color, filter_linear_mipmap;
// Couleur selon l'intensité de la flamme : de gauche (faible) à droite (forte).
uniform sampler2D gradient_texture : source_color;
// Seuil sous lequel la flamme est transparente ; à 0, tout le quad se voit.
uniform float threshold : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Les axes de la caméra (INV_VIEW_MATRIX) à la place de ceux du modèle : le quad lui fait face.
	mat4 billboard = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]),
		MODEL_MATRIX[3]);
	// Tourné dans son plan de l'angle de la particule (INSTANCE_CUSTOM.x, posé par le matériau de particules).
	float angle = INSTANCE_CUSTOM.x;
	billboard = billboard * mat4(vec4(cos(angle), -sin(angle), 0.0, 0.0), vec4(sin(angle), cos(angle), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	// Gardé à l'échelle de la particule.
	billboard = billboard * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard;
	particle_id = INSTANCE_ID;
}

void fragment() {
	vec2 particle_uv = vec2(sin(float(particle_id) / 100.0)) + UV;
	vec2 noise_uv = vec2(0.0, TIME * speed) * vec2(0.5) + particle_uv;
	// Le bruit, éteint vers les bords : (1 - distance au centre)^5.
	float flame = texture(noise_texture, noise_uv).r * pow(1.0 - distance(UV, vec2(0.5)), 5.0);
	vec3 color = texture(gradient_texture, vec2(smoothstep(0.0, 0.3, flame))).rgb;
	ALBEDO = color;
	EMISSION = color;
	ALPHA = step(threshold, flame);
}
