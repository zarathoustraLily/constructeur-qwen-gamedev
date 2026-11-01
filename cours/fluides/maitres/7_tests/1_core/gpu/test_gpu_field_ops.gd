extends GdUnitTestSuite
## Règles des petites passes : elles rendent ce que rend le processeur ; un disque ne touche rien hors de son rayon ; les murs
## vident un champ à leur place seulement ; une vitesse qui entre dans un mur s'arrête, celle qui s'en éloigne reste.

const WIDTH := 30
const HEIGHT := 22
const CLOSE := 0.0001

var _device: ComputeDevice
var _ops: GpuFieldOps
var _walls: ObstacleMask
var _mask: RID


func before_test() -> void:
	_device = ComputeDevice.open()
	_ops = GpuFieldOps.new(_device, WIDTH, HEIGHT)
	_walls = ObstacleMask.new(WIDTH, HEIGHT)
	_walls.add_box(12, 6, 15, 13)
	_mask = _device.new_mask(_walls)


func after_test() -> void:
	_device.release()


func _lu(texture: RID) -> FluidField:
	return GridCheck.read(_device, texture, WIDTH, HEIGHT)


func test_scale_multiplie_toutes_les_cases() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 2.0)
	var texture: RID = GridCheck.texture_of(_device, champ)
	_ops.scale(texture, 0.5)
	for i: int in champ.data.size():
		champ.data[i] *= 0.5
	assert_float(GridCheck.largest_gap(_lu(texture), champ)).is_less(CLOSE)


func test_un_disque_rend_ce_que_rend_le_processeur() -> void:
	var attendu: FluidField = FluidField.new(WIDTH, HEIGHT)
	attendu.add_disc(13.3, 9.6, 6.5, 2.0)
	var texture: RID = _device.new_texture(WIDTH, HEIGHT)
	_ops.add_disc(texture, 13.3, 9.6, 6.5, 2.0)
	assert_float(GridCheck.largest_gap(_lu(texture), attendu)).is_less(CLOSE)


func test_un_disque_s_ajoute_a_ce_qui_est_la() -> void:
	var champ: FluidField = GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 1.0)
	var texture: RID = GridCheck.texture_of(_device, champ)
	_ops.add_disc(texture, 10.0, 10.0, 4.0, 2.0)
	var rendu: FluidField = _lu(texture)
	assert_float(rendu.at(10, 10)).is_equal(3.0)
	assert_float(rendu.at(20, 10)).is_equal(1.0)


func test_un_mur_vide_le_champ_a_sa_place_seulement() -> void:
	var champ: FluidField = GridCheck.waves(WIDTH, HEIGHT, 2.0)
	var texture: RID = GridCheck.texture_of(_device, champ)
	_ops.clear_walls(texture, _mask)
	_walls.clear_inside(champ)
	assert_float(GridCheck.largest_gap(_lu(texture), champ)).is_less(CLOSE)


func test_les_murs_arretent_ce_que_le_processeur_arrete() -> void:
	var u: FluidField = GridCheck.waves(WIDTH, HEIGHT, 3.0)
	var v: FluidField = GridCheck.waves(WIDTH, HEIGHT, -2.0)
	var u_carte: RID = GridCheck.texture_of(_device, u)
	var v_carte: RID = GridCheck.texture_of(_device, v)
	_ops.stop_at_walls(u_carte, v_carte, _mask)
	_walls.stop_at_walls(u, v)
	assert_float(GridCheck.largest_gap(_lu(u_carte), u)).is_less(CLOSE)
	assert_float(GridCheck.largest_gap(_lu(v_carte), v)).is_less(CLOSE)


func test_le_bord_de_la_grille_arrete_comme_un_mur() -> void:
	var u_carte: RID = GridCheck.texture_of(_device, GridCheck.filled(FluidField.new(WIDTH, HEIGHT), 3.0))
	var v_carte: RID = _device.new_texture(WIDTH, HEIGHT)
	_ops.stop_at_walls(u_carte, v_carte, _mask)
	var rendu: FluidField = _lu(u_carte)
	assert_float(rendu.at(WIDTH - 1, 3)).is_equal(0.0)
	assert_float(rendu.at(WIDTH - 2, 3)).is_equal(3.0)
