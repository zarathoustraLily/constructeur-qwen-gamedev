# Flash d'impact (VFX, shader spatial)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier flash_impact`.

## Ce que fait l'effet

Au moment d'un coup, l'objet touché vire à une couleur (le blanc, en général) puis revient : le joueur voit tout de suite qu'il a touché. Le shader mélange la couleur de base et celle du flash selon un paramètre `flash` de 0 à 1, et ajoute la même couleur en émission pour que le flash se voie dans l'ombre.

## Quand l'employer

Ennemi touché, joueur blessé, objet ramassé. Pour un modèle importé, on garde son matériau et on pose ce shader en `next_pass` ou en `material_overlay`.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`flash.gdshader`, vérifié)

```glsl
shader_type spatial;
// Flash d'impact : la surface tourne à la couleur du flash quand `flash` monte vers 1 (un coup reçu), puis revient.

uniform vec4 base_color : source_color = vec4(0.8, 0.15, 0.1, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = mix(base_color.rgb, flash_color.rgb, flash);
	// L'émission garde le flash visible même dans l'ombre.
	EMISSION = flash_color.rgb * flash;
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## Le coup : `flash` passe à 1, puis revient à 0 en `duree` secondes.
func flasher(materiau: ShaderMaterial, duree: float) -> Tween:
	materiau.set_shader_parameter(&"flash", 1.0)
	var regler := func(v: float) -> void: materiau.set_shader_parameter(&"flash", v)
	var tween := create_tween()
	tween.tween_method(regler, 1.0, 0.0, duree)
	return tween
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : centre (0.73, 0.16, 0.13) avant le coup, (1.00, 1.00, 1.00) pendant le flash, (0.73, 0.16, 0.13) après 0.25 s.

## Pièges

- Un matériau est une ressource, partagée par tous les objets qui l'utilisent (godot-docs, resources.rst) : un seul matériau pour tous les ennemis les fait tous flasher. Un `ShaderMaterial` par instance (`duplicate()`), ou un paramètre d'instance (`instance uniform`, réglé par `GeometryInstance3D.set_instance_shader_parameter` ; godot-docs, « Per-instance uniforms »).
- Rien n'arrête le flash précédent : un second coup pendant le flash crée un second `Tween` sur le même paramètre. Garder le `Tween` rendu par `flasher` et l'arrêter (`kill()`) avant d'en lancer un autre (non mesuré ici).
