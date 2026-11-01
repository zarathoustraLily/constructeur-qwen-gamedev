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


## Une texture de la carte, remplie avec `field`.
func _texture(field: FluidField) -> RID:
	var texture: RID = _device.new_texture(field.width, field.height)
	_device.upload(texture, field)
	return texture


## Le champ que contient `texture`, une fois la carte arrêtée.
func _read(texture: RID) -> FluidField:
	_device.finish()
	var field: FluidField = FluidField.new(WIDTH, HEIGHT)
	_device.download(texture, field)
	return field


func test_un_courant_nul_ne_change_rien() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var vide: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.semi_lagrangian(sortie, _texture(champ), vide, vide, 0.5)
	assert_float(GridCheck.largest_gap(_read(sortie), champ)).is_less(CLOSE)


func test_le_transport_simple_rend_ce_que_rend_le_processeur() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 6.0)
	var v: FluidField = GridCheck.filled(champ, -2.5)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Advection.semi_lagrangian(attendu, champ, u, v, 0.4)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.semi_lagrangian(sortie, _texture(champ), _texture(u), _texture(v), 0.4)
	assert_float(GridCheck.largest_gap(_read(sortie), attendu)).is_less(CLOSE)


func test_la_derniere_case_est_calculee() -> void:
	var champ: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 3.0)
	var vide: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.semi_lagrangian(sortie, _texture(champ), vide, vide, 0.5)
	assert_float(_read(sortie).at(WIDTH - 1, HEIGHT - 1)).is_equal(3.0)


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
	_transport.mac_cormack(sortie, _texture(champ), _texture(u), _texture(v), 0.4, aller_carte, retour_carte)
	assert_float(GridCheck.largest_gap(_read(sortie), attendu)).is_less(CLOSE)


func test_la_correction_ne_cree_pas_de_valeur_nouvelle() -> void:
	var champ: FluidField = FluidField.new(WIDTH, HEIGHT)
	champ.add_disc(15.0, 11.0, 5.0, 1.0)
	var u: RID = _texture(GridCheck.filled(champ, 8.0))
	var vide: RID = _device.new_texture(WIDTH, HEIGHT)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	var aller: RID = _device.new_texture(WIDTH, HEIGHT)
	var retour: RID = _device.new_texture(WIDTH, HEIGHT)
	_transport.mac_cormack(sortie, _texture(champ), u, vide, 0.3, aller, retour)
	var rendu: FluidField = _read(sortie)
	assert_float(rendu.peak()).is_less_equal(1.0)
	for valeur: float in rendu.data:
		assert_float(valeur).is_greater_equal(0.0)
