extends GdUnitTestSuite
## Règles d'une passe : le shader compile et tourne sur toutes les valeurs, même quand le dernier groupe n'est pas plein ; les
## groupes couvrent tout, sans groupe en trop.

const SCALE := "res://1_core/gpu/shaders/scale_values.glsl"

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


## Multiplie `values` par `factor` sur la carte, et rend le résultat.
func _scaled(values: PackedFloat32Array, factor: float) -> PackedFloat32Array:
	var passe: ComputePass = ComputePass.new(_device, SCALE)
	var tampon: RID = _device.new_buffer(values)
	var groupes: Vector3i = Vector3i(ComputePass.groups_for(values.size(), 64), 1, 1)
	passe.run([tampon], PackedFloat32Array([factor]), groupes)
	_device.finish()
	return _device.read_buffer(tampon)


func test_le_shader_compile() -> void:
	assert_bool(ComputePass.new(_device, SCALE).is_ready()).is_true()


func test_il_multiplie_chaque_valeur() -> void:
	assert_array(Array(_scaled(PackedFloat32Array([1.0, 2.0, 3.0, 4.0]), 2.0))).is_equal([2.0, 4.0, 6.0, 8.0])


func test_il_va_jusqu_au_bout_d_un_groupe_incomplet() -> void:
	var valeurs: PackedFloat32Array = PackedFloat32Array()
	valeurs.resize(70)
	valeurs.fill(3.0)
	var rendu: PackedFloat32Array = _scaled(valeurs, 2.0)
	assert_float(rendu[0]).is_equal(6.0)
	assert_float(rendu[63]).is_equal(6.0)
	assert_float(rendu[64]).is_equal(6.0)
	assert_float(rendu[69]).is_equal(6.0)


func test_les_groupes_couvrent_tout_sans_groupe_en_trop() -> void:
	assert_int(ComputePass.groups_for(64, 64)).is_equal(1)
	assert_int(ComputePass.groups_for(65, 64)).is_equal(2)
	assert_int(ComputePass.groups_for(1, 8)).is_equal(1)
#@ 12+


func test_les_groupes_d_une_grille_couvrent_ses_deux_cotes() -> void:
	assert_bool(ComputePass.grid_groups(16, 16) == Vector3i(2, 2, 1)).is_true()
	assert_bool(ComputePass.grid_groups(17, 8) == Vector3i(3, 1, 1)).is_true()
#@ all
