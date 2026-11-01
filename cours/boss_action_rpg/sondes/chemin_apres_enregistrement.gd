extends SceneTree
## ResourceSaver.FLAG_CHANGE_PATH donne-t-il son chemin à la ressource enregistrée ?


func _initialize() -> void:
	var chemin: String = "user://essai_chemin.res"
	var ressource: BoxMesh = BoxMesh.new()
	var erreur: Error = ResourceSaver.save(ressource, chemin, ResourceSaver.FLAG_CHANGE_PATH)
	print("save : ", error_string(erreur), " ; resource_path : [", ressource.resource_path, "]")
	ressource.take_over_path(chemin)
	print("après take_over_path : [", ressource.resource_path, "]")
	DirAccess.remove_absolute(chemin)
	quit()
