extends SceneTree
## Test de l'étape {STEP} ({STYLE}) : chaque scène doit se charger, se construire, produire de
## la géométrie, et redonner exactement la même quand on la reconstruit.
#@ 9+ quiet
## Le gabarit oblique, en plus : aucun mur plein ne doit le percer.
#@ 13+ quiet
## Les niveaux de détail, en plus : de près rien ne manque, et de loin on dessine moins.
#@ all
##
## Il vit dans « 7_tests », au même chemin que ce qu'il teste dans « 6_assets ».
##
## Lancer, depuis le dossier du projet :
##     godot --headless -s "res://7_tests/6_assets/Mesh/Procedural/DECORS/Building/test_{NAME}.gd"
## Le code de sortie vaut 0 si tout passe, 1 sinon.

const SCENES: PackedStringArray = [
	"{MESH}.tscn",
#@ 12+ quiet
	"{MESH}_rue.tscn",
#@ all
]


func _init() -> void:
	var failures: int = 0
	for path: String in SCENES:
		var label: String = path.get_file()
		if not ResourceLoader.exists(path):
			print("ABSENTE   ", label)
			failures += 1
			continue
		var instance: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(instance)
		await process_frame
		var first: int = _count_triangles(instance)
		# Reconstruire ne doit rien changer : mêmes variables, même résultat.
		instance.call("rebuild")
		await process_frame
		var second: int = _count_triangles(instance)
		if first <= 0 or first != second:
			print("ÉCHEC     ", label, " : ", first, " triangles, puis ", second)
			failures += 1
		else:
			print("ok        ", label, " : ", first, " triangles")
#@ 9+
		failures += _check_road_slope(instance)
#@ 13+
		failures += _check_detail_levels(instance)
#@ all
		root.remove_child(instance)
		instance.queue_free()
		await process_frame
	print(SCENES.size(), " scène(s) vérifiée(s), ", failures, " échec(s)")
	quit(1 if failures > 0 else 0)


## Compte les triangles de tout ce qu'un nœud dessine, nœuds internes compris.
func _count_triangles(node: Node) -> int:
	var total: int = 0
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		if current.is_queued_for_deletion():
			continue
		pending.append_array(current.get_children(true))
		total += _triangles_of(current)
	return total


## Triangles d'un seul nœud : un maillage, ou un lot de rectangles instanciés.
func _triangles_of(node: Node) -> int:
	if node is MultiMeshInstance3D:
		return (node as MultiMeshInstance3D).multimesh.instance_count * 2
	if node is MeshInstance3D:
		var mesh: Mesh = (node as MeshInstance3D).mesh
		var total: int = 0
		for surface: int in range(mesh.get_surface_count()):
			total += mesh.surface_get_array_len(surface) / 3
		return total
	return 0
#@ 9+


## Gabarit oblique : une ligne monte depuis le bord opposé de la voie, et aucun mur plein ne
## doit la percer. Chaque immeuble sait calculer sa marge (get_slope_margin) : on la demande à
## tous ceux qu'on trouve sous le nœud, lui compris. Renvoie le nombre d'échecs.
func _check_road_slope(subject: Node3D) -> int:
	var worst: float = INF
	var count: int = 0
	var pending: Array[Node] = [subject]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		pending.append_array(current.get_children(true))
		if current.has_method("get_slope_margin"):
			var margin: float = current.call("get_slope_margin")
			# Une marge infinie : l'immeuble n'a pas de gabarit (road_width à 0).
			if margin < INF:
				worst = minf(worst, margin)
				count += 1
	if count == 0:
		return 0
	if worst < -0.01:
		print("ÉCHEC     gabarit oblique : ", count, " immeuble(s), le pire le dépasse de ", snappedf(-worst, 0.01), " m")
		return 1
	print("ok        gabarit oblique : ", count, " immeuble(s), marge la plus faible ", snappedf(worst, 0.01), " m")
	return 0
#@ 13+


## Niveaux de détail : compte ce qui serait dessiné à trois distances de l'objet, d'après les
## distances de visibilité de chaque nœud. De près, tout ce qui vit dans la zone proche doit
## être là ; plus loin, il doit y avoir moins de triangles. Renvoie le nombre d'échecs.
func _check_detail_levels(subject: Node3D) -> int:
	if not ("near_distance" in subject and "far_distance" in subject):
		return 0
	var near: float = subject.get("near_distance")
	var far: float = subject.get("far_distance")
	if near <= 0.0 or far <= near:
		return 0
	var distances: Array[float] = [0.5 * near, 0.5 * (near + far), far + 50.0]
	var drawn: Array[int] = [0, 0, 0]
	var pending: Array[Node] = [subject]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		pending.append_array(current.get_children(true))
		var geometry: GeometryInstance3D = current as GeometryInstance3D
		if geometry == null:
			continue
		for index: int in range(distances.size()):
			var distance: float = distances[index]
			var hidden: bool = (geometry.visibility_range_end > 0.0 and distance > geometry.visibility_range_end) \
					or (geometry.visibility_range_begin > 0.0 and distance < geometry.visibility_range_begin)
			if not hidden:
				drawn[index] += _triangles_of(geometry)
	if drawn[0] <= drawn[1] or drawn[1] < drawn[2] or drawn[2] <= 0:
		print("ÉCHEC     niveaux de détail : ", drawn[0], " triangles de près, ", drawn[1], " à mi-distance, ", drawn[2], " de loin")
		return 1
	print("ok        niveaux de détail : ", drawn[0], " triangles de près, ", drawn[1], " à mi-distance, ", drawn[2], " de loin")
	return 0
