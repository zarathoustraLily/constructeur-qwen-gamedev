@tool
extends RefCounted
## Outil générique de maillage procédural : accumule de la géométrie, un maillage par matériau,
## puis en fait des nœuds.
## {STATUS}
##
## Il vit dans « 1_core » parce qu'il ne sait rien d'un immeuble : il sert aussi bien à un
## lampadaire qu'à un rocher. Les scripts de « 6_assets/Mesh/Procedural » l'utilisent à partir
## de l'étape 002 ; l'étape 001 fait la même chose à la main, pour montrer ce qu'il cache.
##
## Mode d'emploi :
##     var mesh: MeshBuilder = MeshBuilder.new()
##     mesh.box(Vector3(1, 2, 0.5), Vector3(0, 1, 0), stone)     # autant de formes qu'on veut
##     mesh.commit(parent)                                        # tout devient des nœuds
##
## Tout est émis triangle par triangle, avec des normales mais sans tangentes ni UV : les
## shaders procéduraux du cours calculent leur motif d'après la position. Les rectangles qui
## portent un shader à UV (fenêtres, garde-corps, enseignes) sont instanciés dans des
## MultiMesh, un par matériau (étape 004).
#@ 13+ quiet
##
## Niveaux de détail (étape 013) : chaque pièce est dessinée dans une ou plusieurs ZONES de
## distance, proche, moyenne, lointaine. Avant d'émettre une pièce, on dit dans quelles zones
## elle vit :
##     mesh.set_zones(MeshBuilder.ZONE_NEAR)                          # un ornement : de près seulement
##     mesh.extrude(profil, ...)
##     mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)    # sa version simple, pour le reste
##     mesh.box(...)
##     mesh.set_zones(MeshBuilder.ZONE_ALL)                           # retour à la normale
## À la fin, commit() fait un maillage par matériau ET par zone, et confie la bascule au moteur
## (les « visibility ranges » de GeometryInstance3D) : aucun script ne tourne pendant le jeu.
#@ all

## Deux facettes voisines d'un profil sont lissées si elles font moins que cet angle.
const SMOOTH_ANGLE: float = 0.7
#@ 13+
## Les trois zones de distance. Elles se combinent avec « | » : ZONE_NEAR | ZONE_MID.
const ZONE_NEAR: int = 1
const ZONE_MID: int = 2
const ZONE_FAR: int = 4
const ZONE_ALL: int = 7

## Distance où finit la zone proche, puis celle où finit la zone moyenne, en mètres.
## Les deux à 0 : pas de niveaux de détail, tout ce qui vit dans la zone proche est toujours
## dessiné et les versions simplifiées ne sont pas fabriquées.
var near_distance: float = 0.0
var far_distance: float = 0.0
#@ 2-12

var _surfaces: Dictionary[Material, SurfaceTool] = {}
var _panels: Dictionary[Material, Array] = {}
var _nodes: Array[Node3D] = []
var _unit_quad: QuadMesh = QuadMesh.new()
#@ 13+

# Ce qu'on accumule est rangé par « case » : une combinaison de zones et d'ombre portée (voir
# _bucket_key). Dans chaque case, un SurfaceTool par matériau, et une liste de rectangles
# instanciés par matériau. GDScript n'écrit pas les types imbriqués (Dictionary[int,
# Dictionary[Material, SurfaceTool]]) : chaque case est créée avec son type complet, et relue
# avec ce même type.
var _surfaces: Dictionary[int, Dictionary] = {}
var _panels: Dictionary[int, Dictionary] = {}
## Nœuds tout faits, et la case où chacun a été ajouté (même rang dans les deux tableaux).
var _nodes: Array[Node3D] = []
var _node_keys: Array[int] = []
var _unit_quad: QuadMesh = QuadMesh.new()
## Zones et ombre portée de ce qui sera émis ensuite.
var _zones: int = ZONE_ALL
var _cast_shadow: bool = true
#@ all


# --- Repères des moulures ---------------------------------------------------

## Repère d'une moulure horizontale qui court le long de X : la saillie de son profil va vers
## l'avant (+Z), sa hauteur vers le haut. « origin » est le milieu de sa longueur.
static func along_x(origin: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.BACK, Vector3.UP, Vector3.RIGHT), origin)


