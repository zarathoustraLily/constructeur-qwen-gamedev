extends GdUnitTestSuite
## Règles du transport sur la carte : il rend ce que rend le processeur à un dix-millième près, simple comme corrigé, jusqu'à
## la dernière case d'une grille qui n'est pas un multiple de 8 ; un courant nul ne change rien ; la correction ne crée pas de
## valeur nouvelle.

const WIDTH := 30
const HEIGHT := 22
const CLOSE := 0.0001

var _device: ComputeDevice
var _transport: GpuAdvection


func before_test() -> void:
	_device = ComputeDevice.open()
	_transport = GpuAdvection.new(_device, WIDTH, HEIGHT)


func after_test() -> void:
	_device.release()


func test_un_courant_nul_ne_change_rien() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var vide: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.semi_lagrangian(sortie, GridCheck.texture_of(_device, champ), vide, vide, 0.5)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, sortie, WIDTH, HEIGHT), champ)).is_less(CLOSE)


func test_le_transport_simple_rend_ce_que_rend_le_processeur() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 6.0)
	var v: FluidField = GridCheck.filled(champ, -2.5)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Advection.semi_lagrangian(attendu, champ, u, v, 0.4)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.semi_lagrangian(sortie, GridCheck.texture_of(_device, champ), GridCheck.texture_of(_device, u), GridCheck.texture_of(_device, v), 0.4)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, sortie, WIDTH, HEIGHT), attendu)).is_less(CLOSE)


func test_la_derniere_case_est_calculee() -> void:
	var champ: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 3.0)
	var vide: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.semi_lagrangian(sortie, GridCheck.texture_of(_device, champ), vide, vide, 0.5)
	assert_float(GridCheck.read(_device, sortie, WIDTH, HEIGHT).at(WIDTH - 1, HEIGHT - 1)).is_equal(3.0)


func test_mac_cormack_rend_ce_que_rend_le_processeur() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 6.0)
	var v: FluidField = GridCheck.filled(champ, 2.5)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	var aller: FluidField = FluidField.new(WIDTH, HEIGHT)
	var retour: FluidField = FluidField.new(WIDTH, HEIGHT)
	Advection.mac_cormack(attendu, champ, u, v, 0.4, aller, retour)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	var aller_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	var retour_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.mac_cormack(sortie, GridCheck.texture_of(_device, champ), GridCheck.texture_of(_device, u), GridCheck.texture_of(_device, v), 0.4, aller_carte, retour_carte)
	assert_float(GridCheck.largest_gap(GridCheck.read(_device, sortie, WIDTH, HEIGHT), attendu)).is_less(CLOSE)


func test_la_correction_ne_cree_pas_de_valeur_nouvelle() -> void:
	var champ: FluidField = FluidField.new(WIDTH, HEIGHT)
	champ.add_disc(15.0, 11.0, 5.0, 1.0)
	var u: RID = GridCheck.texture_of(_device, GridCheck.filled(champ, 8.0))
	var vide: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	var aller: RID = _device.new_texture(WIDTH, HEIGHT)
	var retour: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.mac_cormack(sortie, GridCheck.texture_of(_device, champ), u, vide, 0.3, aller, retour)
	var rendu: FluidField = GridCheck.read(_device, sortie, WIDTH, HEIGHT)
	assert_float(rendu.peak()).is_less_equal(1.0)
	for valeur: float in rendu.data:
		assert_float(valeur).is_greater_equal(0.0)
