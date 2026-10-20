@tool
extends Node3D
## Outil d'éditeur : sème des détails (herbe, petites plantes) sur un terrain, en blocs MultiMesh.
## Des rayons verticaux tombent sur une grille ; un point est gardé s'il touche `collider`, reste
## dans la plage de hauteur `rules_vertical_range`, est presque à plat et que le canal vert de
## `terrain_texture` y est presque nul. Boutons « Generate Details » et « Clear Details » dans l'inspecteur.

## Corps de collision du terrain : seuls les rayons qui le touchent posent un détail.
@export var collider : CollisionObject3D 
## Maillage du terrain, lu pour retrouver la normale et les UV au point touché.
@export var terrain_mesh_instance : MeshInstance3D 
## Masque du terrain : un détail n'est posé que là où son canal vert est presque nul.
@export var terrain_texture : Texture2D 
## Image du masque, décompressée au moment de la génération.
var terrain_image : Image
## Données du maillage du terrain (MeshDataTool), lues pendant la génération.
var mesh_data : MeshDataTool

@export_group("Detail", "detail_")
## Pas de la grille de semis (m) ; chaque point est décalé au hasard.
@export var detail_grid_size : float = 0.5
## Maillage d'un détail.
@export var detail_mesh : Mesh
## Matériau appliqué à chaque bloc de détails.
@export var detail_material : Material

@export_group("Generation Rules", "rules_")
## Hauteurs (m) minimale (x) et maximale (y) des points gardés.
@export var rules_vertical_range : Vector2 = Vector2(1, 1e6);

@export_group("Visibility", "visibility_")
## Distance (m) au-delà de laquelle un bloc de détails n'est plus affiché.
@export var visibility_max_range : float = 64.0

@export_group("Bounds", "bounds_")
## Taille (m) de la zone semée.
@export var bounds_size : Vector3 = Vector3(256, 256, 256)
## Centre de la zone semée.
@export var bounds_center : Vector3
## Nombre de blocs par axe ; seuls x et z sont utilisés.
@export var bounds_subdivsion : Vector3i = Vector3i(16,1,16)

## Bouton d'éditeur : efface puis régénère tous les blocs.
@export_tool_button("Generate Details")
var generate_details := func () -> void: _populate()

## Bouton d'éditeur : efface tous les blocs.
@export_tool_button("Clear Details")
var clear_details := func () -> void: _clear()

func _clear() -> void:
	for child in get_children():
		child.queue_free()

func _populate() -> void:
	_clear()
	
	mesh_data = MeshDataTool.new()
	mesh_data.create_from_surface(terrain_mesh_instance.mesh, 0)
	
	terrain_image = terrain_texture.get_image()
	if terrain_image.is_compressed():
		terrain_image.decompress()
	
	var grid_corner: Vector3 = bounds_center - bounds_size * 0.5
		
	var chunk_size := Vector3(bounds_size.x / bounds_subdivsion.x, bounds_size.y / bounds_subdivsion.y, bounds_size.z / bounds_subdivsion.z);	
	for x in range(bounds_subdivsion.x): 
		for z in range(bounds_subdivsion.z):
			var corner: Vector3 = grid_corner + Vector3(chunk_size.x * x, chunk_size.y * 0, chunk_size.z * z)
			var chunk := generate_chunk(chunk_size, corner)
			if chunk:
				add_child(chunk)
				chunk.owner = get_tree().edited_scene_root
			
## Couleur de `image` en `uv` (de 0 à 1), interpolée entre les quatre pixels voisins ; noir hors de l'image.
func sample_image_billinear(image : Image, uv : Vector2) -> Color:
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return Color.BLACK

	uv *= Vector2(image.get_size())
	var px : Vector2 = floor(uv)
	var frac := uv - px

	var x := int(px.x)
	var y := int(px.y)

	var v00 := image.get_pixel(x,     y    )
	var v10 := image.get_pixel(x + 1, y    )
	var v01 := image.get_pixel(x,     y + 1)
	var v11 := image.get_pixel(x + 1, y + 1)

	var v0: Color = lerp(v00, v10, frac.x)
	var v1: Color = lerp(v01, v11, frac.x)
	return lerp(v0, v1, frac.y)
	
