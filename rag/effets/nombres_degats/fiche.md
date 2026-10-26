# Nombres de dégâts flottants (Label3D, Tween)

Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels de l'image : `python -m usine.rag.effets verifier nombres_degats`.

## Ce que fait l'effet

Le nombre de dégâts apparaît au point touché, toujours tourné vers la caméra, monte et s'efface, puis le `Label3D` est libéré. Deux `tween_property` en parallèle (hauteur, transparence), puis `queue_free`.

## Quand l'employer

Dégâts, soins, points gagnés, « Critique ! » au-dessus d'un ennemi.

Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).

## Le piloter depuis GDScript (vérifié)

```gdscript
## Un nombre de dégâts : il monte de `montee` mètres en `duree` secondes en s'effaçant, puis il est libéré.
func afficher_degats(parent: Node3D, valeur: int, ou: Vector3, montee: float, duree: float) -> Label3D:
	var etiquette := Label3D.new()
	etiquette.text = str(valeur)
	etiquette.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # toujours face à la caméra
	etiquette.no_depth_test = true  # lisible même derrière un obstacle
	etiquette.outline_size = 8
	parent.add_child(etiquette)
	etiquette.global_position = ou
	var tween := etiquette.create_tween().set_parallel()  # lié à l'étiquette : il s'arrête avec elle
	tween.tween_property(etiquette, "position:y", etiquette.position.y + montee, duree)
	tween.tween_property(etiquette, "modulate:a", 0.0, duree)
	tween.chain().tween_callback(etiquette.queue_free)
	return etiquette
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 446 pixels de texte au départ (ligne 380), 411 à mi-parcours (ligne 316), 0 à la fin, étiquette libérée.

## Pièges

- Le Tween est créé par l'étiquette (`etiquette.create_tween()`) : il est lié à elle et s'arrête quand elle est libérée (référence des classes, `Node.create_tween`).
- `no_depth_test` : le nombre reste lisible derrière un obstacle (référence des classes, `Label3D.no_depth_test`).
- `chain()` après `set_parallel()` : la libération attend la fin des deux mouvements (mesuré : étiquette libérée après l'effacement).
