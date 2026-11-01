extends SceneTree
## De quel côté regardent les faces d'une forme ? Le volume signé d'une forme fermée est positif si elles regardent dehors.


func _initialize() -> void:
	for nom: String in ["saloon_collision.res", "saloon_solid_collision.res"]:
		var chemin: String = "res://6_assets/Environment/Saloon/" + nom
		var faces: PackedVector3Array = (load(chemin) as ConcavePolygonShape3D).get_faces()
		var volume: float = 0.0
		for i: int in range(0, faces.size(), 3):
			var a: Vector3 = faces[i]
			volume += a.dot((a - faces[i + 2]).cross(a - faces[i + 1])) / 6.0
		print("%s : %d triangles, volume signé %d m³" % [nom, floori(faces.size() / 3.0), roundi(volume)])
	quit()
