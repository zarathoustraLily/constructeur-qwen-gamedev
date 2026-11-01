extends GdUnitTestSuite
## Règles des passes en 3D. Sur un volume qui ne varie pas en profondeur, chaque tranche donne ce que donne le solveur 2D du processeur :
## divergence, pente, rotation, confinement, et la pression une fois arrivée. Le transport lit par le filtre de la carte : il suit le
## processeur à quelques millièmes. Une boule est plus forte au centre et s'arrête à son rayon. Un courant uniforme déplace une boule
## d'autant, et la chaleur pousse vers le haut. Un volume neuf est vide.

const WIDTH := 24
const HEIGHT := 20
const DEPTH := 12
const MIDDLE := 6
const CLOSE := 0.001

var _device: ComputeDevice
var _passes: GpuVolumePasses


func before_test() -> void:
	_device = ComputeDevice.open()
	_passes = GpuVolumePasses.new(_device, Vector3i(WIDTH, HEIGHT, DEPTH))


func after_test() -> void:
	_device.release()


func _volume(field: FluidField) -> RID:
	return _device.keep(_device.rd.texture_create(_format(false), RDTextureView.new(), [VolumeCheck.scalar_of(field, DEPTH)]))


func _speed(u: FluidField, v: FluidField) -> RID:
	return _device.keep(_device.rd.texture_create(_format(true), RDTextureView.new(), [VolumeCheck.velocity_of(u, v, DEPTH)]))


func _format(vector: bool) -> RDTextureFormat:
	return _device.rd.texture_get_format(_device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), vector))


## La tranche du milieu d'un volume, canal `channel`.
func _middle(volume: RID, channels: int = 1, channel: int = 0) -> FluidField:
	return VolumeCheck.slice(_device, volume, WIDTH, HEIGHT, MIDDLE, channels, channel)


func test_un_volume_neuf_est_vide_meme_apres_un_autre() -> void:
	var format: RDTextureFormat = _format(false)
	var plein: FluidField = FluidField.new(WIDTH, HEIGHT)
	plein.fill(7.0)
	for _i: int in 4:
		var ancien: RID = _device.rd.texture_create(format, RDTextureView.new(), [VolumeCheck.scalar_of(plein, DEPTH)])
		_device.finish()
		_device.rd.free_rid(ancien)
	_device.finish()
	var neuf: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), false)
	for valeur: float in VolumeCheck.cells_of(_device, neuf):
		assert_float(valeur).is_equal(0.0)


func test_les_groupes_couvrent_les_trois_axes() -> void:
	assert_bool(ComputePass.volume_groups(Vector3i(8, 9, 1)) == Vector3i(2, 3, 1)).is_true()


func test_une_boule_est_plus_forte_au_centre_et_s_arrete_a_son_rayon() -> void:
	var champ: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), false)
	_passes.add_sphere(champ, Vector3(10.0, 10.0, MIDDLE), 4.0, 2.0)
	var tranche: FluidField = _middle(champ)
	assert_float(tranche.at(10, 10)).is_equal(2.0)
	assert_float(tranche.at(12, 10)).is_equal(1.0)
	assert_float(tranche.at(15, 10)).is_equal(0.0)
	assert_float(_tranche_loin(champ).peak()).is_equal(0.0)


func _tranche_loin(volume: RID) -> FluidField:
	return VolumeCheck.slice(_device, volume, WIDTH, HEIGHT, 0, 1, 0)


func test_la_divergence_suit_le_processeur_sur_chaque_tranche() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 4.0)
	var v: FluidField = GridCheck.waves(WIDTH, HEIGHT, -2.0)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	FluidProjection.divergence(attendu, u, v, ObstacleMask.new(WIDTH, HEIGHT))
	var sortie: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), false)
	_passes.divergence(sortie, _speed(u, v))
	assert_float(GridCheck.largest_gap(_middle(sortie), attendu)).is_less(CLOSE)


## Le même champ sans sa moyenne. Entre quatre murs, une pression n'est définie qu'à une constante près : seule sa pente compte.
func _centered(field: FluidField) -> FluidField:
	var centered: FluidField = FluidField.new(field.width, field.height)
	var mean: float = field.total() / field.data.size()
	for i: int in field.data.size():
		centered.data[i] = field.data[i] - mean
	return centered


func test_la_pression_arrive_ou_arrive_le_processeur() -> void:
	var divergence: FluidField = _centered(GridCheck.waves(WIDTH, HEIGHT, 1.0))
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	FluidProjection.solve_pressure(attendu, divergence, ObstacleMask.new(WIDTH, HEIGHT), 400, 1.7)
	var pression: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), false)
	_passes.solve_pressure(pression, _volume(divergence), 400, 1.7)
	assert_float(GridCheck.largest_gap(_centered(_middle(pression)), _centered(attendu))).is_less(0.01)


func test_la_pente_suit_le_processeur_loin_du_bord() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 4.0)
	var v: FluidField = GridCheck.waves(WIDTH, HEIGHT, -2.0)
	var pression: FluidField = GridCheck.waves(WIDTH, HEIGHT, 3.0)
	var vitesse: RID = _speed(u, v)
	_passes.subtract_gradient(vitesse, _volume(pression))
	var murs: ObstacleMask = ObstacleMask.new(WIDTH, HEIGHT)
	FluidProjection.subtract_gradient(u, v, pression, murs)
	murs.stop_at_walls(u, v)
	assert_float(GridCheck.largest_gap(_middle(vitesse, 4, 0), u)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_middle(vitesse, 4, 1), v)).is_less(CLOSE)


