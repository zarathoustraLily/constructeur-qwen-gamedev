extends GdUnitTestSuite
## Règles de l'appareil : il s'ouvre, un tampon rend ce qu'on y a mis, et `release` rend tout à la carte.
#@ 12+
## Une texture rend le champ qu'on y a mis, et garde sa taille.
#@ all

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	if _device.rd != null:
		_device.release()


func test_une_carte_s_ouvre() -> void:
	assert_object(_device).is_not_null()
	assert_object(_device.rd).is_not_null()


func test_un_tampon_rend_ce_qu_on_y_a_mis() -> void:
	var tampon: RID = _device.new_buffer(PackedFloat32Array([1.0, 2.5, -3.0]))
	assert_array(Array(_device.read_buffer(tampon))).is_equal([1.0, 2.5, -3.0])


func test_keep_rend_ce_qu_on_lui_donne() -> void:
	var tampon: RID = _device.rd.storage_buffer_create(4)
	assert_bool(_device.keep(tampon) == tampon).is_true()


#@ 12+
func test_une_texture_rend_le_champ_qu_on_y_a_mis() -> void:
	var champ: FluidField = FluidField.new(3, 2)
	champ.put(0, 0, 1.5)
	champ.put(2, 1, -4.0)
	var texture: RID = _device.new_texture(3, 2)
	_device.upload(texture, champ)
	var relu: FluidField = FluidField.new(3, 2)
	_device.download(texture, relu)
	assert_float(relu.at(0, 0)).is_equal(1.5)
	assert_float(relu.at(2, 1)).is_equal(-4.0)
	assert_float(relu.at(1, 0)).is_equal(0.0)


func test_une_texture_garde_la_taille_demandee() -> void:
	var format: RDTextureFormat = _device.rd.texture_get_format(_device.new_texture(5, 7))
	assert_int(format.width).is_equal(5)
	assert_int(format.height).is_equal(7)


#@ all
func test_release_ferme_l_appareil() -> void:
	_device.new_buffer(PackedFloat32Array([1.0]))
	_device.release()
	assert_object(_device.rd).is_null()
