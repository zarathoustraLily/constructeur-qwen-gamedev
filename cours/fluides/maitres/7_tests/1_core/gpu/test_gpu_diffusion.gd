extends GdUnitTestSuite
## Règles de la diffusion sur la carte : le chemin n'est pas celui du processeur, mais l'arrivée est la même ; sans échange, rien
## ne bouge ; la matière s'étale sans se perdre, et sans dépasser sa bosse de départ.

const WIDTH := 30
const HEIGHT := 22

var _device: ComputeDevice
var _diffusion: GpuDiffusion


func before_test() -> void:
	_device = ComputeDevice.open()
	_diffusion = GpuDiffusion.new(_device, WIDTH, HEIGHT)


func after_test() -> void:
	_device.release()


## Le champ `source` diffusé sur la carte.
func _diffuse(source: FluidField, rate: float, delta: float, iterations: int) -> FluidField:
	var sortie: RID = _device.new_texture(WIDTH, HEIGHT)
	_diffusion.solve(sortie, GridCheck.texture_of(_device, source), rate, delta, iterations)
	return GridCheck.read(_device, sortie, WIDTH, HEIGHT)


func test_a_force_de_passes_il_arrive_ou_arrive_le_processeur() -> void:
	var source: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Diffusion.solve(attendu, source, 1.5, 0.5, 80)
	assert_float(GridCheck.largest_gap(_diffuse(source, 1.5, 0.5, 80), attendu)).is_less(0.001)


func test_sans_echange_rien_ne_bouge() -> void:
	var source: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	assert_float(GridCheck.largest_gap(_diffuse(source, 0.0, 0.5, 4), source)).is_less(0.0001)


func test_la_matiere_s_etale_sans_se_perdre() -> void:
	var source: FluidField = FluidField.new(WIDTH, HEIGHT)
	source.add_disc(15.0, 11.0, 4.0, 1.0)
	var rendu: FluidField = _diffuse(source, 1.0, 1.0, 40)
	assert_float(rendu.total()).is_equal_approx(source.total(), 0.01)
	assert_float(rendu.peak()).is_less(source.peak())
	assert_float(rendu.at(15, 5)).is_greater(0.0)
