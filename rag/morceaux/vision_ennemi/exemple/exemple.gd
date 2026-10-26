extends Node3D
## Exemple : vision d'une sentinelle qui regarde vers -Z (portée 10 m, cône de 45°). On pose un mur et une cible à
## plusieurs endroits : visible devant, cachée derrière le mur (dès la pose du mur, sans attendre une image de
## physique), hors du cône sur le côté, trop loin, visible en oblique à côté du mur.

const COUCHE_DECOR := 1  # couche 1 du plan : decor


func _ready() -> void:
	var vision := VisionComponent.new()
	vision.range_max = 10.0
	vision.half_angle = 45.0
	vision.obstacle_mask = COUCHE_DECOR
	add_child(vision)
	var cible := Node3D.new()
	add_child(cible)
	await get_tree().physics_frame
	cible.position = Vector3(0.0, 0.0, -5.0)
	var devant := vision.can_see(cible)
	add_child(_mur(Vector3(0.0, 0.0, -3.0)))
	var derriere_des_la_pose := vision.can_see(cible)
	await get_tree().physics_frame
	var derriere := vision.can_see(cible)
	cible.position = Vector3(5.0, 0.0, 0.0)
	var cote := vision.can_see(cible)
	cible.position = Vector3(1.0, 0.0, -12.0)
	var loin := vision.can_see(cible)
	cible.position = Vector3(-4.5, 0.0, -5.0)  # la ligne de visée passe à x = -2,7 au droit du mur, qui s'arrête à -2
	var oblique := vision.can_see(cible)
	var moteur: String = ProjectSettings.get_setting("physics/3d/physics_engine")
	if devant and not derriere_des_la_pose and not derriere and not cote and not loin and oblique:
		print(("EXEMPLE VERIFIE : devant vue ; derrière le mur cachée, dès la pose du mur (moteur physique « %s ») ; "
				+ "sur le côté hors du cône, non vue ; à 12 m, non vue ; en oblique à côté du mur, vue") % moteur)
	else:
		push_error("devant %s, derrière dès la pose %s, derrière %s, côté %s, loin %s, oblique %s"
				% [devant, derriere_des_la_pose, derriere, cote, loin, oblique])
	get_tree().quit()


## Un mur de 4 m de large, 3 m de haut et 0,5 m d'épaisseur, sur la couche du décor.
func _mur(ou: Vector3) -> StaticBody3D:
	var forme := BoxShape3D.new()
	forme.size = Vector3(4.0, 3.0, 0.5)
	var collision := CollisionShape3D.new()
	collision.shape = forme
	var mur := StaticBody3D.new()
	mur.collision_layer = COUCHE_DECOR
	mur.position = ou
	mur.add_child(collision)
	return mur
