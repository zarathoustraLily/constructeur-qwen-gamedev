# Caméra qui suit sa cible en douceur, à la même vitesse quelle que soit la cadence

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier camera_suivi_lisse`.

## Ce que fait le morceau

La caméra rattrape sa cible avec retard : à chaque image, elle parcourt une part `1 - exp(-smoothing × delta)` du chemin qui reste. Après une même durée, elle est au même endroit à 30 ou à 120 images par seconde.

## Quand l'employer

Caméra à la troisième personne, vue de dessus, caméra de course, curseur ou viseur qui suit la souris.

Dans un projet qui suit le plan : un mécanisme générique dans `1_core/camera/`, comme la `ShakeCamera3D` du cours roguelike ; ses réglages sont exportés et posés dans la scène du niveau ; elle bouge dans `_process` (présentation, règle SIM-01 du plan) et reçoit sa cible par `setup()` (principe 4).

## Le code (`1_core/camera/follow_camera_3d.gd`, vérifié)

```gdscript
class_name FollowCamera3D
extends Camera3D
## Caméra qui suit sa cible avec retard. Le lissage ne dépend pas de la cadence d'images : chaque pas rapproche la
## caméra d'une part 1 - exp(-smoothing × delta) du chemin qui reste. Présentation : elle bouge dans _process.
## Entrées : setup().

## Place de la caméra par rapport à la cible.
@export var offset: Vector3 = Vector3.ZERO
## Vitesse du rattrapage, par seconde : plus elle est grande, plus la caméra colle à la cible.
@export var smoothing: float = 0.0

var _target: Node3D


func setup(target: Node3D) -> void:
	_target = target
	global_position = target.global_position + offset


func _process(delta: float) -> void:
	if _target != null:
		follow(delta)


## Un pas de suivi, de durée `delta`.
func follow(delta: float) -> void:
	var place := _target.global_position + offset
	global_position = global_position.lerp(place, 1.0 - exp(-smoothing * delta))
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : après 0.2 s, écart entre 30 et 120 images/s 0.000000 m, reste 3.6788 m (10 × e^-1 = 3.6788) ; lissage naïf : reste 3.349 m à 30 images/s, 3.601 m à 120.

## Pièges

- `lerp(cible, smoothing × delta)` dépend de la cadence (mesuré : après 0,2 s, il reste 3,349 m à 30 images/s et 3,601 m à 120, contre 3,679 m pour les deux avec `1 - exp(-smoothing × delta)`).
- La caméra suit la cible après que celle-ci a bougé : une cible déplacée dans `_physics_process` et une caméra dans `_process` peuvent trembler quand les deux cadences diffèrent ; l'interpolation de physique (`physics/common/physics_interpolation`) les accorde (godot-docs, physics_interpolation ; non mesuré ici).