## Pour la face `index` du terrain : ses trois positions, puis ses trois normales, puis ses trois UV.
func get_vertex_positions_normals_uvs_of_face(index: int) -> Array:
	var data: Array = []
	for i in range(0, 3):
		data.append(mesh_data.get_vertex(mesh_data.get_face_vertex(index, i)))
	for i in range(0, 3):
		data.append(mesh_data.get_vertex_normal(mesh_data.get_face_vertex(index, i)))
	for i in range(0, 3):
		data.append(mesh_data.get_vertex_uv(mesh_data.get_face_vertex(index, i)))
	return data


## Construit le bloc de détails de taille `chunk_size` dont le coin est `chunk_corner` ;
## renvoie null si aucun point n'est gardé.
func generate_chunk(chunk_size : Vector3, chunk_corner : Vector3) -> MultiMeshInstance3D:
	var transforms : Array[Transform3D]	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	for x in range(ceil(chunk_size.x / detail_grid_size)): 
		for z in range(ceil(chunk_size.z / detail_grid_size)):
			var raycast_pos: Vector3 = Vector3(x + randfn(0, 0.33), 0, z + randfn(0, 0.33)) * detail_grid_size + chunk_corner - Vector3(0, 40, 0)
			var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(raycast_pos + Vector3.UP * bounds_size.y, raycast_pos + 2.0 * Vector3.DOWN * bounds_size.y)
			var result: Dictionary = space_state.intersect_ray(query)
			if result:				
				var other: Object = result["collider"]
				if other != collider:
					continue
					
				var collision_point: Vector3 = result["position"]
				var face_index: int = result["face_index"]
				
				if collision_point.y < rules_vertical_range.x || collision_point.y > rules_vertical_range.y:
					continue
								
				var face_data: Array = get_vertex_positions_normals_uvs_of_face(face_index)

				var b: Vector3 = Geometry3D.get_triangle_barycentric_coords(collision_point, face_data[0], face_data[1], face_data[2])				
				var normal : Vector3 = (face_data[3] * b.x + face_data[4] * b.y + face_data[5] * b.z).normalized()
				var uv : Vector2 = face_data[6] * b.x + face_data[7] * b.y + face_data[8] * b.z
				var terrain_mask: Color = sample_image_billinear(terrain_image, uv)
				
				#const luminance_min = 0.0
				const luminance_max = 0.01
				#var luminance = terrain_mask.r + terrain_mask.g + terrain_mask.b;
				var luminance: float = terrain_mask.g;
				if luminance < luminance_max and normal.dot(Vector3.UP) > 0.85: 
					var height: float = 1.0 #remap(clamp(luminance, luminance_min, luminance_max), luminance_min, luminance_max, 1.0, 0.01)
					
					var t : Transform3D
					t.origin = collision_point - chunk_corner
					
					var basis_x : Vector3 = normal.cross(Vector3(1,0,0)).normalized()
					if basis_x.length() < 0.0001:
						basis_x = normal.cross(Vector3(0,1,0)).normalized()
					var basis_z := basis_x.cross(normal).normalized()
					t.basis.x = basis_x * height
					t.basis.y = normal * height
					t.basis.z = basis_z * height
					t.basis = t.basis.rotated(normal, randf() * 6.28318530718)
					#t.basis.y *= height
					transforms.append(t)
					
	
	var details_count: int = transforms.size()	
	if details_count <= 0:
		return null
			
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = detail_mesh
	
	multi_mesh.instance_count = details_count
	for i in range(details_count):
		multi_mesh.set_instance_transform(i, transforms[i])
		
		
	var chunk := MultiMeshInstance3D.new()	
	chunk.position = chunk_corner
	chunk.multimesh = multi_mesh
	chunk.material_override = detail_material
	chunk.visibility_range_end = visibility_max_range
	
	return chunk
			
