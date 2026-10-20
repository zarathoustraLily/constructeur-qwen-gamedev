extends SceneTree
## Test de l'étape {STEP} ({STYLE}) : chaque scène doit se charger, se construire, produire de
## la géométrie, et redonner exactement la même quand on la reconstruit.
#@ 6 quiet
## Le règlement de zonage, en plus : aucune partie de la tour ne doit sortir de son enveloppe,
## et la tour ne doit pas couvrir plus que sa part du terrain.
#@ 7+ quiet
## Le règlement de zonage, en plus : aucune partie de la tour ne doit sortir de son enveloppe,
## la tour ne doit pas couvrir plus que sa part du terrain, et les planchers ne doivent pas
## dépasser la surface permise. Les trois familles de tours ont chacune leur scène.
#@ 11+ quiet
## La graine, en plus : la tour, tout laissé au hasard, sous huit graines ; chaque tirage doit
## donner une tour qui respecte son règlement.
#@ 13+ quiet
## Les niveaux de détail, en plus : de près rien ne manque, et de loin on dessine moins ; et
## chaque boîte d'occultation reste dans sa tour.
#@ all
##
## Il vit dans « 7_tests », au même chemin que ce qu'il teste dans « 6_assets ».
##
## Lancer, depuis le dossier du projet :
##     godot --headless -s "res://7_tests/6_assets/Mesh/Procedural/DECORS/Building/test_{NAME}.gd"
## Le code de sortie vaut 0 si tout passe, 1 sinon.

