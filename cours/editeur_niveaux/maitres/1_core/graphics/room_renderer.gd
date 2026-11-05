class_name RoomRenderer
extends Node3D
## Ce qui construit une salle en 3D, vu de l'éditeur : la vue rendue (`4_ui`) ne connaît pas les entités du jeu
## (`3_entities`), seulement ce contrat. La salle du jeu, `Room3DView`, le remplit ; la coquille de l'éditeur, qui
## connaît tout, la donne à la vue.

## Vrai pour montrer les choses inactives (en transparence) : l'éditeur ; faux pour les cacher : le jeu.
var show_inactive: bool = false


## Construit la salle `room`, d'après le catalogue `catalog`.
func build(_room: RoomData, _catalog: AssetCatalogDef) -> void:
	pass


## Pose la chose `thing_id` en `position_m`, tournée de `rotation_deg`, à l'échelle `scale_factor`.
func place(_thing_id: int, _position_m: Vector3, _rotation_deg: float, _scale_factor: float) -> void:
	pass


## Le nombre de sprites de la salle.
func sprite_count() -> int:
	return 0


## Le nœud qui montre la chose `thing_id` (son sprite), ou null.
func sprite_of(_thing_id: int) -> Node3D:
	return null
