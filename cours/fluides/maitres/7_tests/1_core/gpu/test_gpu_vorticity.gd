extends GdUnitTestSuite
## Règles des tourbillons sur la carte : la rotation et le confinement rendent ce que rend le processeur ; une rotation uniforme
## ne pousse rien, et sans force il ne se passe rien.

const WIDTH := 30
const HEIGHT := 22
const CLOSE := 0.0001

var _device: ComputeDevice
var _vorticity: GpuVorticity


func before_test() -> void:
	_device = ComputeDevice.open()
	_vorticity = GpuVorticity.new(_device, WIDTH, HEIGHT)


func after_test() -> void:
	_device.release()


func _lu(texture: RID) -> FluidField:
	return GridCheck.read(_device, texture, WIDTH, HEIGHT)


func test_la_rotation_rend_ce_que_rend_le_processeur() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 5.0)
	var v: FluidField = GridCheck.filled(u, 0.0)
	for y: int in HEIGHT:
		for x: int in WIDTH:
			v.put(x, y, 3.0 * sin(0.31 * x) * cos(0.59 * y))
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Vorticity.curl(attendu, u, v)
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_vorticity.curl(sortie, GridCheck.texture_of(_device, u), GridCheck.texture_of(_device, v))
	assert_float(GridCheck.largest_gap(_lu(sortie), attendu)).is_less(CLOSE)


func test_le_confinement_rend_ce_que_rend_le_processeur() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 5.0)
	var v: FluidField = GridCheck.filled(u, 1.0)
	var rotation_champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 2.0)
	var u_carte: RID = GridCheck.texture_of(_device, u)
	var v_carte: RID = GridCheck.texture_of(_device, v)
	_vorticity.confine(u_carte, v_carte, GridCheck.texture_of(_device, rotation_champ), 4.0, 0.1)
	Vorticity.confine(u, v, rotation_champ, 4.0, 0.1)
	assert_float(GridCheck.largest_gap(_lu(u_carte), u)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_lu(v_carte), v)).is_less(CLOSE)


func test_une_rotation_uniforme_ne_pousse_rien() -> void:
	var u: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 1.0)
	var u_carte: RID = GridCheck.texture_of(_device, u)
	var v_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_vorticity.confine(u_carte, v_carte, GridCheck.texture_of(_device, GridCheck.filled(u, 2.0)), 4.0, 0.1)
	assert_float(GridCheck.largest_gap(_lu(u_carte), u)).is_less(CLOSE)


func test_sans_force_il_ne_se_passe_rien() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 5.0)
	var u_carte: RID = GridCheck.texture_of(_device, u)
	var v_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_vorticity.confine(u_carte, v_carte, GridCheck.texture_of(_device, GridCheck.waves(WIDTH, HEIGHT, 2.0)), 0.0, 0.1)
	assert_float(GridCheck.largest_gap(_lu(u_carte), u)).is_less(CLOSE)
