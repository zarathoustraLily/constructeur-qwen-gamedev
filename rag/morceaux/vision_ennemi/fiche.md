# Vision d'un ennemi : portée, cône et ligne de visée (raycast)

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier vision_ennemi`.

## Ce que fait le morceau

Une cible est vue si elle est assez proche, dans le cône devant l'acteur, et si aucun obstacle des couches surveillées ne coupe la ligne de visée (`PhysicsDirectSpaceState3D.intersect_ray`).

## Quand l'employer

Garde qui repère le joueur, tourelle, caméra de surveillance, ennemi qui décide de poursuivre.

Dans un projet qui suit le plan : un composant dans `1_core/components/`, posé dans la scène de l'ennemi ; ses réglages sont tirés des données de l'ennemi (`5_data/`) ; l'état de l'ennemi (`states/`) l'interroge dans `physics_update`.

## Le code (`1_core/components/vision_component.gd`, vérifié)

```gdscript
class_name VisionComponent
extends Node3D
## Vision d'un acteur : une cible est vue si elle est assez proche, dans le cône devant lui (-Z local), et si aucun
## obstacle ne coupe la ligne de visée. Les obstacles sont les corps des couches de `obstacle_mask`.
## Entrées : can_see(). Réglages : posés dans la scène de l'acteur (valeurs tirées de ses données).

@export var range_max: float = 0.0
## Demi-angle du cône de vision, en degrés.
@export var half_angle: float = 0.0
@export_flags_3d_physics var obstacle_mask: int = 0


func can_see(target: Node3D) -> bool:
	var to_target := target.global_position - global_position
	if to_target.length() > range_max:
		return false
	var forward := -global_basis.z
	if forward.angle_to(to_target) > deg_to_rad(half_angle):
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position, target.global_position, obstacle_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : devant vue ; derrière le mur cachée, dès la pose du mur (moteur physique « DEFAULT ») ; sur le côté hors du cône, non vue ; à 12 m, non vue ; en oblique à côté du mur, vue.

## Pièges

- Un mur posé arrête le rayon tout de suite, sans attendre une image de physique (mesuré, moteur physique par défaut de Godot 4.7.2). Les zones (`Area3D`), elles, ne voient un corps qu'après des images de physique (voir la fiche des couches et masques).
- Le rayon part du centre de l'acteur : le masque ne doit pas contenir la couche de l'acteur lui-même, sinon il se voit (non mesuré ici ; `PhysicsRayQueryParameters3D.exclude` sert aussi).
- L'avant d'un `Node3D` est -Z (`-global_basis.z`) : godot-docs, « Introduction to 3D » (non mesuré ici).
