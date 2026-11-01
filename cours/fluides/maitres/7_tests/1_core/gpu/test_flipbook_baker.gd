extends GdUnitTestSuite
## Règles de la cuisson : un volume plein donne ce que dit la loi de Beer-Lambert ; le haut de l'image est le haut du volume ; une planche
## a la taille de ses cases ; chaque image est à sa place ; d'une image à l'autre, la fumée monte.

const SIZE := Vector3i(16, 24, 16)
const ABSORPTION := 2.0

var _device: ComputeDevice
var _baker: FlipbookBaker


func before_test() -> void:
	_device = ComputeDevice.open()
	_baker = FlipbookBaker.new(_device)


func after_test() -> void:
	_device.release()


func _volume() -> GpuVolume:
	var settings: VolumeSettings = VolumeSettings.new()
	settings.size = SIZE
	settings.iterations = 8
	settings.vortex_strength = 0.0
	settings.dissipation = 0.0
	return GpuVolume.new(_device, settings)


func _settings() -> FlipbookSettings:
	var settings: FlipbookSettings = FlipbookSettings.new()
	settings.columns = 2
	settings.rows = 2
	settings.steps_per_frame = 2
	settings.absorption = ABSORPTION
	return settings


func _feed(delta: float, volume: GpuVolume) -> void:
	volume.add_source(Vector3(7.5, 5.0, 7.5), 4.0, 8.0 * delta, 20.0 * delta)


## La hauteur moyenne de la fumée dans une image : plus elle est petite, plus la fumée est haut.
func _row_of(frame: Image) -> float:
	var weighted: float = 0.0
	var total: float = 0.0
	for y: int in frame.get_height():
		for x: int in frame.get_width():
			var value: float = frame.get_pixel(x, y).r
			weighted += value * y
			total += value
	return weighted / total


func test_un_volume_plein_donne_la_loi_de_beer_lambert() -> void:
	var plein: RID = _device.new_volume(SIZE, false)
	_device.rd.texture_clear(plein, Color(0.5, 0.0, 0.0, 0.0), 0, 1, 0, 1)
	var image: Image = _baker.frame_of(_device.new_texture(SIZE.x, SIZE.y), plein, ABSORPTION)
	var attendu: float = 1.0 - RayMarch.transmittance(PackedFloat32Array([0.5]), 1.0, ABSORPTION)
	assert_float(image.get_pixel(8, 12).r).is_equal_approx(attendu, 0.001)


func test_le_haut_de_l_image_est_le_haut_du_volume() -> void:
	var volume: GpuVolume = _volume()
	volume.add_source(Vector3(7.5, 20.0, 7.5), 3.0, 1.0, 0.0)
	var image: Image = _baker.frame_of(_device.new_texture(SIZE.x, SIZE.y), volume.density, ABSORPTION)
	assert_float(image.get_pixel(8, 3).r).is_greater(0.0)
	assert_float(image.get_pixel(8, 20).r).is_equal(0.0)


func test_une_planche_a_la_taille_de_ses_cases() -> void:
	var volume: GpuVolume = _volume()
	var planche: Image = _baker.bake(volume, _settings(), _feed.bind(volume))
	assert_int(planche.get_width()).is_equal(SIZE.x * 2)
	assert_int(planche.get_height()).is_equal(SIZE.y * 2)
	assert_int(planche.get_format()).is_equal(Image.FORMAT_RF)


func test_chaque_image_est_a_sa_place() -> void:
	var volume: GpuVolume = _volume()
	var planche: Image = _baker.bake(volume, _settings(), _feed.bind(volume))
	var seconde: GpuVolume = _volume()
	var cible: RID = _device.new_texture(SIZE.x, SIZE.y)
	var image: Image
	for _i: int in 3:
		for _pas: int in 2:
			_feed(0.033, seconde)
			seconde.step(0.033)
		image = _baker.frame_of(cible, seconde.density, ABSORPTION)
	for y: int in range(0, SIZE.y, 3):
		var attendu: float = image.get_pixel(8, y).r
		assert_float(planche.get_pixel(8, SIZE.y + y).r).is_equal_approx(attendu, 0.0001)


func test_d_une_image_a_l_autre_la_fumee_monte() -> void:
	var volume: GpuVolume = _volume()
	var planche: Image = _baker.bake(volume, _settings(), _feed.bind(volume))
	var premiere: Image = planche.get_region(Rect2i(0, 0, SIZE.x, SIZE.y))
	var derniere: Image = planche.get_region(Rect2i(SIZE.x, SIZE.y, SIZE.x, SIZE.y))
	assert_float(_row_of(derniere)).is_less(_row_of(premiere))
