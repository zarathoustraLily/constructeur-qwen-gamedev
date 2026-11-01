extends GdUnitTestSuite
## Règles de la cuisson des six lumières. Dans un volume uniforme, chaque réponse se calcule à la main : on compare. Autour d'une boule,
## le côté éclairé est du côté de la lumière, et les réponses opposées sont le miroir l'une de l'autre.

const SIZE := Vector3i(16, 16, 16)
const DENSITY := 0.5
const ABSORPTION := 2.0

var _device: ComputeDevice
var _baker: SixWayBaker


func before_test() -> void:
	_device = ComputeDevice.open()
	_baker = SixWayBaker.new(_device)


func after_test() -> void:
	_device.release()


func _uniform() -> Array[Image]:
	var plein: RID = _device.new_volume(SIZE, false)
	_device.rd.texture_clear(plein, Color(DENSITY, 0.0, 0.0, 0.0), 0, 1, 0, 1)
	return _baker.bake(plein, ABSORPTION)


func _ball() -> Array[Image]:
	var settings: VolumeSettings = VolumeSettings.new()
	settings.size = SIZE
	var volume: GpuVolume = GpuVolume.new(_device, settings)
	volume.add_source(Vector3(7.5, 7.5, 7.5), 6.0, 2.0, 0.0)
	return _baker.bake(volume.density, ABSORPTION)


## Ce qui reste de la lumière après une case.
func _passing() -> float:
	return exp(-ABSORPTION * DENSITY / SIZE.z)


func test_vue_d_en_face_une_lumiere_de_face_traverse_deux_fois() -> void:
	var attendu: float = 0.0
	for k: int in SIZE.z:
		attendu += (1.0 - _passing()) * pow(_passing(), 2.0 * k)
	assert_float(_uniform()[1].get_pixel(8, 8).b).is_equal_approx(attendu, 0.001)


func test_vue_d_en_face_une_lumiere_de_dos_fait_toujours_le_meme_chemin() -> void:
	var attendu: float = SIZE.z * (1.0 - _passing()) * pow(_passing(), SIZE.z - 1.0)
	assert_float(_uniform()[0].get_pixel(8, 8).b).is_equal_approx(attendu, 0.001)


func test_une_lumiere_de_cote_perd_ce_qui_la_separe_du_pixel() -> void:
	var x: int = 3
	var vue: float = 1.0 - pow(_passing(), float(SIZE.z))
	var attendu: float = vue * pow(_passing(), SIZE.x - 1.0 - x)
	assert_float(_uniform()[0].get_pixel(x, 8).r).is_equal_approx(attendu, 0.001)


func test_l_opacite_est_celle_de_la_loi_de_beer_lambert() -> void:
	var attendu: float = 1.0 - RayMarch.transmittance(PackedFloat32Array([DENSITY]), 1.0, ABSORPTION)
	assert_float(_uniform()[0].get_pixel(8, 8).a).is_equal_approx(attendu, 0.001)


func test_un_volume_vide_ne_renvoie_rien() -> void:
	var images: Array[Image] = _baker.bake(_device.new_volume(SIZE, false), ABSORPTION)
	assert_that(images[0].get_pixel(8, 8)).is_equal(Color(0.0, 0.0, 0.0, 0.0))
	assert_that(images[1].get_pixel(8, 8)).is_equal(Color(0.0, 0.0, 0.0, 0.0))


func test_le_cote_eclaire_est_du_cote_de_la_lumiere() -> void:
	var images: Array[Image] = _ball()
	assert_float(images[0].get_pixel(11, 8).r).is_greater(images[0].get_pixel(4, 8).r)
	assert_float(images[1].get_pixel(4, 8).r).is_greater(images[1].get_pixel(11, 8).r)


func test_le_haut_de_l_image_recoit_la_lumiere_du_haut() -> void:
	var images: Array[Image] = _ball()
	assert_float(images[0].get_pixel(8, 4).g).is_greater(images[0].get_pixel(8, 11).g)


func test_droite_et_gauche_sont_le_miroir_l_une_de_l_autre() -> void:
	var images: Array[Image] = _ball()
	for x: int in range(2, SIZE.x - 2):
		assert_float(images[0].get_pixel(x, 8).r).is_equal_approx(images[1].get_pixel(SIZE.x - 1 - x, 8).r, 0.001)


func test_haut_et_bas_sont_le_miroir_l_un_de_l_autre() -> void:
	var images: Array[Image] = _ball()
	for y: int in range(2, SIZE.y - 2):
		assert_float(images[0].get_pixel(8, y).g).is_equal_approx(images[1].get_pixel(8, SIZE.y - 1 - y).g, 0.001)
