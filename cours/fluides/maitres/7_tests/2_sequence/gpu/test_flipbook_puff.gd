extends GdUnitTestSuite
## Règles du flipbook à l'écran : une image pleine se voit ; à mi-chemin de deux images, on voit leur mélange ; après la dernière image,
## on revient à la première. La scène cuit une planche, rend la carte, et fait avancer l'image.

const SCENE := preload("res://2_sequence/flipbook_puff.tscn")
const VIEW := preload("res://1_core/gpu/shaders/flipbook_view.gdshader")
const PIXELS := 32
const MIDDLE := 16


func _viewport() -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(PIXELS, PIXELS)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	return auto_free(viewport)


## Une planche de deux images d'une ligne : la première vide, la seconde pleine.
func _two_frames(frame: float) -> SubViewport:
	var viewport: SubViewport = _viewport()
	var planche: Image = Image.create_empty(2, 1, false, Image.FORMAT_L8)
	planche.set_pixel(1, 0, Color.WHITE)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = VIEW
	material.set_shader_parameter("flipbook", ImageTexture.create_from_image(planche))
	material.set_shader_parameter("columns", 2)
	material.set_shader_parameter("rows", 1)
	material.set_shader_parameter("frame", frame)
	var plan: MeshInstance3D = MeshInstance3D.new()
	plan.mesh = QuadMesh.new()
	plan.scale = Vector3(4.0, 4.0, 1.0)
	plan.material_override = material
	viewport.add_child(plan)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 1.0)
	viewport.add_child(camera)
	return viewport


## L'image du viewport. Une scène immobile ne redessine pas d'elle-même : on force le dessin.
func _image(viewport: SubViewport) -> Image:
	for _i: int in 3:
		await get_tree().process_frame
		RenderingServer.force_draw(false)
	return viewport.get_texture().get_image()


func test_une_image_vide_ne_se_voit_pas() -> void:
	var image: Image = await _image(_two_frames(0.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_less(0.05)


func test_une_image_pleine_se_voit() -> void:
	var image: Image = await _image(_two_frames(1.0))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_greater(0.98)


func test_entre_deux_images_on_voit_leur_melange() -> void:
	var image: Image = await _image(_two_frames(0.25))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_equal_approx(0.25, 0.02)


func test_apres_la_derniere_image_on_revient_a_la_premiere() -> void:
	var image: Image = await _image(_two_frames(1.75))
	assert_float(image.get_pixel(MIDDLE, MIDDLE).a).is_equal_approx(0.25, 0.02)


func test_la_scene_cuit_une_planche_et_la_joue() -> void:
	var viewport: SubViewport = _viewport()
	var puff: Node3D = SCENE.instantiate()
	viewport.add_child(puff)
	var material: ShaderMaterial = puff.get("_material")
	assert_object(material.get_shader_parameter("flipbook")).is_not_null()
	var image: Texture2D = material.get_shader_parameter("flipbook")
	assert_int(image.get_width()).is_equal(32 * 4)
	for _i: int in 4:
		await get_tree().process_frame
	var image_montree: float = material.get_shader_parameter("frame")
	assert_float(image_montree).is_greater(0.0)
