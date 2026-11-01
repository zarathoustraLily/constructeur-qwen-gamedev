extends GdUnitTestSuite
## Règles du feu sur la carte : la combustion et la poussée rendent ce que rend le processeur ; sous la température d'allumage,
## rien ne brûle ; on ne brûle jamais plus qu'il n'y a de carburant.

const WIDTH := 30
const HEIGHT := 22
const CLOSE := 0.0001

var _device: ComputeDevice
var _combustion: GpuCombustion
var _settings: FireSettings


func before_test() -> void:
	_device = ComputeDevice.open()
	_combustion = GpuCombustion.new(_device, WIDTH, HEIGHT)
	_settings = FireSettings.new()


func after_test() -> void:
	_device.release()


func _lu(texture: RID) -> FluidField:
	return GridCheck.read(_device, texture, WIDTH, HEIGHT)


## Un champ en vagues toutes positives.
func _positive(strength: float) -> FluidField:
	var field: FluidField = GridCheck.waves(WIDTH, HEIGHT, strength)
	for i: int in field.data.size():
		field.data[i] = absf(field.data[i])
	return field


func test_la_combustion_rend_ce_que_rend_le_processeur() -> void:
	var carburant: FluidField = _positive(1.0)
	var chaleur: FluidField = _positive(0.8)
	var suie: FluidField = _positive(0.2)
	var dilatation: FluidField = FluidField.new(WIDTH, HEIGHT)
	var carburant_carte: RID = GridCheck.texture_of(_device, carburant)
	var chaleur_carte: RID = GridCheck.texture_of(_device, chaleur)
	var suie_carte: RID = GridCheck.texture_of(_device, suie)
	var dilatation_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_combustion.burn(carburant_carte, chaleur_carte, suie_carte, dilatation_carte, _settings, 0.1)
	Combustion.burn(carburant, chaleur, suie, dilatation, _settings, 0.1)
	assert_float(GridCheck.largest_gap(_lu(carburant_carte), carburant)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_lu(chaleur_carte), chaleur)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_lu(suie_carte), suie)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_lu(dilatation_carte), dilatation)).is_less(CLOSE)


func test_sous_l_allumage_rien_ne_brule() -> void:
	var carburant: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 1.0)
	var froid: FluidField = GridCheck.filled(carburant, _settings.ignition - 0.05)
	var carburant_carte: RID = GridCheck.texture_of(_device, carburant)
	var chaleur_carte: RID = GridCheck.texture_of(_device, froid)
	var suie_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	var dilatation_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_combustion.burn(carburant_carte, chaleur_carte, suie_carte, dilatation_carte, _settings, 0.1)
	assert_float(_lu(carburant_carte).at(4, 4)).is_equal(1.0)


func test_on_ne_brule_pas_plus_qu_il_n_y_a_de_carburant() -> void:
	var carburant: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 0.01)
	var chaud: FluidField = GridCheck.filled(carburant, 1.0)
	var carburant_carte: RID = GridCheck.texture_of(_device, carburant)
	var chaleur_carte: RID = GridCheck.texture_of(_device, chaud)
	var suie_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	var dilatation_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_combustion.burn(carburant_carte, chaleur_carte, suie_carte, dilatation_carte, _settings, 0.1)
	assert_float(_lu(carburant_carte).at(4, 4)).is_equal(0.0)


func test_la_poussee_rend_ce_que_rend_le_processeur() -> void:
	var v: FluidField = GridCheck.waves(WIDTH, HEIGHT, 3.0)
	var chaleur: FluidField = _positive(1.0)
	var suie: FluidField = _positive(0.5)
	var v_carte: RID = GridCheck.texture_of(_device, v)
	_combustion.lift(v_carte, GridCheck.texture_of(_device, chaleur), GridCheck.texture_of(_device, suie), _settings, 0.1)
	Combustion.lift(v, chaleur, suie, _settings, 0.1)
	assert_float(GridCheck.largest_gap(_lu(v_carte), v)).is_less(CLOSE)
