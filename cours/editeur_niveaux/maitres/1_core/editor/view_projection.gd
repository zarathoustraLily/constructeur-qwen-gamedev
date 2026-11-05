class_name ViewProjection
extends RefCounted
## Le contrat commun des vues de l'éditeur : passer de la salle (en mètres) à l'écran (en pixels) et retour, déplacer,
## zoomer, cadrer. Deux vues le remplissent : la carte vue de dessus (`ViewTransform`) et la vue rendue par la caméra du
## jeu (`CameraTransform`). La souris, la sélection, le cadre bleu et les calques (collisions, apparitions, effets) ne
## parlent qu'à ce contrat : ils marchent dans l'une comme dans l'autre.

## Le zoom ou le déplacement de la vue vient de changer.
signal changed

## Le zoom courant (1 : le zoom de base de la vue).
var zoom: float = 1.0


## Prévient ceux qui écoutent `changed` : chaque vue l'appelle après avoir bougé.
func notify_changed() -> void:
	changed.emit()


## Le point de l'écran où se trouve `world` (un point de la salle, en mètres).
func world_to_screen(_world: Vector3) -> Vector2:
	return Vector2.ZERO


## Le point de la salle, au sol (y = 0), qui se trouve sous `screen`.
func screen_to_world(_screen: Vector2) -> Vector3:
	return Vector3.ZERO


## Le nombre de pixels d'un mètre en largeur, au zoom courant (pour convertir un rayon de prise en mètres).
func pixels_per_meter() -> float:
	return 1.0


## Déplace la vue de `delta` pixels.
func pan(_delta: Vector2) -> void:
	pass


## Multiplie le zoom par `factor`, en gardant immobile le point de la salle sous `screen`.
func zoom_at(_screen: Vector2, _factor: float) -> void:
	pass


## Cadre une salle de taille `size_m` (en mètres) entière, au milieu d'une vue de `view_size` pixels.
func frame(_size_m: Vector2, _view_size: Vector2) -> void:
	pass