## Repère d'un chambranle vertical : la largeur de son profil s'éloigne de la baie vers
## « side » fois +X, sa saillie va vers l'avant (+Z). « origin » est le milieu de sa hauteur.
static func jamb(origin: Vector3, side: float) -> Transform3D:
	return Transform3D(Basis(Vector3(side, 0.0, 0.0), Vector3.BACK, Vector3.UP), origin)


## Repère d'un chambranle horizontal : la largeur de son profil s'éloigne de la baie vers le
## haut, sa saillie va vers l'avant (+Z). « origin » est le milieu de sa longueur.
static func head(origin: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, Vector3.BACK, Vector3.RIGHT), origin)


## Repère d'un profil vu de face (x vers +X, y vers le haut), extrudé vers l'avant (+Z).
static func facing_street(origin: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, origin)


#@ 13+
# --- Niveaux de détail ------------------------------------------------------

## Choisit les zones de distance où sera dessiné tout ce qu'on émet ensuite, et si ces pièces
## portent une ombre. « zones » combine ZONE_NEAR, ZONE_MID et ZONE_FAR ; les zones choisies
## doivent se suivre (proche et lointaine sans la moyenne n'a pas de sens).
## Un petit ornement n'a pas besoin de porter d'ombre : c'est autant de triangles en moins
## dans le rendu des ombres.
func set_zones(zones: int, cast_shadow: bool = true) -> void:
	assert(zones != (ZONE_NEAR | ZONE_FAR), "Zones proche et lointaine sans la zone moyenne.")
	_zones = zones
	_cast_shadow = cast_shadow


## Vrai si ce qu'on s'apprête à émettre ne servirait à rien : sans niveaux de détail, les
## versions simplifiées (celles qui ne vivent pas dans la zone proche) ne sont pas fabriquées.
func _skipped() -> bool:
	return near_distance <= 0.0 and far_distance <= 0.0 and (_zones & ZONE_NEAR) == 0


## Numéro de la case courante : les zones, plus 8 si la pièce ne porte pas d'ombre.
func _bucket_key() -> int:
	return _zones + (0 if _cast_shadow else 8)


#@ all
# --- Triangles --------------------------------------------------------------

## Triangle à normales par sommet. L'ordre des sommets est remis d'aplomb d'après les normales.
func triangle(a: Vector3, b: Vector3, c: Vector3, normal_a: Vector3, normal_b: Vector3, normal_c: Vector3, material: Material) -> void:
#@ 13+
	if _skipped():
		return
#@ all
	var surface: SurfaceTool = _surface(material)
	# Godot prend pour face avant celle dont les sommets tournent dans le sens des aiguilles.
	if (b - a).cross(c - a).dot(normal_a + normal_b + normal_c) > 0.0:
		surface.set_normal(normal_a)
		surface.add_vertex(a)
		surface.set_normal(normal_c)
		surface.add_vertex(c)
		surface.set_normal(normal_b)
		surface.add_vertex(b)
	else:
		surface.set_normal(normal_a)
		surface.add_vertex(a)
		surface.set_normal(normal_b)
		surface.add_vertex(b)
		surface.set_normal(normal_c)
		surface.add_vertex(c)


## Quadrilatère plan a-b-c-d, de normale donnée.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, material: Material) -> void:
	triangle(a, b, c, normal, normal, normal, material)
	triangle(a, c, d, normal, normal, normal, material)


## Quadrilatère a-b-c-d à normales par sommet, pour les surfaces courbes.
func smooth_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal_a: Vector3, normal_b: Vector3, normal_c: Vector3, normal_d: Vector3, material: Material) -> void:
	triangle(a, b, c, normal_a, normal_b, normal_c, material)
	triangle(a, c, d, normal_a, normal_c, normal_d, material)


# --- Volumes simples --------------------------------------------------------

