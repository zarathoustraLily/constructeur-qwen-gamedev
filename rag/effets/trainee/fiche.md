# Traînée derrière un objet (Line2D, dégradé)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier trainee`.

## Ce que fait l'effet

Une ligne suit l'objet : à chaque image, sa position est ajoutée à la fin de la `Line2D` et les points les plus anciens sont retirés au-delà d'une longueur. Un dégradé rend l'arrière transparent.

## Quand l'employer

Projectile, épée, curseur, comète, sillage d'un véhicule vu de dessus.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le piloter depuis GDScript (vérifié)

```gdscript
## La traînée suit `point` : sa position est ajoutée à la fin, les plus anciennes sont retirées au-delà de `longueur`.
func suivre(trainee: Line2D, point: Vector2, longueur: int) -> void:
	trainee.add_point(point)
	while trainee.get_point_count() > longueur:
		trainee.remove_point(0)
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 30 points ; luminance au-dessus du fond 0.66 près du point, 0.07 à l'arrière, -0.00 au départ.

## Pièges

- Le dégradé va du premier point (le plus ancien) au dernier (le plus récent) : transparent en 0, plein en 1 (mesuré : pleine près de l'objet, pâle à l'arrière).
- Les points ajoutés sont des positions du monde : `top_level` empêche la ligne d'hériter du déplacement de son parent (référence des classes, `CanvasItem.top_level`).
- En 3D, Godot 4.7 n'a pas de nœud de traînée ; Godot 4.8 ajoute `Trail3D` (différence d'API mesurée, `python -m usine.vocab difference`).
