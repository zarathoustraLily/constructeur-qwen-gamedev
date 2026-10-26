extends Node3D
## Exemple minimal de Terrain3D (v1.0.2, GDExtension) : créer une région de terrain vide, y élever un point à 5 m,
## puis relire la hauteur du terrain, comme le ferait un personnage qui cherche le sol.

var _terrain: Terrain3D
var _image: int = 0


func _ready() -> void:
	# le terrain suit la caméra active (niveaux de détail) : sans caméra, il s'arrête avec une erreur
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 20.0, 30.0)
	add_child(camera)
	_terrain = Terrain3D.new()
	add_child(_terrain)
	var donnees := _terrain.get_data()
	donnees.add_region_blankp(Vector3.ZERO)  # une région, là où se trouve le point
	donnees.set_height(Vector3(10.0, 0.0, 10.0), 5.0)
	donnees.update_maps(Terrain3DRegion.TYPE_HEIGHT)  # pousser les cartes modifiées vers le rendu


func _physics_process(_delta: float) -> void:
	_image += 1
	if _image < 5:
		return
	var donnees := _terrain.get_data()
	var haut := donnees.get_height(Vector3(10.0, 0.0, 10.0))
	var plat := donnees.get_height(Vector3(40.0, 0.0, 40.0))
	if donnees.get_region_count() == 1 and is_equal_approx(haut, 5.0) and is_equal_approx(plat, 0.0):
		print("EXEMPLE VERIFIE : %d région, hauteur %.1f m au point élevé, %.1f m ailleurs" % [donnees.get_region_count(), haut, plat])
	else:
		push_error("régions %d, hauteurs %.2f et %.2f" % [donnees.get_region_count(), haut, plat])
	get_tree().quit()