## Boîte centrée sur « center ». « orientation » la fait tourner autour de son centre.
func box(size: Vector3, center: Vector3, material: Material, orientation: Basis = Basis.IDENTITY) -> void:
	var half: Vector3 = 0.5 * size
	for axis: int in range(3):
		var first: int = (axis + 1) % 3
		var second: int = (axis + 2) % 3
		for direction: float in [-1.0, 1.0]:
			var normal: Vector3 = Vector3.ZERO
			normal[axis] = direction
			var corners: Array[Vector3] = []
			for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
				var point: Vector3 = Vector3.ZERO
				point[axis] = direction * half[axis]
				point[first] = corner.x * half[first]
				point[second] = corner.y * half[second]
				corners.append(center + orientation * point)
			quad(corners[0], corners[1], corners[2], corners[3], orientation * normal, material)


## Tronc de cône fermé en haut, d'axe Y avant rotation par « orientation ».
## Avec deux rayons égaux, c'est un cylindre : poteau, tuyau, réservoir.
func cone(center: Vector3, bottom_radius: float, top_radius: float, height: float, material: Material,
		orientation: Basis = Basis.IDENTITY, segments: int = 12) -> void:
	var slant: float = atan2(bottom_radius - top_radius, height)
	var up: Vector3 = orientation * Vector3.UP
	var low: Vector3 = center - up * (0.5 * height)
	var high: Vector3 = center + up * (0.5 * height)
	for index: int in range(segments):
		var angle_a: float = TAU * float(index) / float(segments)
		var angle_b: float = TAU * float(index + 1) / float(segments)
		var out_a: Vector3 = orientation * Vector3(cos(angle_a), 0.0, sin(angle_a))
		var out_b: Vector3 = orientation * Vector3(cos(angle_b), 0.0, sin(angle_b))
		var normal_a: Vector3 = (out_a * cos(slant) + up * sin(slant)).normalized()
		var normal_b: Vector3 = (out_b * cos(slant) + up * sin(slant)).normalized()
		smooth_quad(low + out_a * bottom_radius, low + out_b * bottom_radius, high + out_b * top_radius, high + out_a * top_radius,
				normal_a, normal_b, normal_b, normal_a, material)
		triangle(high, high + out_a * top_radius, high + out_b * top_radius, up, up, up, material)


# --- Polygones et profils ---------------------------------------------------

## Polygone plan quelconque, donné dans le plan XY de « frame ». Sa normale est l'axe Z de
## « frame », ou son opposé si « flipped » est vrai.
func polygon(outline: PackedVector2Array, frame: Transform3D, material: Material, flipped: bool = false) -> void:
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(outline)
	var normal: Vector3 = frame.basis.z.normalized() * (-1.0 if flipped else 1.0)
	for index: int in range(0, indices.size(), 3):
		var a: Vector2 = outline[indices[index]]
		var b: Vector2 = outline[indices[index + 1]]
		var c: Vector2 = outline[indices[index + 2]]
		triangle(frame * Vector3(a.x, a.y, 0.0), frame * Vector3(b.x, b.y, 0.0), frame * Vector3(c.x, c.y, 0.0), normal, normal, normal, material)


## Profil fermé, donné dans le plan XY de « frame », extrudé sur « length » le long de son axe Z
## et centré sur l'origine de « frame ». Les arrondis du profil sont lissés.
func extrude(profile: PackedVector2Array, frame: Transform3D, length: float, material: Material, caps: bool = true) -> void:
	var count: int = profile.size()
	if count < 3:
		return
	var normals: PackedVector2Array = _edge_normals(profile)
	var back: Vector3 = Vector3(0.0, 0.0, -0.5 * length)
	var front: Vector3 = Vector3(0.0, 0.0, 0.5 * length)
	for index: int in range(count):
		var next: int = (index + 1) % count
		# Normale au début et à la fin de l'arête : moyennée avec la voisine si l'angle est faible.
		var start: Vector2 = _blend(normals[index], normals[(index + count - 1) % count])
		var end: Vector2 = _blend(normals[index], normals[next])
		var p: Vector3 = Vector3(profile[index].x, profile[index].y, 0.0)
		var q: Vector3 = Vector3(profile[next].x, profile[next].y, 0.0)
		var normal_p: Vector3 = (frame.basis * Vector3(start.x, start.y, 0.0)).normalized()
		var normal_q: Vector3 = (frame.basis * Vector3(end.x, end.y, 0.0)).normalized()
		smooth_quad(frame * (p + back), frame * (q + back), frame * (q + front), frame * (p + front),
				normal_p, normal_q, normal_q, normal_p, material)
	if caps:
		polygon(profile, frame * Transform3D(Basis.IDENTITY, front), material)
		polygon(profile, frame * Transform3D(Basis.IDENTITY, back), material, true)