const SCENES: PackedStringArray = [
	"{MESH}.tscn",
#@ 7+ quiet
	"{MESH}_verre.tscn",
	"{MESH}_verre_integral.tscn",
#@ 12+ quiet
	"{MESH}_quartier.tscn",
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
#@ 6+
		failures += _check_zoning(instance)
#@ 13+
		failures += _check_detail_levels(instance)
		failures += _check_occluders(instance)
#@ 11+
		if path == SCENES[0]:
			failures += _check_seeds(instance)
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
#@ 6+


## Zonage : chaque tour sait mesurer sa marge sous l'enveloppe de son règlement
## (get_zoning_margin) et la part du terrain que couvre sa tour (get_tower_coverage). On le
## demande à toutes celles qu'on trouve sous le nœud, lui compris. Renvoie le nombre d'échecs.
#@ 7+ quiet
## Elle sait aussi son coefficient d'occupation (get_floor_area_ratio) : la surface de ses
## planchers, en multiples de celle du terrain, et ce que le règlement permet.
#@ 6+
func _check_zoning(subject: Node3D) -> int:
	var worst: float = INF
	var worst_coverage: float = -INF
#@ 7+
	var worst_ratio: float = -INF
#@ 6+
	var count: int = 0
	var pending: Array[Node] = [subject]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		pending.append_array(current.get_children(true))
		if not current.has_method("get_zoning_margin"):
			continue
		count += 1
		worst = minf(worst, current.call("get_zoning_margin"))
		# x : la part du terrain couverte par la tour ; y : la part permise.
		var coverage: Vector2 = current.call("get_tower_coverage")
		worst_coverage = maxf(worst_coverage, coverage.x - coverage.y)
#@ 7+
		# x : les planchers, en multiples du terrain ; y : ce qui est permis (infini en 1916).
		var ratio: Vector2 = current.call("get_floor_area_ratio")
		worst_ratio = maxf(worst_ratio, ratio.x - ratio.y)
#@ 6
	if count == 0:
		return 0
	if worst < -0.01 or worst_coverage > 0.001:
		print("ÉCHEC     zonage : ", count, " tour(s), marge la plus faible ", snappedf(worst, 0.01),
				" m, couverture la plus forte ", snappedf(worst_coverage, 0.001), " au-dessus de la part permise")
		return 1
	print("ok        zonage : ", count, " tour(s), marge la plus faible ", snappedf(worst, 0.01), " m")
	return 0
#@ 7+
	if count == 0:
		return 0
	if worst < -0.01 or worst_coverage > 0.001 or worst_ratio > 0.001:
		print("ÉCHEC     zonage : ", count, " tour(s), marge la plus faible ", snappedf(worst, 0.01),
				" m, couverture ", snappedf(worst_coverage, 0.001), " et coefficient ", snappedf(worst_ratio, 0.01),
				" au-dessus de ce qui est permis")
		return 1
	print("ok        zonage : ", count, " tour(s), marge la plus faible ", snappedf(worst, 0.01), " m")
	return 0
#@ 6+
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


## Occultation : chaque gradin de chaque tour pose une boîte d'occultation, et la boîte reste
## dans ce que sa tour dessine : une boîte qui dépasserait cacherait des choses visibles. Sans
## occultation, plus une seule boîte. Renvoie le nombre d'échecs.
func _check_occluders(subject: Node3D) -> int:
	if not "occluders" in subject:
		return 0
	var boxes: int = 0
	var outside: int = 0
	# La boîte de ce que dessine chaque tour, calculée une fois par tour.
	var drawn: Dictionary[Node, AABB] = {}
	var pending: Array[Node] = [subject]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		pending.append_array(current.get_children(true))
		var occluder: OccluderInstance3D = current as OccluderInstance3D
		if occluder == null:
			continue
		boxes += 1
		# L'occulteur est un enfant du nœud interne de sa tour : il est posé dans le même repère
		# que tout ce que la tour dessine.
		var generated: Node = occluder.get_parent()
		if not drawn.has(generated):
			drawn[generated] = _drawn_bounds(generated)
		var size: Vector3 = (occluder.occluder as BoxOccluder3D).size
		var box: AABB = AABB(occluder.position - 0.5 * size, size)
		if not drawn[generated].grow(0.01).encloses(box):
			outside += 1
	# Sans occultation, la tour ne doit plus en poser.
	subject.set("occluders", false)
	subject.call("rebuild")
	var left: int = _count_occluders(subject)
	subject.set("occluders", true)
	subject.call("rebuild")
	if boxes == 0 or outside > 0 or left > 0:
		print("ÉCHEC     occultation : ", boxes, " boîte(s), ", outside, " qui dépasse(nt) de sa tour, ", left, " sans occultation")
		return 1
	print("ok        occultation : ", boxes, " boîte(s), chacune dans sa tour")
	return 0


## La boîte de tout ce que dessinent les enfants d'un nœud, dans le repère de ce nœud.
func _drawn_bounds(generated: Node) -> AABB:
	var bounds: AABB = AABB()
	var first: bool = true
	for child: Node in generated.get_children(true):
		var geometry: GeometryInstance3D = child as GeometryInstance3D
		if geometry == null:
			continue
		var placed: AABB = geometry.transform * geometry.get_aabb()
		bounds = placed if first else bounds.merge(placed)
		first = false
	return bounds


## Nombre de boîtes d'occultation sous un nœud, nœuds internes compris.
func _count_occluders(node: Node) -> int:
	var count: int = 1 if node is OccluderInstance3D else 0
	for child: Node in node.get_children(true):
		count += _count_occluders(child)
	return count
#@ 11+


## La graine : on laisse tout au hasard (famille, couronnement, petits bois, proportions,
## teintes) et on reconstruit la tour sous huit graines. Chaque tirage doit donner des
## triangles et respecter son règlement. Renvoie le nombre d'échecs.
func _check_seeds(subject: Node3D) -> int:
	if not ("variation_seed" in subject and "family_choice" in subject):
		return 0
	var failures: int = 0
	# Combien de tours de chaque famille les huit tirages ont donné.
	var families: Array[int] = [0, 0, 0]
	for seed_value: int in range(1, 9):
		for property: String in ["family_choice", "crown_choice", "window_lights"]:
			subject.set(property, 0)
		subject.set("random_massing", true)
		subject.set("random_colors", true)
		subject.set("variation_seed", seed_value)
		subject.call("rebuild")
		var triangles: int = _count_triangles(subject)
		var margin: float = subject.call("get_zoning_margin")
		var coverage: Vector2 = subject.call("get_tower_coverage")
		var ratio: Vector2 = subject.call("get_floor_area_ratio")
		var family: int = subject.get("family")
		families[family] += 1
		if triangles <= 0 or margin < -0.01 or coverage.x > coverage.y + 0.001 or ratio.x > ratio.y + 0.001:
			print("ÉCHEC     graine ", seed_value, " : ", triangles, " triangles, marge ", snappedf(margin, 0.01), " m")
			failures += 1
	if failures == 0:
		print("ok        graines : 8 tirages, ", families[0], " de brique, ", families[1], " de 1961, ", families[2], " tout en verre")
	return failures
