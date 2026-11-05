class_name CameraDef
extends Resource
## La caméra du jeu (`5_data/camera/camera.tres`), la même pour le jeu et pour la vue rendue de l'éditeur : une caméra
## orthographique (les tailles ne rétrécissent pas avec la distance), tournée autour de la verticale (la vue en
## diagonale : les axes du sol partent en biais à l'écran, comme sur la grille de référence), puis inclinée au-dessus
## du sol. Une inclinaison de 30° écrase la profondeur du sol à sin(30°) = 0,5 à l'écran ; une hauteur s'y voit à
## cos(30°) ≈ 0,866.

## Identifiant de la caméra.
@export var id: StringName = &"camera"
## L'inclinaison : l'angle entre l'axe de la caméra et le sol, en degrés.
@export var pitch_deg: float = 30.0
## La rotation autour de la verticale, en degrés (0 : les axes du sol alignés sur l'écran ; 45 : en diagonale).
@export var yaw_deg: float = 45.0
## La hauteur que montre la vue au zoom 1, en mètres (la taille orthographique) : 9 m, soit 18 m de sol en profondeur
## à 30°, autour du héros, comme dans un roguelike.
@export var view_height_m: float = 9.0
## La distance entre la caméra et le point qu'elle regarde, en mètres (assez pour ne rien couper).
@export var distance_m: float = 80.0


## Les erreurs de la caméra, une phrase par erreur ; vide si elle est valide.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if pitch_deg <= 0.0 or pitch_deg > 90.0:
		errors.append("pitch_deg : inclinaison dans ]0, 90] requise")
	if view_height_m <= 0.0 or distance_m <= 0.0:
		errors.append("view_height_m, distance_m : valeurs positives requises")
	return errors
