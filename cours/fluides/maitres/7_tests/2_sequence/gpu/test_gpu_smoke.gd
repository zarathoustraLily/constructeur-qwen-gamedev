extends GdUnitTestSuite
## Règles de la fumée à l'écran. L'image se juge par le calcul : à travers un volume plein, chaque pixel doit dire ce que dit la loi de
## Beer-Lambert (`RayMarch`), y compris caméra dans le volume ; hors de la boîte, rien. La scène montre le volume du pas courant, la
## fumée se voit à la source, et quitter la scène rend tout à la carte.

const SCENE := preload("res://2_sequence/gpu_smoke.tscn")
const VIEW := preload("res://1_core/gpu/shaders/smoke_view.gdshader")
const PIXELS := 32
const MIDDLE := 16
const ABSORPTION := 1.0

var _device: ComputeDevice
var _texture: Texture3DRD


func after_test() -> void:
	if _texture != null:
		_texture.texture_rd_rid = RID()
		_texture = null
	if _device != null:
		_device.release()
		_device = null


func _viewport(transparent: bool) -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(PIXELS, PIXELS)
	viewport.own_world_3d = true
	viewport.transparent_bg = transparent
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	return auto_free(viewport)


## Une boîte de côté 1 pleine de fumée de densité 1, et une caméra à la hauteur `camera_z` qui regarde le centre.
func _full_box(camera_z: float) -> SubViewport:
	_device = ComputeDevice.shared()
	var viewport: SubViewport = _viewport(true)
	var filled: RID = _device.new_volume(Vector3i(8, 8, 8), false)
	_device.rd.texture_clear(filled, Color(1.0, 0.0, 0.0, 0.0), 0, 1, 0, 1)
	_texture = Texture3DRD.new()
	_texture.texture_rd_rid = filled
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = VIEW
	material.set_shader_parameter("volume", _texture)
	material.set_shader_parameter("absorption", ABSORPTION)
	var box: MeshInstance3D = MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	box.material_override = material
	viewport.add_child(box)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, camera_z)
	camera.near = 0.01
	viewport.add_child(camera)
	return viewport


## L'image du viewport. Une scène immobile ne redessine pas d'elle-même : on force le dessin.
func _image(viewport: SubViewport) -> Image:
	for _i: int in 3:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
	return viewport.get_texture().get_image()


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_la_lumiere_traverse_le_volume_comme_le_dit_beer_lambert() -> void:
	var image: Image = await _image(_full_box(3.0))
	var attendu: float = 1.0 - RayMarch.transmittance(PackedFloat32Array([1.0]), 1.0, ABSORPTION)
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_equal_approx(attendu, 0.02)


func test_hors_de_la_boite_il_n_y_a_rien() -> void:
	var image: Image = await _image(_full_box(3.0))
	assert_float(image.get_pixel(1, 1).a).is_equal(0.0)


func test_une_camera_dans_le_volume_ne_traverse_que_ce_qui_reste() -> void:
	var image: Image = await _image(_full_box(0.25))
	var attendu: float = 1.0 - RayMarch.transmittance(PackedFloat32Array([1.0]), 0.75, ABSORPTION)
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_equal_approx(attendu, 0.02)


func test_la_texture_montree_est_la_fumee_du_pas_courant() -> void:
	var viewport: SubViewport = _viewport(false)
	var smoke: Node3D = SCENE.instantiate()
	viewport.add_child(smoke)
	await _frames(3)
	var texture: Texture3DRD = smoke.get("_texture")
	var volume: GpuVolume = smoke.get("_volume")
	assert_bool(texture.texture_rd_rid == volume.density).is_true()
	await _frames(1)
	assert_bool(texture.texture_rd_rid == volume.density).is_true()


func test_la_fumee_se_voit_a_la_source_et_pas_ailleurs() -> void:
	var viewport: SubViewport = _viewport(false)
	var smoke: Node3D = SCENE.instantiate()
	viewport.add_child(smoke)
	await _frames(20)
	var image: Image = await _image(viewport)
	var fond: Color = image.get_pixel(1, 1)
	var source: Color = image.get_pixel(MIDDLE, 21)
	var haut_de_la_boite: Color = image.get_pixel(MIDDLE, 12)
	assert_float(source.r).is_greater(fond.r + 0.05)
	assert_float(haut_de_la_boite.r).is_equal_approx(fond.r, 0.01)


func test_quitter_la_scene_rend_tout_a_la_carte() -> void:
	var viewport: SubViewport = _viewport(false)
	var smoke: Node3D = SCENE.instantiate()
	viewport.add_child(smoke)
	await _frames(1)
	var device: ComputeDevice = smoke.get("_device")
	smoke.free()
	assert_object(device.rd).is_null()
