shader_type spatial;
// Dissolution : la surface disparaît par morceaux quand `progression` monte de 0 à 1, avec un liseré lumineux au bord.
// Le bruit est calculé dans le shader (une texture de bruit marcherait aussi, mais se génère en différé).

uniform vec4 base_color : source_color = vec4(0.2, 0.5, 0.9, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float progression : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform float noise_scale = 8.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	float n = value_noise(UV * noise_scale);
	if (n < progression) {
		discard;
	}
	float bord = 1.0 - smoothstep(0.0, edge_width, n - progression);
	ALBEDO = mix(base_color.rgb, edge_color.rgb, bord * step(0.001, progression));
	EMISSION = edge_color.rgb * bord * step(0.001, progression) * 2.0;
}