## Profil fermé balayé le long d'un arc d'ellipse tracé dans le plan XY de « frame ».
## Dans le profil, x est l'écart vers l'extérieur de l'arc et y la saillie le long de Z.
## Les angles sont en radians, 0 vers +X et PI/2 vers +Y.
func sweep(profile: PackedVector2Array, frame: Transform3D, radius: Vector2, angle_from: float, angle_to: float, material: Material, steps: int = 20) -> void:
	var count: int = profile.size()
	if count < 3:
		return
	var normals: PackedVector2Array = _edge_normals(profile)
	for step: int in range(steps):
		var angle_a: float = lerpf(angle_from, angle_to, float(step) / float(steps))
		var angle_b: float = lerpf(angle_from, angle_to, float(step + 1) / float(steps))
		for index: int in range(count):
			var next: int = (index + 1) % count
			var normal: Vector2 = normals[index]
			smooth_quad(
					frame * _swept_point(profile[index], radius, angle_a), frame * _swept_point(profile[next], radius, angle_a),
					frame * _swept_point(profile[next], radius, angle_b), frame * _swept_point(profile[index], radius, angle_b),
					frame.basis * _swept_normal(normal, angle_a), frame.basis * _swept_normal(normal, angle_a),
					frame.basis * _swept_normal(normal, angle_b), frame.basis * _swept_normal(normal, angle_b), material)


## Mur percé d'un arc : remplit, au-dessus d'un arc d'ellipse, le rectangle qui monte jusqu'à
## « top_y », puis ferme la sous-face de l'arc sur l'épaisseur du mur.
## L'arc naît en (center.x ± half_width, center.y) et s'élève de « rise ». La face est en center.z.
func arch_wall(center: Vector3, half_width: float, rise: float, top_y: float, depth: float, material: Material, steps: int = 20) -> void:
	for step: int in range(steps):
		var angle_a: float = PI * float(step) / float(steps)
		var angle_b: float = PI * float(step + 1) / float(steps)
		var a: Vector3 = center + Vector3(half_width * cos(angle_a), rise * sin(angle_a), 0.0)
		var b: Vector3 = center + Vector3(half_width * cos(angle_b), rise * sin(angle_b), 0.0)
		quad(a, b, Vector3(b.x, top_y, b.z), Vector3(a.x, top_y, a.z), Vector3.BACK, material)
		# Sous-face : sa normale regarde vers le centre de l'arc.
		var inward_a: Vector3 = -Vector3(cos(angle_a) / half_width, sin(angle_a) / rise, 0.0).normalized()
		var inward_b: Vector3 = -Vector3(cos(angle_b) / half_width, sin(angle_b) / rise, 0.0).normalized()
		var recess: Vector3 = Vector3(0.0, 0.0, -depth)
		smooth_quad(a, b, b + recess, a + recess, inward_a, inward_b, inward_b, inward_a, material)


# --- Rectangles instanciés et nœuds -----------------------------------------

## Rectangle vertical instancié, tourné vers l'axe Z de « frame », aux UV de QuadMesh.
## « custom » et « tint » arrivent au shader par INSTANCE_CUSTOM et COLOR.
func panel(size: Vector2, frame: Transform3D, material: Material, custom: Color = Color(0.0, 0.0, 0.0, 0.0), tint: Color = Color.WHITE) -> void:
#@ 2-12
	if not _panels.has(material):
		var entries: Array[Array] = []
		_panels[material] = entries
	var transform: Transform3D = frame * Transform3D(Basis.from_scale(Vector3(size.x, size.y, 1.0)), Vector3.ZERO)
	_panels[material].append([transform, custom, tint])
