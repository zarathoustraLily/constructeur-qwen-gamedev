class_name RenderedView
extends RoomView
## La vue rendue, celle où l'on édite : la salle construite par `Room3DView` (le code même du jeu), filmée par la caméra du
## jeu (orthographique, inclinée), dans une `SubViewport` à elle dont la vue dessine l'image. Ce qu'on voit est ce que le
## jeu affichera, texture par texture. Les désignations à la souris, le cadre bleu et les calques sont ceux de `RoomView` :
## seule la projection change (`CameraTransform`), et l'emprise de chaque sprite se projette comme Godot le dessine.
## La vue ne connaît pas la salle 3D du jeu (`3_entities`) : elle reçoit un `RoomRenderer` (`set_renderer`), que la
## coquille lui donne. Une grille au sol, comme dans Blender (un trait par mètre, un plus marqué tous les quatre, l'axe x
## en rouge et l'axe z en vert), se dessine par-dessus les dalles, en transparence : on y place les textures au mètre près.
#@ 7+
## Pendant un geste, les sprites concernés suivent l'aperçu ; au relâchement, la salle est reconstruite.
#@ all

## La couleur des traits de la grille, d'un mètre à l'autre.
const GRID_COLOR: Color = Color(1.0, 1.0, 1.0, 0.16)
## La couleur des traits marqués, tous les `GRID_MAJOR` mètres.
const GRID_MAJOR_COLOR: Color = Color(1.0, 1.0, 1.0, 0.32)
## L'écart entre deux traits marqués, en mètres.
const GRID_MAJOR: int = 4
## La couleur de l'axe x (le trait z = 0), comme dans Blender.
const AXIS_X_COLOR: Color = Color(0.9, 0.25, 0.3, 0.9)
## La couleur de l'axe z (le trait x = 0).
const AXIS_Z_COLOR: Color = Color(0.45, 0.75, 0.2, 0.9)

## Vrai pour montrer la grille au sol.
var show_grid: bool = true:
	set(value):
		show_grid = value
		_grid.visible = value

var _viewport: SubViewport = SubViewport.new()
var _grid: MeshInstance3D = MeshInstance3D.new()
var _room3d: RoomRenderer
var _camera: Camera3D = Camera3D.new()
var _camera_transform: CameraTransform


## Donne à la vue ce qui construit la salle en 3D (la salle du jeu) ; à appeler avant `setup`.
func set_renderer(renderer: RoomRenderer) -> void:
	_room3d = renderer


## Branche la vue sur `document` et `catalog`, filmée par la projection de caméra `transform`.
func setup(document: RoomDocument, catalog: AssetCatalogDef, transform: ViewProjection) -> void:
	super(document, catalog, transform)
	_camera_transform = transform as CameraTransform
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_room3d.show_inactive = true
#@ 17+
	_room3d.game_camera = game_camera
#@ all
	_viewport.add_child(_room3d)
	_viewport.add_child(_camera)
	_viewport.add_child(_grid)
	_camera.current = true
	resized.connect(_on_resized)
	document.changed.connect(_rebuild)
	transform.changed.connect(_update_camera)
	_on_resized()
	_rebuild()


## La salle en 3D de la vue (pour les tests).
func room_3d() -> RoomRenderer:
	return _room3d


## La caméra de la vue (pour les tests).
func camera() -> Camera3D:
	return _camera


## La fenêtre de rendu de la vue (pour les tests et les captures).
func viewport() -> SubViewport:
	return _viewport


## La grille au sol (pour les tests).
func grid() -> MeshInstance3D:
	return _grid
#@ 18+


## Reconstruit la salle d'après le catalogue (après l'import d'une planche, qui change ses assets).
func refresh() -> void:
	_rebuild()
	queue_redraw()
#@ all
#@ 7+


## Montre l'aperçu `preview` sur la carte comme dans la vue rendue : les sprites concernés suivent le geste.
func set_preview(preview: Dictionary[StringName, Variant]) -> void:
	super(preview)
	_place(_preview_ids())


## Revient au document : les sprites de l'aperçu reprennent leur place.
func clear_preview() -> void:
	var previewed: Array[int] = _preview_ids()
	super()
	_place(previewed)


func _preview_ids() -> Array[int]:
	var ids: Array[int] = []
	if _preview.has(&"ids"):
		ids.assign(_preview[&"ids"])
	return ids


func _place(ids: Array[int]) -> void:
	for thing_id: int in ids:
		var shown: Dictionary[StringName, Variant] = _shown(thing_id)
		_room3d.place(thing_id, shown[&"position"], shown[&"rotation"], shown[&"scale"])
#@ all


func _draw() -> void:
	draw_texture(_viewport.get_texture(), Vector2.ZERO)


func _rebuild() -> void:
	if not _document.is_open():
		return
	var room: RoomData = _document.snapshot()
	_room3d.build(room, _catalog)
	_build_grid(room.size_m)


# La grille : des traits au sol, d'un bord à l'autre de la salle, tous les mètres.
func _build_grid(size_m: Vector2) -> void:
	var lines: SurfaceTool = SurfaceTool.new()
	lines.begin(Mesh.PRIMITIVE_LINES)
	for x: int in range(ceili(size_m.x) + 1):
		var color: Color = AXIS_Z_COLOR if x == 0 else (GRID_MAJOR_COLOR if x % GRID_MAJOR == 0 else GRID_COLOR)
		_line(lines, Vector3(x, 0.0, 0.0), Vector3(x, 0.0, size_m.y), color)
	for z: int in range(ceili(size_m.y) + 1):
		var color: Color = AXIS_X_COLOR if z == 0 else (GRID_MAJOR_COLOR if z % GRID_MAJOR == 0 else GRID_COLOR)
		_line(lines, Vector3(0.0, 0.0, z), Vector3(size_m.x, 0.0, z), color)
	# Pas de variable nommée material : elle masquerait celle du CanvasItem (une erreur, ici).
	var grid_material: StandardMaterial3D = StandardMaterial3D.new()
	grid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_material.vertex_color_use_as_albedo = true
	grid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_material.no_depth_test = true
	lines.set_material(grid_material)
	_grid.mesh = lines.commit()
	_grid.visible = show_grid


func _line(lines: SurfaceTool, from: Vector3, to: Vector3, color: Color) -> void:
	lines.set_color(color)
	lines.add_vertex(from)
	lines.set_color(color)
	lines.add_vertex(to)


func _on_resized() -> void:
	_viewport.size = Vector2i(maxi(roundi(size.x), 1), maxi(roundi(size.y), 1))
	_camera_transform.resize(size)


func _update_camera() -> void:
	_camera_transform.apply_to(_camera)
	queue_redraw()