func test_rien_ne_sort_du_volume() -> void:
	var u: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 3.0)
	var vitesse: RID = _speed(u, u)
	_passes.subtract_gradient(vitesse, _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), false))
	assert_float(_middle(vitesse, 4, 0).at(WIDTH - 1, 5)).is_equal(0.0)
	assert_float(_middle(vitesse, 4, 0).at(WIDTH - 2, 5)).is_equal(3.0)
	assert_float(_middle(vitesse, 4, 1).at(5, HEIGHT - 1)).is_equal(0.0)


func test_le_transport_suit_le_processeur_par_le_filtre() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 1.0)
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 6.0)
	var v: FluidField = GridCheck.filled(champ, -2.5)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Advection.semi_lagrangian(attendu, champ, u, v, 0.4)
	var sortie: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), false)
	_passes.advect(sortie, _volume(champ), _speed(u, v), 0.4)
	assert_float(GridCheck.largest_gap(_middle(sortie), attendu)).is_less(0.01)


func test_un_courant_uniforme_deplace_une_boule_d_autant() -> void:
	var taille: Vector3i = Vector3i(WIDTH, HEIGHT, DEPTH)
	var boule: RID = _device.new_volume(taille, false)
	_passes.add_sphere(boule, Vector3(8.0, 10.0, MIDDLE), 3.5, 1.0)
	var vitesse_x: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 20.0)
	var sortie: RID = _device.new_volume(taille, false)
	_passes.advect(sortie, boule, _speed(vitesse_x, FluidField.new(WIDTH, HEIGHT)), 0.3)
	var centre: Vector3 = VolumeCheck.center_of(VolumeCheck.cells_of(_device, sortie), taille)
	assert_float(centre.x).is_equal_approx(14.0, 0.1)
	assert_float(centre.y).is_equal_approx(10.0, 0.1)
	assert_float(centre.z).is_equal_approx(MIDDLE, 0.1)


func test_la_vitesse_se_transporte_elle_meme_comme_le_processeur() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 6.0)
	var v: FluidField = GridCheck.filled(u, -2.5)
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Advection.semi_lagrangian(attendu, u, u, v, 0.4)
	var sortie: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), true)
	_passes.advect_velocity(sortie, _speed(u, v), 0.4)
	assert_float(GridCheck.largest_gap(_middle(sortie, 4, 0), attendu)).is_less(0.01)


func test_la_chaleur_pousse_vers_le_haut_et_la_fumee_vers_le_bas() -> void:
	var chaud: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 2.0)
	var vide: FluidField = FluidField.new(WIDTH, HEIGHT)
	var vitesse: RID = _speed(vide, vide)
	_passes.lift(vitesse, _volume(chaud), _volume(GridCheck.filled(vide, 3.0)), 10.0, 4.0, 0.1)
	assert_float(_middle(vitesse, 4, 1).at(5, 5)).is_equal_approx(0.8, CLOSE)
	assert_float(_middle(vitesse, 4, 0).at(5, 5)).is_equal(0.0)


func test_scale_multiplie_toutes_les_cases() -> void:
	var champ: RID = _volume(GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 3.0))
	_passes.scale(champ, 0.5)
	assert_float(_middle(champ).at(3, 3)).is_equal(1.5)


func test_la_rotation_suit_le_processeur_sur_chaque_tranche() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 4.0)
	var v: FluidField = FluidField.new(WIDTH, HEIGHT)
	for y: int in HEIGHT:
		for x: int in WIDTH:
			v.put(x, y, 3.0 * sin(0.31 * x) * cos(0.59 * y))
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	Vorticity.curl(attendu, u, v)
	var sortie: RID = _device.new_volume(Vector3i(WIDTH, HEIGHT, DEPTH), true)
	_passes.curl(sortie, _speed(u, v))
	assert_float(GridCheck.largest_gap(_middle(sortie, 4, 2), attendu)).is_less(CLOSE)


func test_le_confinement_suit_le_processeur_sur_chaque_tranche() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 4.0)
	var v: FluidField = GridCheck.filled(u, 1.0)
	var rotation_champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 2.0)
	var spin: RID = _speed(FluidField.new(WIDTH, HEIGHT), FluidField.new(WIDTH, HEIGHT))
	var valeurs: PackedFloat32Array = _device.rd.texture_get_data(spin, 0).to_float32_array()
	for z: int in DEPTH:
		for i: int in rotation_champ.data.size():
			valeurs[(z * rotation_champ.data.size() + i) * 4 + 2] = rotation_champ.data[i]
	_device.rd.texture_update(spin, 0, valeurs.to_byte_array())
	var vitesse: RID = _speed(u, v)
	_passes.confine(vitesse, spin, 4.0, 0.1)
	Vorticity.confine(u, v, rotation_champ, 4.0, 0.1)
	assert_float(GridCheck.largest_gap(_middle(vitesse, 4, 0), u)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_middle(vitesse, 4, 1), v)).is_less(CLOSE)
