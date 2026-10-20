@tool
extends Node3D
## Outil d'éditeur : sème des détails (herbe, petites plantes) sur un terrain, en blocs MultiMesh. La zone
## (`bounds_*`) est découpée en blocs ; dans chaque bloc, des rayons verticaux tombent sur une grille (pas
## `detail_grid_size`, chaque point décalé au hasard). Un point est gardé s'il touche `collider`, reste dans
## la plage de hauteur `rules_vertical_range`, est presque à plat, et que le canal vert de `terrain_texture` y
## est presque nul. Chaque bloc devient un MultiMeshInstance3D enfant, nommé DetailBlockNNN : des milliers de
## brins pour un seul dessin par bloc. Le hasard passe par un RandomNumberGenerator de graine `random_seed` :
## un même terrain et une même graine donnent le même semis (règle SIM-09). Boutons « Generate Details » et
## « Clear Details » dans l'inspecteur.

## Au-delà de cette valeur du canal vert du masque, rien n'est semé (chemins, sable).
const MASK_MAX := 0.01
## En dessous de ce produit scalaire entre la normale et le haut, la pente est trop forte.
const FLAT_MIN := 0.85
## Écart type du décalage au hasard d'un point, en pas de grille.
const JITTER := 0.33
## Les rayons partent d'aussi haut que la zone, depuis ce point sous le bloc.
const RAY_DROP := 40.0

## Corps de collision du terrain : seuls les rayons qui le touchent posent un détail.
@export var collider: CollisionObject3D
## Maillage du terrain, lu pour retrouver la normale et les UV au point touché.
@export var terrain_mesh_instance: MeshInstance3D
## Masque du terrain : un détail n'est posé que là où son canal vert est presque nul.
@export var terrain_texture: Texture2D
## Graine du semis.
@export var random_seed: int = 0
## Image du masque, décompressée au moment de la génération.
var terrain_image: Image
## Données du maillage du terrain (MeshDataTool), lues pendant la génération.
var mesh_data: MeshDataTool

@export_group("Detail", "detail_")
## Pas de la grille de semis (m).
@export var detail_grid_size: float = 0.5
## Maillage d'un détail.
@export var detail_mesh: Mesh
## Matériau appliqué à chaque bloc de détails.
@export var detail_material: Material

@export_group("Generation Rules", "rules_")
## Hauteurs (m) minimale (x) et maximale (y) des points gardés.
@export var rules_vertical_range: Vector2 = Vector2(1, 1e6)

@export_group("Visibility", "visibility_")
## Distance (m) au-delà de laquelle un bloc de détails n'est plus affiché.
@export var visibility_max_range: float = 64.0

@export_group("Bounds", "bounds_")
## Taille (m) de la zone semée.
@export var bounds_size: Vector3 = Vector3(256, 256, 256)
## Centre de la zone semée.
@export var bounds_center: Vector3
## Nombre de blocs par axe ; seuls x et z sont utilisés.
@export var bounds_subdivsion: Vector3i = Vector3i(16, 1, 16)

## Bouton d'éditeur : efface puis régénère tous les blocs.
@export_tool_button("Generate Details")
var generate_details: Callable = func() -> void: populate()

## Bouton d'éditeur : efface tous les blocs.
@export_tool_button("Clear Details")
var clear_details: Callable = func() -> void: clear()


## Efface tous les blocs (à la fin de l'image).
func clear() -> void:
	for child: Node in get_children():
		child.queue_free()


## Lit le maillage et le masque du terrain : à faire avant chunk_transforms().
func load_terrain() -> void:
	mesh_data = MeshDataTool.new()
	mesh_data.create_from_surface(terrain_mesh_instance.mesh, 0)
	terrain_image = terrain_texture.get_image()
	if terrain_image.is_compressed():
		terrain_image.decompress()


## Efface les blocs, puis sème toute la zone, bloc par bloc.
func populate() -> void:
	clear()
	load_terrain()
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var grid_corner: Vector3 = bounds_center - bounds_size * 0.5
	var chunk_size := Vector3(bounds_size.x / bounds_subdivsion.x, bounds_size.y / bounds_subdivsion.y,
		bounds_size.z / bounds_subdivsion.z)
	var count := 0
	for x: int in range(bounds_subdivsion.x):
		for z: int in range(bounds_subdivsion.z):
			var corner: Vector3 = grid_corner + Vector3(chunk_size.x * x, 0.0, chunk_size.z * z)
			var chunk := generate_chunk(chunk_size, corner, rng)
			if chunk != null:
				chunk.name = "DetailBlock%03d" % count
				count += 1
				add_child(chunk)
				if Engine.is_editor_hint():
					chunk.owner = get_tree().edited_scene_root


