# Vignette de dégâts (shader canvas_item, plein écran)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier vignette_degats`.

## Ce que fait l'effet

Un voile rouge sur les bords de l'écran, d'autant plus fort que `force` monte (santé basse, coup reçu). Le centre reste libre pour jouer.

## Quand l'employer

Santé basse, coup reçu, poison. Un `ColorRect` plein écran dans un `CanvasLayer` au-dessus du jeu porte le shader ; c'est de la présentation (`4_ui/` ou un `_view.gd`).

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le shader (`vignette.gdshader`, vérifié)

```glsl
shader_type canvas_item;
// Vignette de dégâts : un voile rouge sur les bords de l'écran, d'autant plus fort que `force` est grande (santé
// basse, coup reçu). Le centre reste libre. À poser sur un ColorRect plein écran, au-dessus du jeu.

uniform vec4 tint : source_color = vec4(0.8, 0.0, 0.0, 1.0);
uniform float force : hint_range(0.0, 1.0) = 0.0;
uniform float softness = 0.45;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float voile = smoothstep(0.5 - softness, 0.75, d) * force;
	COLOR = vec4(tint.rgb, voile);
}
```

## Le piloter depuis GDScript (vérifié)

```gdscript
## La force suit la santé : nulle à pleine vie, entière à vie nulle (`part_de_vie` entre 0 et 1).
func suivre_sante(materiau: ShaderMaterial, part_de_vie: float) -> void:
	materiau.set_shader_parameter(&"force", 1.0 - clampf(part_de_vie, 0.0, 1.0))
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : vie nulle, coin (0.80, 0.00, 0.00) et centre (0.30, 0.30, 0.30) égal au fond ; pleine vie, coin 0.30 de rouge.

## Pièges

- `mouse_filter = MOUSE_FILTER_IGNORE` sur le `ColorRect` : avec `MOUSE_FILTER_STOP`, les clics sont marqués traités et ne vont pas plus loin (référence des classes, `Control`).
- La force suit la santé dans la présentation, pas dans la logique (principe 1 du plan).
