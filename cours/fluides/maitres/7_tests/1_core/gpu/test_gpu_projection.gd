extends GdUnitTestSuite
## Règles de la projection sur la carte : divergence, pression et pente rendent ce que rend le processeur, murs compris, à un
## millième près ; ensemble, elles divisent la divergence ; un mur garde une vitesse nulle. Le test demande un rapport de 5 et
## non zéro : sur cette grille, des hautes fréquences restent quel que soit le nombre de passes (voir la note de l'étape).

const WIDTH := 30
const HEIGHT := 22
const CLOSE := 0.001

var _device: ComputeDevice
var _projection: GpuProjection
var _walls: ObstacleMask
var _mask: RID


func before_test() -> void:
	_device = ComputeDevice.open()
	_projection = GpuProjection.new(_device, WIDTH, HEIGHT)
	_walls = ObstacleMask.new(WIDTH, HEIGHT)
	_walls.add_box(12, 6, 15, 13)
	_mask = _device.new_mask(_walls)


func after_test() -> void:
	_device.release()


## La vitesse de départ, sans vitesse dans les murs.
func _speed(strength: float) -> FluidField:
	var field: FluidField = GridCheck.waves(WIDTH, HEIGHT, strength)
	_walls.clear_inside(field)
	return field


func test_l_image_des_murs_dit_plein_ou_libre() -> void:
	var u: RID = GridCheck.texture_of(_device, GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 2.0))
	var v: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_projection.divergence(sortie, u, v, _mask)
	var rendu: FluidField = GridCheck.read(_device, sortie, WIDTH, HEIGHT)
	assert_float(rendu.at(11, 10)).is_equal(-1.0)
	assert_float(rendu.at(16, 10)).is_equal(1.0)
	assert_float(rendu.at(4, 3)).is_equal(0.0)


func test_la_divergence_rend_ce_que_rend_le_processeur() -> void:
	var u: FluidField = _speed(5.0)
	var v: FluidField = _speed(-3.0)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	FluidProjection.divergence(attendu, u, v, _walls)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_projection.divergence(sortie, GridCheck.texture_of(_device, u), GridCheck.texture_of(_device, v), _mask)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, sortie, WIDTH, HEIGHT), attendu)).is_less(CLOSE)


func test_la_pression_rend_ce_que_rend_le_processeur() -> void:
	var divergence: FluidField = _speed(2.0)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	FluidProjection.solve_pressure(attendu, divergence, _walls, 12, 1.7)
	var pression: RID = _device.new_texture(WIDTH, HEIGHT)
	_projection.solve_pressure(pression, GridCheck.texture_of(_device, divergence), _mask, 12, 1.7)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, pression, WIDTH, HEIGHT), attendu)).is_less(CLOSE)


func test_une_seule_passe_touche_les_deux_couleurs() -> void:
	var divergence: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 1.0)
	var pression: RID = _device.new_texture(WIDTH, HEIGHT)
	_projection.solve_pressure(pression, GridCheck.texture_of(_device, divergence), _mask, 1, 1.0)
	var rendu: FluidField = GridCheck.read(_device, pression, WIDTH, HEIGHT)
	assert_float(rendu.at(2, 2)).is_not_equal(0.0)
	assert_float(rendu.at(3, 2)).is_not_equal(0.0)


func test_un_mur_ne_prend_pas_de_pression() -> void:
	var divergence: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 1.0)
	var pression: RID = _device.new_texture(WIDTH, HEIGHT)
	_projection.solve_pressure(pression, GridCheck.texture_of(_device, divergence), _mask, 6, 1.7)
	assert_float(GridCheck.read(_device, pression, WIDTH, HEIGHT).at(13, 10)).is_equal(0.0)


func test_la_pente_rend_ce_que_rend_le_processeur() -> void:
	var u: FluidField = _speed(5.0)
	var v: FluidField = _speed(-3.0)
	var pression: FluidField = _speed(2.0)
	var u_carte: RID = GridCheck.texture_of(_device, u)
	var v_carte: RID = GridCheck.texture_of(_device, v)
	_projection.subtract_gradient(u_carte, v_carte, GridCheck.texture_of(_device, pression), _mask)
	FluidProjection.subtract_gradient(u, v, pression, _walls)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, u_carte, WIDTH, HEIGHT), u)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, v_carte, WIDTH, HEIGHT), v)).is_less(CLOSE)


func test_un_mur_garde_une_vitesse_nulle() -> void:
	var u_carte: RID = GridCheck.texture_of(_device, _speed(5.0))
	var v_carte: RID = GridCheck.texture_of(_device, _speed(-3.0))
	_projection.subtract_gradient(u_carte, v_carte, GridCheck.texture_of(_device, GridCheck.waves(WIDTH, HEIGHT, 2.0)), _mask)
	assert_float(GridCheck.read(_device, u_carte, WIDTH, HEIGHT).at(13, 10)).is_equal(0.0)
	assert_float(GridCheck.read(_device, v_carte, WIDTH, HEIGHT).at(13, 10)).is_equal(0.0)


func test_la_projection_divise_la_divergence() -> void:
	var u: RID = GridCheck.texture_of(_device, _speed(5.0))
	var v: RID = GridCheck.texture_of(_device, _speed(-3.0))
	var divergence: RID = _device.new_texture(WIDTH, HEIGHT)
	var pression: RID = _device.new_texture(WIDTH, HEIGHT)
	_projection.divergence(divergence, u, v, _mask)
	var avant: float = GridCheck.mean_size(GridCheck.read(_device, divergence, WIDTH, HEIGHT))
	_projection.solve_pressure(pression, divergence, _mask, 60, 1.7)
	_projection.subtract_gradient(u, v, pression, _mask)
	_projection.divergence(divergence, u, v, _mask)
	assert_float(GridCheck.mean_size(GridCheck.read(_device, divergence, WIDTH, HEIGHT))).is_less(avant / 5.0)
