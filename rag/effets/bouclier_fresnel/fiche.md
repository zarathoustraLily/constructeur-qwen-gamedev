# Bouclier d'énergie par effet de Fresnel (shader spatial, additif)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier bouclier_fresnel`.

## Ce que fait l'effet

Une bulle transparente au centre et lumineuse sur les bords : la luminosité suit `1 - dot(NORMAL, VIEW)`, forte quand la surface est vue de biais. Le mélange additif (`blend_add`) éclaire ce qui est derrière sans le cacher.

## Quand l'employer

Bouclier, aura, bulle de protection, mise en valeur d'un objet.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`bouclier.gdshader`, vérifié)

```glsl
shader_type spatial;
// Bouclier : plus la surface est vue de biais (bords de la sphère), plus elle brille ; le centre reste transparent.
// C'est l'effet de Fresnel : 1 - dot(NORMAL, VIEW), élevé à une puissance.
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 shield_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);
uniform float power = 3.0;
uniform float intensity = 1.5;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
	ALBEDO = shield_color.rgb * fresnel * intensity;
	ALPHA = fresnel;
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## Un coup encaissé : la bulle brille à `intensite_coup`, puis revient à `intensite` en `duree` secondes.
func encaisser(materiau: ShaderMaterial, intensite: float, intensite_coup: float, duree: float) -> Tween:
	materiau.set_shader_parameter(&"intensity", intensite_coup)
	var regler := func(v: float) -> void: materiau.set_shader_parameter(&"intensity", v)
	var tween := create_tween()
	tween.tween_method(regler, intensite_coup, intensite, duree)
	return tween
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : centre 0.30 de bleu (fond 0.30), bord 0.97, à 17 % de la demi-largeur ; lueur de la ligne 4.9, 8.1 pendant le coup, 4.9 après.

## Pièges

- `depth_draw_never` : la bulle n'écrit pas la profondeur (« Never draw depth », godot-docs, spatial_shader.rst), elle ne masque donc pas ce qu'elle contient (non mesuré ici).
- Avec `cull_back`, seule la face avant de la bulle est dessinée (mesuré : le centre montre le fond).