#@ 13+
	if _skipped():
		return
	var key: int = _bucket_key()
	if not _panels.has(key):
		var fresh: Dictionary[Material, Array] = {}
		_panels[key] = fresh
	var bucket: Dictionary[Material, Array] = _panels[key]
	if not bucket.has(material):
		var entries: Array[Array] = []
		bucket[material] = entries
	var transform: Transform3D = frame * Transform3D(Basis.from_scale(Vector3(size.x, size.y, 1.0)), Vector3.ZERO)
	bucket[material].append([transform, custom, tint])
#@ all


## Nœud tout fait (une enseigne en Label3D, par exemple), ajouté tel quel au résultat.
func node(child: Node3D) -> void:
#@ 2-12
	_nodes.append(child)
#@ 13+
	if _skipped():
		child.free()
		return
	_nodes.append(child)
	_node_keys.append(_bucket_key())
#@ all


#@ 2-12
## Transforme tout ce qui a été accumulé en nœuds enfants de « parent », puis repart à vide.
func commit(parent: Node3D) -> void:
	for material: Material in _surfaces:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.mesh = _surfaces[material].commit()
		instance.material_override = material
		parent.add_child(instance)
	for material: Material in _panels:
		var entries: Array[Array] = _panels[material]
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.use_colors = true
		multimesh.mesh = _unit_quad
		multimesh.instance_count = entries.size()
		for index: int in range(entries.size()):
			multimesh.set_instance_transform(index, entries[index][0])
			multimesh.set_instance_custom_data(index, entries[index][1])
			multimesh.set_instance_color(index, entries[index][2])
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = material
		parent.add_child(instance)
	for child: Node3D in _nodes:
		parent.add_child(child)
	_surfaces.clear()
	_panels.clear()
	_nodes.clear()
#@ 13+
## Transforme tout ce qui a été accumulé en nœuds enfants de « parent », puis repart à vide.
## Il sort un MeshInstance3D par matériau et par case, un MultiMeshInstance3D pour les
## rectangles instanciés, et règle sur chacun ses distances de visibilité.
func commit(parent: Node3D) -> void:
	# Les nœuds créés, et leur case (même rang dans les deux tableaux) : on en a besoin deux
	# fois, pour leurs distances puis pour leur boîte englobante.
	var created: Array[GeometryInstance3D] = []
	var created_keys: Array[int] = []

	for key: int in _surfaces:
		var bucket: Dictionary[Material, SurfaceTool] = _surfaces[key]
		for material: Material in bucket:
			var instance: MeshInstance3D = MeshInstance3D.new()
			instance.mesh = bucket[material].commit()
			instance.material_override = material
			parent.add_child(instance)
			created.append(instance)
			created_keys.append(key)
	for key: int in _panels:
		var bucket: Dictionary[Material, Array] = _panels[key]
		for material: Material in bucket:
			var entries: Array[Array] = bucket[material]
			var multimesh: MultiMesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.use_custom_data = true
			multimesh.use_colors = true
			multimesh.mesh = _unit_quad
			multimesh.instance_count = entries.size()
			for index: int in range(entries.size()):
				multimesh.set_instance_transform(index, entries[index][0])
				multimesh.set_instance_custom_data(index, entries[index][1])
				multimesh.set_instance_color(index, entries[index][2])
			var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
			instance.multimesh = multimesh
			instance.material_override = material
			parent.add_child(instance)
			created.append(instance)
			created_keys.append(key)

	# Le moteur mesure la distance entre la caméra et le CENTRE de la boîte englobante de chaque
	# nœud. Si chaque nœud gardait sa propre boîte, un ornement et sa version simplifiée ne
	# basculeraient pas au même moment : on verrait les deux, ou aucun. On donne donc à tous la
	# même boîte, celle de l'objet entier.
	var bounds: AABB = AABB()
	var first: bool = true
	for instance: GeometryInstance3D in created:
		var own: AABB = instance.get_aabb()
		bounds = own if first else bounds.merge(own)
		first = false
	# Les nœuds tout faits ont leur propre position : leur boîte est ramenée dans le repère du
	# parent avant d'entrer dans la boîte commune.
	for child: Node3D in _nodes:
		if child is GeometryInstance3D:
			var placed: AABB = child.transform * (child as GeometryInstance3D).get_aabb()
			bounds = placed if first else bounds.merge(placed)
			first = false
	for index: int in range(created.size()):
		_apply_zones(created[index], created_keys[index], bounds)
	for index: int in range(_nodes.size()):
		var child: Node3D = _nodes[index]
		parent.add_child(child)
		if child is GeometryInstance3D:
			# Et dans l'autre sens : la boîte commune, comptée dans le repère du nœud.
			_apply_zones(child as GeometryInstance3D, _node_keys[index], child.transform.affine_inverse() * bounds)

	_surfaces.clear()
	_panels.clear()
	_nodes.clear()
	_node_keys.clear()
	set_zones(ZONE_ALL)


