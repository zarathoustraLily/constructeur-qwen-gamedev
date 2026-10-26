# Dissolution (VFX, shader spatial)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier dissolution`.

## Ce que fait l'effet

L'objet disparaît par morceaux quand `progression` monte de 0 à 1, avec un liseré lumineux au bord des trous. Chaque fragment compare un bruit à la progression et se retire (`discard`) en dessous.

## Quand l'employer

Ennemi vaincu, objet qui apparaît ou disparaît, téléportation. Le bruit est calculé dans le shader (fonction `value_noise`) : pas de texture à charger.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`dissolution.gdshader`, vérifié)

```glsl
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
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## La disparition : `progression` monte de 0 à 1 en `duree` secondes, puis l'objet est libéré.
func dissoudre(materiau: ShaderMaterial, objet: Node3D, duree: float) -> Tween:
	var regler := func(v: float) -> void: materiau.set_shader_parameter(&"progression", v)
	var tween := create_tween()
	tween.tween_method(regler, 0.0, 1.0, duree)
	tween.tween_callback(objet.queue_free)
	return tween
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : part disparue 0.00, 0.25 puis 1.00 pour une progression de 0, 0,5 et 1 ; 1 appels de dessin sphère dissoute, 0 une fois libérée par dissoudre.

## Pièges

- Une `NoiseTexture2D` génère ses données sur un fil : tant que ce n'est pas fini, elle est vide (référence des classes 4.7.2 : attendre `texture.changed`). Le bruit calculé dans le shader évite ce délai.
- Entièrement dissous, l'objet reste dans la scène et coûte encore son appel de dessin : `dissoudre` le libère à la fin (mesuré par l'exemple).