## Couleur de `image` en `uv` (de 0 à 1), interpolée entre les quatre pixels voisins ; noir hors de l'image.
func sample_image_billinear(image: Image, uv: Vector2) -> Color:
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return Color.BLACK
	uv *= Vector2(image.get_size())
	var px: Vector2 = floor(uv)
	var frac := uv - px
	var x := int(px.x)
	var y := int(px.y)
	var v0: Color = lerp(image.get_pixel(x, y), image.get_pixel(mini(x + 1, image.get_width() - 1), y), frac.x)
	var v1: Color = lerp(image.get_pixel(x, mini(y + 1, image.get_height() - 1)),
		image.get_pixel(mini(x + 1, image.get_width() - 1), mini(y + 1, image.get_height() - 1)), frac.x)
	return lerp(v0, v1, frac.y)


## Pour la face `index` du terrain : ses trois positions, puis ses trois normales.
func face_positions_normals(index: int) -> PackedVector3Array:
	var data := PackedVector3Array()
	for corner: int in range(3):
		data.append(mesh_data.get_vertex(mesh_data.get_face_vertex(index, corner)))
	for corner: int in range(3):
		data.append(mesh_data.get_vertex_normal(mesh_data.get_face_vertex(index, corner)))
	return data


## Pour la face `index` du terrain : les UV de ses trois sommets.
func face_uvs(index: int) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for corner: int in range(3):
		uvs.append(mesh_data.get_vertex_uv(mesh_data.get_face_vertex(index, corner)))
	return uvs


## Les détails du bloc de taille `chunk_size` dont le coin est `chunk_corner` : une transformation par point
## gardé, relative à ce coin, tirée avec le hasard de `rng`.
func chunk_transforms(chunk_size: Vector3, chunk_corner: Vector3, rng: RandomNumberGenerator) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var space_state := get_world_3d().direct_space_state
	for x: int in range(ceili(chunk_size.x / detail_grid_size)):
		for z: int in range(ceili(chunk_size.z / detail_grid_size)):
			var ray_origin: Vector3 = Vector3(x + rng.randfn(0.0, JITTER), 0.0, z + rng.randfn(0.0, JITTER)) \
				* detail_grid_size + chunk_corner - Vector3.UP * RAY_DROP
			var query := PhysicsRayQueryParameters3D.create(ray_origin + Vector3.UP * bounds_size.y,
				ray_origin + 2.0 * Vector3.DOWN * bounds_size.y)
			var hit := space_state.intersect_ray(query)
			if hit.is_empty() or hit["collider"] != collider:
				continue
			var point: Vector3 = hit["position"]
			if point.y < rules_vertical_range.x or point.y > rules_vertical_range.y:
				continue
			var face := face_positions_normals(hit["face_index"])
			var uvs := face_uvs(hit["face_index"])
			var weights: Vector3 = Geometry3D.get_triangle_barycentric_coords(point, face[0], face[1], face[2])
			var normal: Vector3 = (face[3] * weights.x + face[4] * weights.y + face[5] * weights.z).normalized()
			var uv: Vector2 = uvs[0] * weights.x + uvs[1] * weights.y + uvs[2] * weights.z
			if sample_image_billinear(terrain_image, uv).g < MASK_MAX and normal.dot(Vector3.UP) > FLAT_MIN:
				transforms.append(_detail_transform(point - chunk_corner, normal, rng))
	return transforms


## Construit le bloc de détails de taille `chunk_size` dont le coin est `chunk_corner`, avec le hasard de
## `rng` ; renvoie null si aucun point n'est gardé.
func generate_chunk(chunk_size: Vector3, chunk_corner: Vector3, rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var transforms := chunk_transforms(chunk_size, chunk_corner, rng)
	if transforms.is_empty():
		return null
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = detail_mesh
	multi_mesh.instance_count = transforms.size()
	for index: int in transforms.size():
		multi_mesh.set_instance_transform(index, transforms[index])
	var chunk := MultiMeshInstance3D.new()
	chunk.position = chunk_corner
	chunk.multimesh = multi_mesh
	chunk.material_override = detail_material
	chunk.visibility_range_end = visibility_max_range
	return chunk


# Un détail posé en `origin`, debout selon `normal`, tourné au hasard autour d'elle.
func _detail_transform(origin: Vector3, normal: Vector3, rng: RandomNumberGenerator) -> Transform3D:
	var basis_x := normal.cross(Vector3.RIGHT).normalized()
	if basis_x.length() < 0.0001:
		basis_x = normal.cross(Vector3.UP).normalized()
	var basis_z := basis_x.cross(normal).normalized()
	var placed := Transform3D(Basis(basis_x, normal, basis_z), origin)
	placed.basis = placed.basis.rotated(normal, rng.randf() * TAU)
	return placed