## Règle sur un nœud l'ombre portée et les distances de visibilité de sa case.
func _apply_zones(instance: GeometryInstance3D, key: int, bounds: AABB) -> void:
	var zones: int = key & ZONE_ALL
	if key >= 8:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var far_limit: float = maxf(far_distance, near_distance)
	if zones == ZONE_ALL or far_limit <= 0.0:
		return
	# Distance où la pièce apparaît, puis celle où elle disparaît. 0 : pas de limite.
	var begin: float = 0.0
	var end: float = 0.0
	if (zones & ZONE_NEAR) == 0:
		begin = near_distance if (zones & ZONE_MID) != 0 else far_limit
	if (zones & ZONE_FAR) == 0:
		end = far_limit if (zones & ZONE_MID) != 0 else near_distance
	# Pas de marge autour de ces distances : avec une marge, le moteur attend que la caméra
	# s'éloigne franchement de la limite avant de montrer une pièce, et un ornement comme sa
	# version simplifiée pourraient rester cachés tous les deux.
	instance.visibility_range_begin = begin
	instance.visibility_range_end = end
	instance.custom_aabb = bounds
#@ all


# --- Interne ----------------------------------------------------------------

#@ 2-12
func _surface(material: Material) -> SurfaceTool:
	if not _surfaces.has(material):
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_surfaces[material] = surface
	return _surfaces[material]
#@ 13+
## Le SurfaceTool du matériau dans la case courante, créé au besoin.
func _surface(material: Material) -> SurfaceTool:
	var key: int = _bucket_key()
	if not _surfaces.has(key):
		var fresh: Dictionary[Material, SurfaceTool] = {}
		_surfaces[key] = fresh
	var bucket: Dictionary[Material, SurfaceTool] = _surfaces[key]
	if not bucket.has(material):
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		bucket[material] = surface
	return bucket[material]
#@ all


## Normale extérieure de chaque arête d'un profil fermé, quel que soit son sens de parcours.
func _edge_normals(profile: PackedVector2Array) -> PackedVector2Array:
	var count: int = profile.size()
	var area: float = 0.0
	for index: int in range(count):
		var next: Vector2 = profile[(index + 1) % count]
		area += profile[index].x * next.y - next.x * profile[index].y
	var winding: float = 1.0 if area > 0.0 else -1.0
	var normals: PackedVector2Array = PackedVector2Array()
	for index: int in range(count):
		var edge: Vector2 = profile[(index + 1) % count] - profile[index]
		normals.append((Vector2(edge.y, -edge.x) * winding).normalized())
	return normals


## Normale d'une arête, moyennée avec celle de sa voisine si elles font un angle faible.
func _blend(normal: Vector2, neighbour: Vector2) -> Vector2:
	if absf(normal.angle_to(neighbour)) < SMOOTH_ANGLE:
		return (normal + neighbour).normalized()
	return normal


func _swept_point(point: Vector2, radius: Vector2, angle: float) -> Vector3:
	return Vector3((radius.x + point.x) * cos(angle), (radius.y + point.x) * sin(angle), point.y)


func _swept_normal(normal: Vector2, angle: float) -> Vector3:
	return Vector3(normal.x * cos(angle), normal.x * sin(angle), normal.y).normalized()
